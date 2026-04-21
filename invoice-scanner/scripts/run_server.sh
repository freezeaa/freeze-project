#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

HOST="${APP_HOST:-127.0.0.1}"
PORT="${APP_PORT:-5000}"
WORKERS="${GUNICORN_WORKERS:-2}"
THREADS="${GUNICORN_THREADS:-4}"
TIMEOUT="${GUNICORN_TIMEOUT:-120}"
LOG_PATH="${LOG_PATH:-$PROJECT_DIR/scanner.log}"
EXPORT_DIR="${EXPORT_DIR:-$PROJECT_DIR/static/exports}"

mkdir -p "$(dirname "$LOG_PATH")"
mkdir -p "$EXPORT_DIR"

exec "$PROJECT_DIR/venv/bin/gunicorn" \
  --workers "$WORKERS" \
  --threads "$THREADS" \
  --bind "$HOST:$PORT" \
  --timeout "$TIMEOUT" \
  --access-logfile - \
  --error-logfile - \
  app:app
