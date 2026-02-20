Muscat-PyPi - A repository to generate the PyPi packages for Muscat (https://gitlab.com/drti/muscat)
===========================================================================================================

This Muscat Super Build will build minimal required dependencies not available in Pypi.

What the workflow does
====================

- `build-linux`, `build-macos`, `build-windows` build wheels using `cibuildwheel` on each OS and upload per-job artifacts.
- `publish` downloads artifacts and uploads them to PyPI using `twine` and the `PYPI_API_TOKEN` secret.

Launching a workflow
====================

This repository includes a GitHub Actions workflow to build binary wheels on Linux, macOS and Windows and publish them to PyPI when a tag is pushed to the Muscat repository.

Manually in GitHub:
-------------------

On the page https://github.com/muscat-packages/muscat-pypi/actions/workflows/publish-pypi-matrix.yml use the 'Run workflow' to select the Muscat tag/branch to use for the package generation.

By creating a tag in gitlab.com/drti/Muscat
-------------------------------------------

On the page https://gitlab.com/drti/muscat/-/tags use the 'New Tag' button to crate a new tag.


Curl expression:
----------------

The action can be launched using the following curl expression:

```
curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/muscat-packages/muscat-pypi/dispatches -d '{"event_type": "tag_push", "client_payload": {"ref": "refs/tags/__tagname__", "run-name":"from curl hook"}}' -v
```

The user must provide the gitlab token (environment variable `GITHUB_TOKEN`). the field `ref` can point to a tag or a branch of Muscat.


Setup
==================


On this Repository (GitHub):
----------------------------
Create a Github Personal Access Token.

Url for the current tokens : https://github.com/settings/personal-access-tokens

Create a secret named `PYPI_API_TOKEN` in the repository settings (Settings → Secrets → Actions) containing a PyPI API token with `action` and `Contents` permissions to `Read and write`.


On Muscat Repository ("https://gitlab.com/drti/muscat")
-------------------------------------------------------
Create a Gitlab Webhook to notified github of the event push tag

 - Name : Github PyPi package creation
 - URL : https://api.github.com/repos/muscat-packages/muscat-pypi/dispatches
 - Trigger : check "Tag push events"
 - Custom webhook template :
  ```{
  "event_type": "{{object_kind}}",
  "client_payload": {"run-name":"from gitlab hook", "ref":"{{ref}}"}
}
  ```
  - Custom Headers :
    - "Accept": "application/vnd.github+json"
    - "Authorization": "Bearer __GITHUB_TOKEN__"

Current active hooks
https://gitlab.com/drti/muscat/-/hooks

Notes
-----

- For CI troubleshooting, run the workflow via `Actions` → select the workflow → `Run workflow` or inspect logs on failed runs.
