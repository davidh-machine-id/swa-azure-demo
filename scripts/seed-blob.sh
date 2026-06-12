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
echo "=== Seeding Blob Storage ==="

# Fetch Terraform outputs for container names
cd "${PROJECT_ROOT}/terraform/environments/azure"
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
WRITE_CONTAINER=$(terraform output -raw write_container)
cd - >/dev/null

echo "Storage Account: $STORAGE_ACCOUNT"
echo "Write Container: $WRITE_CONTAINER"

# Create temporary hello.txt
TEMP_FILE=$(mktemp)
echo "Hello from SWA SVID!" >"$TEMP_FILE"

# Upload to blob storage
az storage blob upload \
	--account-name      "$STORAGE_ACCOUNT" \
	--container-name      "$WRITE_CONTAINER" \
	--name      "hello.txt" \
	--file      "$TEMP_FILE" \
	--overwrite

# Clean up
rm "$TEMP_FILE"

echo "✓ Successfully seeded hello.txt to $WRITE_CONTAINER"
