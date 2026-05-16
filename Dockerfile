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

RUN mkdir -p /data/logs && chmod +x /app/docker-entrypoint.sh

VOLUME ["/data"]

EXPOSE 8082

ENTRYPOINT ["/app/docker-entrypoint.sh"]
