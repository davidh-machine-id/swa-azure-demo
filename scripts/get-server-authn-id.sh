#!/usr/bin/env bash
set -euo pipefail
set -a

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

# GET https://<subdomain>.secretsmgr.cyberark.cloud/api/swa/trust-domains/{trust-domain-name}/server-groups/{server-group-name}/components/{server-name}

URL="$CONJUR_APPLIANCE_URL/swa/trust-domains/$SWA_TRUST_DOMAIN/server-groups/$SWA_SERVER_GROUP_NAME/components/$SWA_SERVER_NAME"
TOKEN=$(bash $SCRIPT_DIR/get-conjur-token.sh)
#export TOKEN="<access-token>"
TENANT_SUBDOMAIN="$CONJUR_TENANT"
TRUST_DOMAIN_NAME="$SWA_TRUST_DOMAIN"

curl -sS -XGET "$URL" \
	-H "Authorization: Token token=\"${TOKEN}\"" \
	-H "Accept: application/x.secretsmgr.v2+json" \
	-H "Content-Type: application/json" |
	jq .
