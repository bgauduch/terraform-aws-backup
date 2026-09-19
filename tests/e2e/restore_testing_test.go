package test

import (
	"context"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/backup"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRestoreTesting(t *testing.T) {
	t.Parallel()

	opts := terraformOptions(t, "restore-testing", nil)
	defer destroy(t, opts)
	terraform.InitAndApply(t, opts)

	planName := terraform.Output(t, opts, "restore_testing_plan_name")
	vaultArn := terraform.Output(t, opts, "vault_arn")
	roleArn := terraform.Output(t, opts, "iam_role_arn")

	client := backup.NewFromConfig(awsConfig(t, region))
	plan, err := client.GetRestoreTestingPlan(context.Background(), &backup.GetRestoreTestingPlanInput{RestoreTestingPlanName: aws.String(planName)})
	require.NoError(t, err)
	assert.Equal(t, "cron(0 8 ? * MON *)", aws.ToString(plan.RestoreTestingPlan.ScheduleExpression))
	assert.Equal(t, []string{vaultArn}, plan.RestoreTestingPlan.RecoveryPointSelection.IncludeVaults)

	selections, err := client.ListRestoreTestingSelections(context.Background(), &backup.ListRestoreTestingSelectionsInput{RestoreTestingPlanName: aws.String(planName)})
	require.NoError(t, err)
	require.Len(t, selections.RestoreTestingSelections, 1)
	assert.Equal(t, "DynamoDB", aws.ToString(selections.RestoreTestingSelections[0].ProtectedResourceType))
	assert.Equal(t, roleArn, aws.ToString(selections.RestoreTestingSelections[0].IamRoleArn))
}
