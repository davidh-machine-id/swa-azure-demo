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

require_cmd() {
	local cmd="$1"
	local msg="$2"
	if ! command -v "${cmd}" >/dev/null 2>&1; then
		echo "ERROR: Required CLI '${cmd}' not found in PATH."
		if [ -n "$msg" ]; then
			printf "$msg"
		fi
		exit 1
	fi
}

# Check setup.env
echo "====="
echo "Checking setup.env..."
if [ ! -f "$SETUP_ENV_FILE" ]; then
	echo "ERROR: setup.env file not found"
	echo "  Create from template: cp setup.env.example setup.env"
	echo "  Edit setup.env"
	exit 1
fi
echo "✅ setup.env file found"

# shellcheck disable=SC1090
source "${PROJECT_ROOT}/setup.env"

echo "====="
echo "Checking required vars are set in setup.env..."

EMPTY_VARS=0
if [ -z "$CONJUR_TENANT" ]; then
	echo "CONJUR_TENANT is not set"
	EMPTY_VARS=1
fi
if [ -z "$AZURE_TENANT_ID" ]; then
	echo "AZURE_TENANT_ID is not set"
	EMPTY_VARS=1
fi
if [ -z "$AZURE_REGION" ]; then
	echo "AZURE_REGION is not set"
	EMPTY_VARS=1
fi
if [ "$EMPTY_VARS" -gt 0 ]; then
	echo "Missing vars in setup.env ...stopping."
	exit 1
fi

echo "====="
echo "Checking Go is installed..."
require_cmd go "Install Go: https://go.dev/doc/install"
echo "✅ Go is installed"

echo "====="
echo "Checking Terraform is installed..."
require_cmd terraform "Install Terraform: https://developer.hashicorp.com/terraform/install"
echo "✅ Terraform is installed"

echo "====="
echo "Checking Docker is installed..."
require_cmd docker "Install Docker: https://www.docker.com/get-started/"
echo "✅ Docker is installed"

echo "====="
echo "Checking Kind is installed..."
require_cmd kind "Install Kind: https://kind.sigs.k8s.io/docs/user/quick-start#installation"
echo "✅ Kind is installed"

echo "====="
echo "Checking Kubectl is installed..."
require_cmd kubectl "Install Kubectl: https://kubernetes.io/docs/tasks/tools/"
echo "✅ Kubectl is installed"

echo "====="
echo "Checking Helm is installed..."
require_cmd helm "Install Helm: https://helm.sh/docs/intro/install/"
echo "✅ Helm is installed"

echo "====="
echo "Checking Task is installed..."
require_cmd task "Install Task: https://taskfile.dev/docs/installation"
echo "✅ Task is installed"

echo "====="
echo "Checking jq is installed..."
require_cmd jq "Install jq: https://jqlang.org/download/"
echo "✅ jq is installed"

echo "====="
echo "Checking Azure CLI is installed..."
require_cmd az "Install Azure CLI: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest"
echo "✅ Azure CLI is installed"

echo "====="
echo "Checking Secrets Manager CLI..."
require_cmd conjur "Install Secrets Manager CLI:\n\tSaaS        - https://docs.cyberark.com/secrets-manager-saas/latest/en/content/conjurcloud/cli/cli-setup-new.htm\n\tSelf-hosted - https://docs.cyberark.com/secrets-manager-sh/latest/en/content/developer/cli/cli-setup.htm\n"
echo "✅ Secrets manager CLI (conjur) is installed, version: \"$(conjur --version | head -1)\""

echo
