#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SETUP_ENV_FILE="${WORKSHOP_ROOT}/setup.env"

if [[ -f "${SETUP_ENV_FILE}" ]]; then
	# shellcheck disable=SC1090
	source "${SETUP_ENV_FILE}"
fi

# IMAGE="us-central1-docker.pkg.dev/swa-workshop-k8s/davidh-machine-id/swa-agent:latest"
IMAGE="${SWA_IMAGE_REGISTRY}/${SWA_AGENT_IMAGE}:${SWA_AGENT_IMAGE_TAG}"
NAMESPACE="demo-app"

OPTS="-it"
OPTS="$OPTS --rm"
OPTS="$OPTS --quiet"
kubectl run svid-fetcher \
	--image="$IMAGE" \
	--restart=Never \
	$OPTS \
	--namespace=${NAMESPACE} \
	--labels=app.kubernetes.io/name=svid-fetcher \
	--overrides="$(
		cat <<JSON
{
  "spec": {
    "serviceAccountName": "$APP_SERVICE_ACCT",
    "containers": [{
      "name": "svid-fetcher",
      "image": "$IMAGE",
      "args": ["api", "fetch", "jwt", "--audience=conjur", "--socketPath=${SWA_AGENT_SOCKET_PATH}", "--output=json"],
      "volumeMounts": [{
        "name": "agent-socket",
        "mountPath": "/tmp/swa-agent"
      }]
    }],
    "volumes": [{
      "name": "agent-socket",
      "hostPath": {
        "path": "/tmp/swa-agent",
        "type": "Directory"
      }
    }]
  }
}
JSON
	)" 2>/dev/null
