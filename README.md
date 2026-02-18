Muscat-PyPi - A repository to generate the PyPi packages for Muscat (https://gitlab.com/drti/muscat)
===========================================================================================================

Muscat-PyPi for Muscat to generate wheels on Github

This Muscat Super Build will build all the dependencies to available in Pypi.

Publishing to PyPI
==================

This repository includes a GitHub Actions workflow to build binary wheels on Linux, macOS and Windows and publish them to PyPI when a tag is pushed to the Muscat repository.

Setup
-----

On this Repository (GitHub):

Create a Github Personal Access Token with the permissions : actions:write
Url for the creation : https://github.com/settings/personal-access-tokens/new

- Create a secret named `PYPI_API_TOKEN` in the repository settings (Settings → Secrets → Actions) containing a PyPI API token with `action` permissions.


On Muscat Repository ("https://gitlab.com/drti/muscat")

Create a Gitlab Webhook to notified github of the event push tag

https://gitlab.com/drti/muscat/-/hooks

current active hook
https://gitlab.com/drti/muscat/-/hooks/71549345/edit

What the workflow does
----------------------

- `build-linux`, `build-macos`, `build-windows` build wheels using `cibuildwheel` on each OS and upload per-job artifacts.
- `publish` downloads artifacts and uploads them to PyPI using `twine` and the `PYPI_API_TOKEN` secret.

Notes
-----

- For CI troubleshooting, run the workflow via `Actions` → select the workflow → `Run workflow` or inspect logs on failed runs.
