# Contributing

Thanks for helping improve this project. This document covers the project's contribution process and commit/PR format expectations.

## PR (Merge Request) template
We use a PR template in `.github/PULL_REQUEST_TEMPLATE.md`. Please fill it in when opening PRs.

## Commit message format
We follow the Conventional Commits style:

```
<type>(<scope>): <short summary>

<optional body>

<optional footer>
```

Common types:
- feat: a new feature
- fix: a bug fix
- docs: documentation only changes
- style: formatting, missing semicolons, no production code change
- refactor: code change that neither fixes a bug nor adds a feature
- perf: a code change that improves performance
- test: adding or updating tests
- chore: changes to the build process or auxiliary tools

Keep the subject line <= 50 characters, use the body to explain *why* the change is needed and any non-obvious implementation notes.

Example:

```
feat(terraform): add optional VPC creation for EC2 module

When users don't provide `vpc_id` the module now creates a minimal VPC,
subnet and internet gateway so the EC2 instance can be launched.

Closes: #123
```

## Branch naming
- Use short, descriptive branch names, e.g. `feature/terraform-ec2-vpc`, `bugfix/jenkinsfile-check`, `chore/docs`

## PR Checklist
- Run tests locally if available
- Ensure no secrets or credentials are committed
- Update `README.md` or other documentation for user-facing changes

## Optional: commit-msg hook (local)
To help enforce commit messages, this repo includes a basic commit-msg hook in `.githooks/commit-msg`. To enable hooks locally run:

```bash
git config core.hooksPath .githooks
```

This hook will reject commits that do not comply with the Conventional Commits regex. It's optional but recommended.
