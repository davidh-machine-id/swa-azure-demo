# kind-load-images.sh
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

# --- OS detection ---
detect_os() {
	case "$(uname -s)" in
	Darwin) echo "darwin" ;;
	Linux) echo "linux" ;;
	MINGW* | MSYS* | CYGWIN*) echo "Windows is not supported by this script. Use install-terraform-provider.ps1 instead." >&2 && exit 1 ;;
	*) echo "unsupported OS: $(uname -s)" >&2 && exit 1 ;;
	esac
}

# --- Arch detection ---
detect_arch() {
	case "$(uname -m)" in
	x86_64) echo "amd64" ;;
	aarch64 | arm64) echo "arm64" ;;
	*) echo "unsupported arch: $(uname -m)" >&2 && exit 1 ;;
	esac
}

GOOS=$(detect_os)
GOARCH=$(detect_arch)

IMAGE_BASE="$PROJECT_ROOT/swa-release/container-images"
IMAGE_AGENT="$(find $IMAGE_BASE -maxdepth 1 -type f -name 'swa-agent-*-'${GOARCH}'*.tar' | sort | head -1)"
IMAGE_SERVER="$(find $IMAGE_BASE -maxdepth 1 -type f -name 'swa-server-*-'${GOARCH}'*.tar' | sort | head -1)"

if [ -z "$IMAGE_AGENT" ]; then
	echo "ERROR: could not find swa-agent container image."
	exit 1
fi
if [ -z "$IMAGE_SERVER" ]; then
	echo "ERROR: could not find swa-server container image."
	exit 1
fi

kind load image-archive $IMAGE_AGENT --name $SWA_CLUSTER_NAME
kind load image-archive $IMAGE_SERVER --name $SWA_CLUSTER_NAME

# Extract container tags from filenames and update setup.env
# Filename patterns: swa-agent-<TAG>.tar and swa-server-<TAG>.tar

# Extract tag from agent image filename
# e.g., swa-agent-0.0.0-SNAPSHOT-arm64v8.tar -> 0.0.0-SNAPSHOT-arm64v8
AGENT_FILENAME=$(basename "$IMAGE_AGENT")
SWA_AGENT_IMAGE_TAG=$(echo "$AGENT_FILENAME" | sed -E 's/swa-agent-(.+)\.tar/\1/')

# Extract tag from server image filename
# e.g., swa-server-0.0.0-SNAPSHOT-arm64v8.tar -> 0.0.0-SNAPSHOT-arm64v8
SERVER_FILENAME=$(basename "$IMAGE_SERVER")
SWA_SERVER_IMAGE_TAG=$(echo "$SERVER_FILENAME" | sed -E 's/swa-server-(.+)\.tar/\1/')

echo "Extracted container tags:"
echo "  Agent tag:  $SWA_AGENT_IMAGE_TAG"
echo "  Server tag: $SWA_SERVER_IMAGE_TAG"

# Update setup.env with extracted tags
sed -i.bak "s|^SWA_SERVER_IMAGE_TAG=.*|SWA_SERVER_IMAGE_TAG=\"$SWA_SERVER_IMAGE_TAG\"|" "$SETUP_ENV_FILE"
sed -i.bak "s|^SWA_AGENT_IMAGE_TAG=.*|SWA_AGENT_IMAGE_TAG=\"$SWA_AGENT_IMAGE_TAG\"|" "$SETUP_ENV_FILE"

echo "Updated $SETUP_ENV_FILE with extracted container tags"
