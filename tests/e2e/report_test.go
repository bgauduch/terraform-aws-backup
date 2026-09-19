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

func TestReport(t *testing.T) {
	t.Parallel()

	opts := terraformOptions(t, "report", nil)
	defer destroy(t, opts)
	terraform.InitAndApply(t, opts)

	bucket := terraform.Output(t, opts, "s3_bucket_name")
	plans := terraform.OutputMapOfObjects(t, opts, "report_plans")
	require.Len(t, plans, 3)

	client := backup.NewFromConfig(awsConfig(t, region))
	for template, plan := range plans {
		name := plan.(map[string]interface{})["id"].(string)
		out, err := client.DescribeReportPlan(context.Background(), &backup.DescribeReportPlanInput{ReportPlanName: aws.String(name)})
		require.NoError(t, err, template)
		assert.Equal(t, bucket, aws.ToString(out.ReportPlan.ReportDeliveryChannel.S3BucketName))
		assert.Equal(t, "backup", aws.ToString(out.ReportPlan.ReportDeliveryChannel.S3KeyPrefix))
		assert.ElementsMatch(t, []string{"CSV", "JSON"}, out.ReportPlan.ReportDeliveryChannel.Formats)
		assert.Equal(t, template, aws.ToString(out.ReportPlan.ReportSetting.ReportTemplate))
	}
}
