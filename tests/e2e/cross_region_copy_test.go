package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/backup"
	"github.com/aws/aws-sdk-go-v2/service/backup/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCrossRegionCopy backs up the DynamoDB table, copies the recovery point to the secondary region and checks the copy.
func TestCrossRegionCopy(t *testing.T) {
	if !regionReachable(t, regionSecondary) {
		t.Skipf("region %s is not reachable from this account", regionSecondary)
	}

	opts := terraformOptions(t, "cross-region-copy", nil)
	defer destroy(t, opts)
	terraform.InitAndApply(t, opts)

	vaultName := terraform.Output(t, opts, "vault_name")
	secondaryVaultName := terraform.Output(t, opts, "secondary_vault_name")
	secondaryVaultArn := terraform.Output(t, opts, "secondary_vault_arn")
	roleArn := terraform.Output(t, opts, "iam_role_arn")
	tableArn := terraform.Output(t, opts, "dynamodb_table_arn")

	primary := backup.NewFromConfig(awsConfig(t, region))
	secondary := backup.NewFromConfig(awsConfig(t, regionSecondary))
	defer deleteRecoveryPoints(t, primary, vaultName)
	defer deleteRecoveryPoints(t, secondary, secondaryVaultName)

	jobID := startBackupJob(t, primary, vaultName, tableArn, roleArn)
	recoveryPointArn := waitBackupJob(t, primary, jobID, 30*time.Minute)

	copyJob, err := primary.StartCopyJob(context.Background(), &backup.StartCopyJobInput{
		SourceBackupVaultName:     aws.String(vaultName),
		DestinationBackupVaultArn: aws.String(secondaryVaultArn),
		RecoveryPointArn:          aws.String(recoveryPointArn),
		IamRoleArn:                aws.String(roleArn),
		Lifecycle:                 &types.Lifecycle{DeleteAfterDays: aws.Int64(1)},
	})
	require.NoError(t, err)

	waitFor(t, "copy job", 45*time.Minute, func() (bool, error) {
		out, err := primary.DescribeCopyJob(context.Background(), &backup.DescribeCopyJobInput{CopyJobId: copyJob.CopyJobId})
		if err != nil {
			return false, err
		}
		switch out.CopyJob.State {
		case types.CopyJobStateCompleted:
			return true, nil
		case types.CopyJobStateFailed:
			return false, fmt.Errorf("copy job failed: %s", aws.ToString(out.CopyJob.StatusMessage))
		}
		return false, nil
	})

	copies, err := secondary.ListRecoveryPointsByBackupVault(context.Background(), &backup.ListRecoveryPointsByBackupVaultInput{BackupVaultName: aws.String(secondaryVaultName)})
	require.NoError(t, err)
	assert.Len(t, copies.RecoveryPoints, 1)
}
