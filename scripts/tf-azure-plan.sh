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

# Azure region for resources
TF_VAR_location="$AZURE_REGION"

# Resource group name for all Azure resources
TF_VAR_resource_group_name="${AZURE_RESOURCE_GROUP}"

# Environment name (for tagging)
# TF_VAR_environment="${PROJECT_PREFIX}-demo"
TF_VAR_prefix="${PROJECT_PREFIX}"

OIDC_VALS=$(bash ${PROJECT_ROOT}/scripts/oidc-values.sh)
TF_VAR_swa_oidc_issuer_url="$(echo $OIDC_VALS | jq -r '.jwt.discovery_endpoints.oidc_discovery_url' | sed 's|/.well-known/openid-configuration||')"
TF_VAR_spiffe_subject="$SPIFFE_SUBJECT"

cd "${PROJECT_ROOT}/terraform/environments/azure"

echo ""
echo "=== TERRAFORM: Planning Azure Resources ==="
echo ""
terraform plan
echo ""
echo "✓ Plan complete"
echo ""
