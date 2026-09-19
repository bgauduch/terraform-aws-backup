package test

import (
	"context"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/backup"
	"github.com/aws/aws-sdk-go-v2/service/backup/types"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCompleteBackupRestoreDynamoDB deploys the complete example, backs up the DynamoDB table on demand,
// restores the recovery point into a new table and compares the data. Every resource is deleted, recovery points included.
func TestCompleteBackupRestoreDynamoDB(t *testing.T) {
	t.Parallel()

	opts := terraformOptions(t, "complete", nil)
	defer destroy(t, opts)
	terraform.InitAndApply(t, opts)

	vaultName := terraform.Output(t, opts, "vault_name")
	roleArn := terraform.Output(t, opts, "iam_role_arn")
	tableName := terraform.Output(t, opts, "dynamodb_table_name")
	tableArn := terraform.Output(t, opts, "dynamodb_table_arn")
	restoredTable := tableName + "-restored"

	assert.Equal(t, vaultName, terraform.Output(t, opts, "vault_lock_configuration_id"))
	assert.True(t, hasPrefix(terraform.Output(t, opts, "air_gapped_vault_arn"), "arn:aws:backup:"+region+":"))
	assert.Len(t, terraform.OutputMap(t, opts, "selections"), 2)

	cfg := awsConfig(t, region)
	backupClient := backup.NewFromConfig(cfg)
	dynamoClient := dynamodb.NewFromConfig(cfg)
	defer deleteRecoveryPoints(t, backupClient, vaultName)
	defer deleteTable(t, dynamoClient, restoredTable)

	items := putItems(t, dynamoClient, tableName, 10)

	// The role is created seconds before the job starts: IAM propagation can reject the first attempts
	var jobID string
	waitFor(t, "backup job start", 5*time.Minute, func() (bool, error) {
		out, err := backupClient.StartBackupJob(context.Background(), &backup.StartBackupJobInput{
			BackupVaultName: aws.String(vaultName),
			ResourceArn:     aws.String(tableArn),
			IamRoleArn:      aws.String(roleArn),
			// The vault lock bounds the retention: an on-demand job without lifecycle never expires and is rejected
			Lifecycle: &types.Lifecycle{DeleteAfterDays: aws.Int64(1)},
		})
		if err != nil {
			t.Logf("start backup job: %v", err)
			return false, nil
		}
		jobID = aws.ToString(out.BackupJobId)
		return true, nil
	})
	recoveryPointArn := waitBackupJob(t, backupClient, jobID, 30*time.Minute)
	require.NotEmpty(t, recoveryPointArn)

	restoreJobID := startRestoreJob(t, backupClient, recoveryPointArn, roleArn, map[string]string{
		"targetTableName": restoredTable,
		"encryptionType":  "Default",
	})
	waitRestoreJob(t, backupClient, restoreJobID, 45*time.Minute)
	waitTableActive(t, dynamoClient, restoredTable, 10*time.Minute)

	assert.Equal(t, items, scanItems(t, dynamoClient, restoredTable))
}
