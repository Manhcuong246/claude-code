#!/bin/sh
set -e
exec uvicorn server:app \
  --host "${HOST:-0.0.0.0}" \
  --port "${PORT:-8082}" \
  --timeout-graceful-shutdown 5
