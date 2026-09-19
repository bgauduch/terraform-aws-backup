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

func TestPlan(t *testing.T) {
	t.Parallel()

	opts := terraformOptions(t, "plan", nil)
	defer destroy(t, opts)
	terraform.InitAndApply(t, opts)

	planID := terraform.Output(t, opts, "plan_id")
	vaultName := terraform.Output(t, opts, "vault_name")
	require.Len(t, terraform.OutputMap(t, opts, "selection_ids"), 2)

	client := backup.NewFromConfig(awsConfig(t, region))
	out, err := client.GetBackupPlan(context.Background(), &backup.GetBackupPlanInput{BackupPlanId: aws.String(planID)})
	require.NoError(t, err)
	assert.Len(t, out.BackupPlan.Rules, 2)
	for _, rule := range out.BackupPlan.Rules {
		assert.Equal(t, vaultName, aws.ToString(rule.TargetBackupVaultName))
	}
}
