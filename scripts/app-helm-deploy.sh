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

echo "=== Deploying demo-app to kind cluster ==="
echo "= Namespace: $APP_NAMESPACE"

# Fetch Terraform outputs for container names and managed identity client ID
cd "${PROJECT_ROOT}/terraform/environments/azure"
export STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
export WRITE_CONTAINER_NAME=$(terraform output -raw write_container)
export AZURE_CLIENT_ID=$(terraform output -raw managed_identity_client_id)
cd - >/dev/null

cd "${PROJECT_ROOT}/app"
helm upgrade --install demo-app ./helm/demo-app \
	--create-namespace \
	--namespace "$APP_NAMESPACE" \
	--set image.name=$APP_NAME \
	--set image.tag=$APP_TAG \
	--set namespace="$APP_NAMESPACE" \
	--set serviceAccount.name="$APP_SERVICE_ACCT" \
	--set config.storageAccountName="$STORAGE_ACCOUNT_NAME" \
	--set config.writeContainerName="$WRITE_CONTAINER_NAME" \
	--set config.swaAgentSocketPath="$SWA_AGENT_SOCKET_PATH" \
	--set config.azureTenantId="$AZURE_TENANT_ID" \
	--set config.azureClientId="$AZURE_CLIENT_ID" \
	--set config.rogueAppAddress="http://rogue-app.${APP_NAMESPACE}.svc.cluster.local:8081"

echo "✓ demo-app deployed to $APP_NAMESPACE namespace"
echo "Use port forward then open browser to http://localhost:8080/"
echo "Ex. kubectl port-forward -n demo-app svc/demo-app 8080:8080"
