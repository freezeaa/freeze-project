#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_BIN="$PROJECT_DIR/venv/bin/python"
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup_exports.py"

if [ -x "$PYTHON_BIN" ]; then
  exec "$PYTHON_BIN" "$CLEANUP_SCRIPT"
else
  exec python3 "$CLEANUP_SCRIPT"
fi
