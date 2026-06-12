#!/usr/bin/env bash
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
source "${PROJECT_ROOT}/setup.env"

echo "=== Deploying rogue-app to kind cluster ==="
echo "= Namespace: $ROGUE_APP_NAMESPACE"

# # Fetch Terraform outputs for container names and managed identity client ID
# cd "${PROJECT_ROOT}/terraform/environments/azure"
# export STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
# export WRITE_CONTAINER_NAME=$(terraform output -raw write_container)
# export AZURE_CLIENT_ID=$(terraform output -raw managed_identity_client_id)
# cd - >/dev/null

cd "${PROJECT_ROOT}/rogue-app"
helm upgrade --install rogue-app ./helm \
	--create-namespace \
	--namespace "$ROGUE_APP_NAMESPACE" \
	--set image.name=$ROGUE_APP_NAME \
	--set image.tag=$ROGUE_APP_TAG \
	--set namespace="$ROGUE_APP_NAMESPACE" \
	--set serviceAccount.name="$ROGUE_APP_SERVICE_ACCT"

echo "✓ rogue-app deployed to $ROGUE_APP_NAMESPACE namespace"
echo "Use port forward then open browser to http://localhost:8080/"
echo "Ex. kubectl port-forward -n demo-app svc/demo-app 8080:8080"
