Publishing to PyPI
==================

This repository includes a GitHub Actions workflow to build binary wheels on Linux, macOS and Windows and publish them to PyPI when a tag `v*` is pushed.

Setup
-----

- Create a secret named `PYPI_API_TOKEN` in the repository settings (Settings → Secrets → Actions) containing a PyPI API token with `upload` permissions.
- Create a tag and push it, e.g.:

  git tag v1.2.3
  git push origin v1.2.3

What the workflow does
----------------------

- `build-linux`, `build-macos`, `build-windows` build wheels using `cibuildwheel` on each OS and upload per-job artifacts.
- `publish` downloads artifacts and uploads them to PyPI using `twine` and the `PYPI_API_TOKEN` secret.

Notes
-----

- Ensure `pyproject.toml` is correctly configured for building (it already exists in the repo).
- For CI troubleshooting, run the workflow via `Actions` → select the workflow → `Run workflow` or inspect logs on failed runs.
