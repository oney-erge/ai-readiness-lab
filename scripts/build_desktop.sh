#!/usr/bin/env bash
# Build the native AI Readiness Lab desktop app locally.
#
#   ./scripts/build_desktop.sh
#
# Output: dist/"AI Readiness Lab"/ — a self-contained app (no Python needed to run).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Building frontend"
( cd frontend && npm ci && npm run build )

echo "==> Installing desktop build deps"
pip install -r backend/requirements.txt -r backend/requirements-desktop.txt

echo "==> Bundling with PyInstaller"
pyinstaller desktop/AIReadinessLab.spec --noconfirm --clean

echo "==> Done. App is in: dist/"
ls -la dist
