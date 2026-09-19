# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change.

Please note we have a code of conduct, please follow it in all your interactions with the project.

## Pull Request Process

1. Update the README.md with details of changes including example hcl blocks and [example files](../examples) if appropriate.
2. Run pre-commit hooks `pre-commit run -a`.
3. Run the unit tests `terraform test -filter=tests/unit_root.tftest.hcl` (no AWS credentials needed).
4. Once all outstanding comments and checklist items have been addressed, your contribution will be merged! Merged PRs will be included in the next release. The maintainers take care of updating the CHANGELOG as they merge.

## Checklists for contributions

- [ ] Add [semantics prefix](#semantic-pull-requests) to your PR or Commits (at least one of your commit groups)
- [ ] CI tests are passing
- [ ] README.md has been updated after any changes to variables and outputs. See https://github.com/bgauduch/terraform-aws-backup/#doc-generation
- [ ] Run pre-commit hooks `pre-commit run -a`

## Semantic Pull Requests

To generate the changelog, pull requests or commits must follow the conventional commit prefixes below:

| Prefix | Purpose |
|--------|---------|
| `feat:` | new features |
| `fix:` | bug fixes |
| `improvement:` | enhancements |
| `docs:` | documentation and examples |
| `refactor:` | code refactoring |
| `test:` | tests |
| `ci:` | CI purpose |
| `chore:` | chores, skipped in the changelog, for example `chore: update changelog` |
