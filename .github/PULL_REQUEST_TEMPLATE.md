<!-- Title: keep it short and use Conventional Commits-style -->
<!-- Example: feat(ci): add terraform infra and PR template -->

## Summary

Describe the change in 1-2 sentences. Explain *why* the change is needed (not just what it does).

## Changed Files
- List the important files changed (high level).

## Verification / How to test
- Steps to reproduce the change locally or how reviewers can validate.

## Checklist
- [ ] I ran the tests locally (if applicable)
- [ ] I updated documentation where relevant (README/CONTRIBUTING)
- [ ] No secrets or sensitive data are committed
- [ ] I added any required Terraform changes to `terraform/*` and validated `terraform plan`

## Release notes
- (optional) Short user-facing description for the changelog/release notes.

## Related
- Fixes/Relates to: <!-- issue/pr links -->

---
Please follow the commit message style described in `CONTRIBUTING.md` (Conventional Commits). Use `type(scope): subject` with a short 50 character limit for the subject line.
