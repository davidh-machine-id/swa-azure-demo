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

TOK=$(bash ${PROJECT_ROOT}/scripts/get-conjur-token.sh)
curl -sS -X GET "$CONJUR_APPLIANCE_URL/swa/trust-domains/${SWA_TRUST_DOMAIN}" \
	-H "Authorization: Token token=\"$TOK\"" \
	-H "Accept: application/x.secretsmgr.v2+json" \
	-H "Content-Type: application/json" |
	jq .
