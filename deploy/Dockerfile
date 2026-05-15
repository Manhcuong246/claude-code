# Personal / self-hosted image (not maintained as an official distribution).
# Build from repo root: docker compose -f deploy/docker-compose.yml build
FROM ghcr.io/astral-sh/uv:python3.14-bookworm-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY . .
RUN uv sync --frozen --no-dev

ENV PATH="/app/.venv/bin:$PATH" \
    LOG_FILE=/data/logs/server.log

RUN mkdir -p /data/logs && chmod +x /app/deploy/entrypoint.sh

VOLUME ["/data"]

EXPOSE 8082

ENTRYPOINT ["/app/deploy/entrypoint.sh"]
