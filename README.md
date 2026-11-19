# python-app-template

Template for a Python 3.14 application that ships as a container image and
a Helm chart. Create a repository from it with **Use this template**, then
rename things (see [Start a new app](#start-a-new-app)).

## What is inside

| Path                       | What it is                                                         |
| -------------------------- | ------------------------------------------------------------------ |
| `src/app/main.py`          | Entry point (`app` command). Only answers `GET /healthz` for now.  |
| `tests/`                   | pytest tests.                                                      |
| `pyproject.toml`, `uv.lock`| uv project. The only dependency is pytest, for the tests.          |
| `Makefile`                 | Local commands, and the targets the CI calls.                      |
| `dockerfiles/`             | Dockerfile and bake file of the image.                             |
| `chart/`                   | Helm chart: Deployment, Service, ServiceAccount, HPA, PDB, NetworkPolicy, Ingress. |
| `.github/workflows/`       | CI, release and publish, from [AzAvalon/workflows](https://github.com/AzAvalon/workflows). |

The image is built from the
[AzAvalon base images](https://github.com/AzAvalon/base-images): the
`python3.14-debian-dev` image installs the app in a virtualenv, and the
`python3.14-debian` image runs it as the `app` user (uid 1001). The CI
tests run in the same dev image.

## Local development

You need [uv](https://docs.astral.sh/uv/) and, for the hooks,
[prek](https://github.com/j178/prek).

```sh
make install   # create .venv
make test      # run the tests
make run       # start the app on http://127.0.0.1:8000/healthz
make lint      # run the pre-commit hooks
make docker    # build the image for your machine
```

Add a dependency with `uv add <package>` (or `uv add --dev <package>` for
a test tool). Commit `uv.lock` with it.

## The Helm chart

Everything is set in `chart/values.yaml`; each value has a comment. The
defaults are safe for production:

- the pod runs as a non-root user with a read-only root filesystem, no
  Linux capabilities and the `RuntimeDefault` seccomp profile; `/tmp` is a
  small writable `emptyDir`;
- the memory request equals the memory limit;
- startup, liveness and readiness probes call `/healthz`;
- a PodDisruptionBudget lets one pod go at a time;
- a NetworkPolicy only lets traffic in on the app port. Set
  `networkPolicy.egress.enabled` to also limit outgoing traffic (DNS stays
  allowed).

The HorizontalPodAutoscaler (`autoscaling.enabled`) and the Ingress
(`ingress.enabled`) are off by default.

## CI and releases

- `ci.yml` runs on every pull request: pre-commit hooks and PR title
  check, tests, chart lint and `kubeconform`, image build, and a deploy of
  the chart in a kind cluster. Images and charts of a PR are pushed as
  `pr-<number>.<sha>` and `0.0.0-pr.<number>.<sha>`.
- `pr-cleanup.yml` deletes them when the PR closes.
- `release.yml` is run by hand. semantic-release reads the conventional
  commit messages, writes the version into `pyproject.toml`, `uv.lock` and
  `chart/Chart.yaml`, and creates the GitHub release: a release on `main`,
  a `-dev` prerelease on `develop`.
- `publish.yml` runs on each GitHub release and pushes the image
  `ghcr.io/azavalon/python-app-template:<version>` and the chart
  `oci://ghcr.io/azavalon/charts/python-app-template`.

Renovate keeps the base image, the Python packages, the actions and the
hooks up to date.

The workflows need the variable `CI_APP_CLIENT_ID` and the secret
`CI_APP_PRIVATE_KEY` (the CI GitHub App). Both are set at AzAvalon
organization level. Images are pushed with the job's `GITHUB_TOKEN`.

## Start a new app

Replace `python-app-template` with the new name in:

- `pyproject.toml` (`name`),
- `chart/Chart.yaml` (`name`) and `chart/values.yaml` (`image.repository`),
- `dockerfiles/docker-bake.hcl` (`DOCKER_IMAGE`),
- `.github/workflows/` (`service-name`, `packages`, `test-id`),
- this README and `SECURITY.md`.

The Python package can stay `app`. New GHCR packages start private: make
them public once in the package settings, or the kind deploy in the CI
can't pull the image.
