#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SETUP_ENV_FILE="${PROJECT_ROOT}/setup.env"
if [[ -f "${SETUP_ENV_FILE}" ]]; then
	# shellcheck disable=SC1090
	source "${SETUP_ENV_FILE}"
fi

set -a
source "${PROJECT_ROOT}/setup.env"
set +a

SWA_LOGIN_URL="${SWA_CONTROL_PLANE_LOGIN_URL%/}"
if [[ "${SWA_LOGIN_URL}" != */conjur/authenticate ]]; then
	SWA_LOGIN_URL="${SWA_LOGIN_URL}/conjur/authenticate"
fi
SWA_LOGIN_URL_B64="$(printf '%s' "${SWA_LOGIN_URL}" | base64 | tr -d '\n')"

cd "$PROJECT_ROOT/terraform/environments/swa-provider"

U=$(terraform output authn_id)
DU=$(printf "$U" | sed -e 's/"//g')
SWA_AUTHN_ID="$DU"

cd "$PROJECT_ROOT/swa-release/helm"

OPTS=""
# OPTS="--dry-run=client --debug"

# Deploy SWA Server
helm upgrade --install $OPTS swa-server ./swa-server \
	--namespace "${SWA_NAMESPACE}" \
	--create-namespace \
	--set image.repository=${SWA_IMAGE_REGISTRY}/swa-server \
	--set image.tag=${SWA_SERVER_IMAGE_TAG} \
	--set trustDomain.name=${SWA_TRUST_DOMAIN} \
	--set controlPlane.url=${SWA_CONJUR_APPLIANCE_URL} \
	--set controlPlane.auth.authnID=${SWA_AUTHN_ID} \
	--set rbac.createTokenReviewRole=true
