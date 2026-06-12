#!/bin/bash
set -aeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SETUP_ENV_FILE="${PROJECT_ROOT}/setup.env"
if ! [[ -f "${SETUP_ENV_FILE}" ]]; then
	echo "ERROR: setup.env file does not exist, stopping."
	echo "       expected ${SETUP_ENV_FILE} to exist."
	exit 1
fi

# shellcheck disable=SC1090
source "${SETUP_ENV_FILE}"

cd "${PROJECT_ROOT}/terraform/environments/azure"

echo ""
echo "=== TERRAFORM: Initializing Azure Environment ==="
echo ""
terraform init
echo ""
echo "✓ Terraform initialized!"
echo ""
