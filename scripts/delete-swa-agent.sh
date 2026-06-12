#!/usr/bin/env bash
set -euo pipefail
set -a

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/setup.env"

cd "$PROJECT_ROOT/swa-release/helm"

# Deploy SWA Agent
helm uninstall swa-agent -n "${SWA_NAMESPACE}"
