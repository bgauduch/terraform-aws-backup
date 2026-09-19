package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSimple(t *testing.T) {
	t.Parallel()

	opts := terraformOptions(t, "simple", nil)
	defer destroy(t, opts)
	terraform.InitAndApply(t, opts)

	assert.True(t, hasPrefix(terraform.Output(t, opts, "vault_arn"), "arn:aws:backup:"+region+":"))
	assert.Equal(t, "backup-ex-simple", terraform.Output(t, opts, "vault_name"))
	assert.True(t, hasPrefix(terraform.Output(t, opts, "iam_role_arn"), "arn:aws:iam::"))
	assert.Contains(t, terraform.OutputMapOfObjects(t, opts, "plans"), "daily")
	assert.Contains(t, terraform.OutputMap(t, opts, "selections"), "daily/tagged")
}
