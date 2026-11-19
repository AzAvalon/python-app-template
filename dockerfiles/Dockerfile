# syntax=docker/dockerfile:1.29

# Build stage: the dev base image has uv and runs as the app user (uid 1001).
FROM ghcr.io/azavalon/base:0.2.0-python3.14-debian-dev@sha256:ae11e56488aa32f0e17702c0e46cd77e08011a55e8ec4b8c3f96a81ccb5e3332 AS builder

WORKDIR /opt/app
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/app/.venv

# Dependencies first: this layer is reused until uv.lock changes
RUN --mount=type=cache,target=/home/app/.cache/uv,uid=1001,gid=1001 \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --locked --no-dev --no-install-project --no-editable

COPY --chown=app:app pyproject.toml uv.lock README.md ./
COPY --chown=app:app src ./src
RUN --mount=type=cache,target=/home/app/.cache/uv,uid=1001,gid=1001 \
    uv sync --locked --no-dev --no-editable


# Runtime stage: Python, CA certificates and the app user, nothing else.
FROM ghcr.io/azavalon/base:0.2.0-python3.14-debian@sha256:a9e8e1eb7b05ed6a6b07f93b811a629dfd9ad80c54719d54f144265cf0dd17c0 AS production

WORKDIR /opt/app
# Owned by root: the app user can read the virtualenv, not change it
COPY --link --from=builder /opt/app/.venv /opt/app/.venv
ENV PATH=/opt/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_PORT=8000

EXPOSE 8000
CMD ["app"]
