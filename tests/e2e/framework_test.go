package test

import (
	"context"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/backup"
	"github.com/aws/aws-sdk-go-v2/service/configservice"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestFramework deploys the framework example and waits for the AWS Config rules to be deployed.
// An AWS Config recorder is created by the example only when the region has none.
func TestFramework(t *testing.T) {
	t.Parallel()

	cfg := awsConfig(t, region)
	recorders, err := configservice.NewFromConfig(cfg).DescribeConfigurationRecorders(context.Background(), &configservice.DescribeConfigurationRecordersInput{})
	require.NoError(t, err)
	createRecorder := len(recorders.ConfigurationRecorders) == 0
	t.Logf("existing config recorders: %d, example creates one: %t", len(recorders.ConfigurationRecorders), createRecorder)

	opts := terraformOptions(t, "framework", map[string]interface{}{"enable_config_recorder": createRecorder})
	defer destroy(t, opts)
	terraform.InitAndApply(t, opts)

	frameworkName := terraform.Output(t, opts, "framework_id")
	client := backup.NewFromConfig(cfg)
	waitFor(t, "framework deployment", 20*time.Minute, func() (bool, error) {
		out, err := client.DescribeFramework(context.Background(), &backup.DescribeFrameworkInput{FrameworkName: aws.String(frameworkName)})
		if err != nil {
			return false, err
		}
		t.Logf("framework %s deployment status: %s", frameworkName, aws.ToString(out.DeploymentStatus))
		return aws.ToString(out.DeploymentStatus) == "COMPLETED", nil
	})

	out, err := client.DescribeFramework(context.Background(), &backup.DescribeFrameworkInput{FrameworkName: aws.String(frameworkName)})
	require.NoError(t, err)
	assert.Len(t, out.FrameworkControls, 5)
	assert.Equal(t, "backup_ex_framework", frameworkName)
}
