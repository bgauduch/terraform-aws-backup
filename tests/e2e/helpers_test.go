package test

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/backup"
	"github.com/aws/aws-sdk-go-v2/service/backup/types"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	dynamodbtypes "github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

const (
	region          = "eu-west-1"
	regionSecondary = "eu-west-3"
	pollInterval    = 30 * time.Second
)

func awsConfig(t *testing.T, region string) aws.Config {
	t.Helper()
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(region))
	require.NoError(t, err)
	return cfg
}

// regionReachable reports whether AWS Backup can be called in the region, false when a service control policy denies it.
func regionReachable(t *testing.T, region string) bool {
	t.Helper()
	_, err := backup.NewFromConfig(awsConfig(t, region)).ListBackupVaults(context.Background(), &backup.ListBackupVaultsInput{MaxResults: aws.Int32(1)})
	return err == nil
}

// destroy runs terraform destroy up to three times: a destroy interrupted by a transient error leaves resources behind.
func destroy(t *testing.T, opts *terraform.Options) {
	t.Helper()
	var err error
	for attempt := 1; attempt <= 3; attempt++ {
		if _, err = terraform.DestroyE(t, opts); err == nil {
			return
		}
		t.Logf("destroy attempt %d failed: %v", attempt, err)
		time.Sleep(pollInterval)
	}
	t.Errorf("destroy failed after 3 attempts: %v", err)
}

func terraformOptions(t *testing.T, example string, vars map[string]interface{}) *terraform.Options {
	t.Helper()
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../examples/" + example,
		Vars:         vars,
		NoColor:      true,
	})
}

// waitFor polls fn until it returns done, fails on error, and fails the test on timeout.
func waitFor(t *testing.T, what string, timeout time.Duration, fn func() (done bool, err error)) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for {
		done, err := fn()
		require.NoError(t, err, what)
		if done {
			return
		}
		require.True(t, time.Now().Before(deadline), "timeout waiting for %s", what)
		t.Logf("waiting for %s", what)
		time.Sleep(pollInterval)
	}
}

func startBackupJob(t *testing.T, client *backup.Client, vaultName, resourceArn, roleArn string) string {
	t.Helper()
	out, err := client.StartBackupJob(context.Background(), &backup.StartBackupJobInput{
		BackupVaultName: aws.String(vaultName),
		ResourceArn:     aws.String(resourceArn),
		IamRoleArn:      aws.String(roleArn),
		Lifecycle:       &types.Lifecycle{DeleteAfterDays: aws.Int64(1)},
	})
	require.NoError(t, err)
	return aws.ToString(out.BackupJobId)
}

// waitBackupJob returns the recovery point ARN of a completed backup job.
func waitBackupJob(t *testing.T, client *backup.Client, jobID string, timeout time.Duration) string {
	t.Helper()
	var recoveryPointArn string
	waitFor(t, "backup job "+jobID, timeout, func() (bool, error) {
		out, err := client.DescribeBackupJob(context.Background(), &backup.DescribeBackupJobInput{BackupJobId: aws.String(jobID)})
		if err != nil {
			return false, err
		}
		switch out.State {
		case types.BackupJobStateCompleted:
			recoveryPointArn = aws.ToString(out.RecoveryPointArn)
			return true, nil
		case types.BackupJobStateFailed, types.BackupJobStateAborted, types.BackupJobStateExpired:
			return false, fmt.Errorf("backup job %s ended in state %s: %s", jobID, out.State, aws.ToString(out.StatusMessage))
		}
		return false, nil
	})
	return recoveryPointArn
}

func startRestoreJob(t *testing.T, client *backup.Client, recoveryPointArn, roleArn string, metadata map[string]string) string {
	t.Helper()
	out, err := client.StartRestoreJob(context.Background(), &backup.StartRestoreJobInput{
		RecoveryPointArn: aws.String(recoveryPointArn),
		IamRoleArn:       aws.String(roleArn),
		Metadata:         metadata,
	})
	require.NoError(t, err)
	return aws.ToString(out.RestoreJobId)
}

func waitRestoreJob(t *testing.T, client *backup.Client, jobID string, timeout time.Duration) {
	t.Helper()
	waitFor(t, "restore job "+jobID, timeout, func() (bool, error) {
		out, err := client.DescribeRestoreJob(context.Background(), &backup.DescribeRestoreJobInput{RestoreJobId: aws.String(jobID)})
		if err != nil {
			return false, err
		}
		switch out.Status {
		case types.RestoreJobStatusCompleted:
			return true, nil
		case types.RestoreJobStatusFailed, types.RestoreJobStatusAborted:
			return false, fmt.Errorf("restore job %s ended in status %s: %s", jobID, out.Status, aws.ToString(out.StatusMessage))
		}
		return false, nil
	})
}

// deleteRecoveryPoints removes every recovery point of the vault and waits until the vault is empty, so that it can be destroyed.
// A governance mode vault lock forbids manual deletion: the lock is removed first.
func deleteRecoveryPoints(t *testing.T, client *backup.Client, vaultName string) {
	t.Helper()
	ctx := context.Background()
	if _, err := client.DeleteBackupVaultLockConfiguration(ctx, &backup.DeleteBackupVaultLockConfigurationInput{BackupVaultName: aws.String(vaultName)}); err != nil {
		var notFound *types.ResourceNotFoundException
		if !errors.As(err, &notFound) {
			t.Logf("removing vault lock of %s: %v", vaultName, err)
		}
	}
	paginator := backup.NewListRecoveryPointsByBackupVaultPaginator(client, &backup.ListRecoveryPointsByBackupVaultInput{BackupVaultName: aws.String(vaultName)})
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			var notFound *types.ResourceNotFoundException
			if errors.As(err, &notFound) {
				return
			}
			t.Logf("listing recovery points of %s: %v", vaultName, err)
			return
		}
		for _, rp := range page.RecoveryPoints {
			_, err := client.DeleteRecoveryPoint(ctx, &backup.DeleteRecoveryPointInput{
				BackupVaultName:  aws.String(vaultName),
				RecoveryPointArn: rp.RecoveryPointArn,
			})
			if err != nil {
				t.Logf("deleting recovery point %s: %v", aws.ToString(rp.RecoveryPointArn), err)
			}
		}
	}
	waitFor(t, "recovery points deletion in "+vaultName, 20*time.Minute, func() (bool, error) {
		out, err := client.ListRecoveryPointsByBackupVault(ctx, &backup.ListRecoveryPointsByBackupVaultInput{BackupVaultName: aws.String(vaultName)})
		if err != nil {
			var notFound *types.ResourceNotFoundException
			if errors.As(err, &notFound) {
				return true, nil
			}
			return false, err
		}
		return len(out.RecoveryPoints) == 0, nil
	})
}

func putItems(t *testing.T, client *dynamodb.Client, table string, count int) map[string]string {
	t.Helper()
	items := make(map[string]string, count)
	for i := 0; i < count; i++ {
		id := fmt.Sprintf("item-%02d", i)
		payload := fmt.Sprintf("payload-%02d", i)
		items[id] = payload
		_, err := client.PutItem(context.Background(), &dynamodb.PutItemInput{
			TableName: aws.String(table),
			Item: map[string]dynamodbtypes.AttributeValue{
				"id":      &dynamodbtypes.AttributeValueMemberS{Value: id},
				"payload": &dynamodbtypes.AttributeValueMemberS{Value: payload},
			},
		})
		require.NoError(t, err)
	}
	return items
}

func scanItems(t *testing.T, client *dynamodb.Client, table string) map[string]string {
	t.Helper()
	items := map[string]string{}
	paginator := dynamodb.NewScanPaginator(client, &dynamodb.ScanInput{TableName: aws.String(table), ConsistentRead: aws.Bool(true)})
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(context.Background())
		require.NoError(t, err)
		for _, item := range page.Items {
			id := item["id"].(*dynamodbtypes.AttributeValueMemberS).Value
			payload := item["payload"].(*dynamodbtypes.AttributeValueMemberS).Value
			items[id] = payload
		}
	}
	return items
}

func deleteTable(t *testing.T, client *dynamodb.Client, table string) {
	t.Helper()
	_, err := client.DeleteTable(context.Background(), &dynamodb.DeleteTableInput{TableName: aws.String(table)})
	if err != nil {
		var notFound *dynamodbtypes.ResourceNotFoundException
		if errors.As(err, &notFound) {
			return
		}
		t.Logf("deleting table %s: %v", table, err)
		return
	}
	waitFor(t, "table "+table+" deletion", 10*time.Minute, func() (bool, error) {
		_, err := client.DescribeTable(context.Background(), &dynamodb.DescribeTableInput{TableName: aws.String(table)})
		var notFound *dynamodbtypes.ResourceNotFoundException
		if errors.As(err, &notFound) {
			return true, nil
		}
		return false, err
	})
}

func waitTableActive(t *testing.T, client *dynamodb.Client, table string, timeout time.Duration) {
	t.Helper()
	waitFor(t, "table "+table+" active", timeout, func() (bool, error) {
		out, err := client.DescribeTable(context.Background(), &dynamodb.DescribeTableInput{TableName: aws.String(table)})
		if err != nil {
			return false, err
		}
		return out.Table.TableStatus == dynamodbtypes.TableStatusActive, nil
	})
}

func hasPrefix(s, prefix string) bool {
	return strings.HasPrefix(s, prefix)
}
