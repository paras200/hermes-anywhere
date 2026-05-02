# CI workflows (staged)

These GitHub Actions workflows live here instead of `.github/workflows/` so the repo can be published with a GitHub token that doesn't have the `workflow` scope.

**To activate them**, move both files:

```bash
mkdir -p .github/workflows
git mv ci/check-upstream.yml      .github/workflows/check-upstream.yml
git mv ci/terraform-validate.yml  .github/workflows/terraform-validate.yml
git commit -m "Activate CI workflows"
git push
```

The push needs a token with the `workflow` scope. With `gh`:

```bash
gh auth refresh -h github.com -s workflow
git push
```

## What each does

### `check-upstream.yml`

Runs daily at 14:00 UTC. Compares the version pinned in `docker-compose.yml` against the latest tag on Docker Hub. If a newer version exists and no open issue already tracks it, opens a new issue with the upstream release notes inline.

Anyone who forks this repo gets the upstream-watcher for free.

### `terraform-validate.yml`

Runs on PRs that touch `terraform/**`. For each of the five providers, runs `terraform fmt -check` and `terraform validate`. Catches broken HCL before merge.
