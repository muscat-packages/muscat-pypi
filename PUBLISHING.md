Publishing to PyPI
==================

This repository includes a GitHub Actions workflow to build binary wheels on Linux, macOS and Windows and publish them to PyPI when a tag `v*` is pushed.

Setup
-----

- Create a secret named `PYPI_API_TOKEN` in the repository settings (Settings → Secrets → Actions) containing a PyPI API token with `upload` permissions.

- Create a tag and push it, e.g.:

  git tag 1.2.3
  git push origin 1.2.3

Notes on GitLab mirrors
----------------------

- The workflow is configured to trigger on any tag push (no `v` prefix required). If you mirror the GitLab repository to GitHub, pushing tags on GitLab that are mirrored to GitHub will trigger the workflow automatically.

Triggering from a non-mirrored GitLab repository (recommended hook)
----------------------------------------------------------------

If the GitLab repository is not a mirror of this GitHub repo, add a small GitLab CI job or webhook that calls GitHub's `repository_dispatch` API to trigger the publish workflow when a tag is pushed.

Example GitLab CI job (add to the GitLab project's `.gitlab-ci.yml`):

```yaml
stages:
  - dispatch

dispatch_to_github:
  stage: dispatch
  only:
    - tags
  script:
    - |
      curl -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_PAT" \
        https://api.github.com/repos/<github-owner>/<github-repo>/dispatches \
        -d '{"event_type":"gitlab-tag","client_payload":{"tag":"'$CI_COMMIT_TAG'"}}'

# In GitLab CI variables, set `GITHUB_PAT` to a GitHub personal access token
# with `repo` and `workflow` scopes. Replace `<github-owner>/<github-repo>`
# with your GitHub repository path.
```

This will POST a `repository_dispatch` event named `gitlab-tag` to GitHub and include the pushed tag name in `client_payload.tag`. The GitHub workflow will extract that tag and run the publish job.

What the workflow does
----------------------

- `build-linux`, `build-macos`, `build-windows` build wheels using `cibuildwheel` on each OS and upload per-job artifacts.
- `publish` downloads artifacts and uploads them to PyPI using `twine` and the `PYPI_API_TOKEN` secret.

Notes
-----

- Ensure `pyproject.toml` is correctly configured for building (it already exists in the repo).
- For CI troubleshooting, run the workflow via `Actions` → select the workflow → `Run workflow` or inspect logs on failed runs.
