#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
swa_release_dir="$project_root/swa-release"
helm_dir="$swa_release_dir/helm"
tf_provider_dir="$swa_release_dir/terraform-provider"
terraform_dir="$project_root/terraform"

# ============================================================
# Tasks to complete:
# - locate helm dir (should be under ./swa-release/helm)
# - untar helm agent and server files
# - install terraform provider using ./swa-release/install-terraform-provider.sh
# - extract tf provider version
# - compare tf provider version in tf code that uses the swa provider to ensure the tf code is using the right version
# ============================================================

# --- OS detection ---
detect_os() {
	case "$(uname -s)" in
	Darwin) echo "darwin" ;;
	Linux) echo "linux" ;;
	MINGW* | MSYS* | CYGWIN*)
		echo "Windows is not supported by this script. Use install-terraform-provider.ps1 instead." >&2
		exit                                                                                                          1
		;;
	*)
		echo "unsupported OS: $(uname -s)" >&2
		exit                              1
		;;
	esac
}

# --- Arch detection ---
detect_arch() {
	case "$(uname -m)" in
	x86_64) echo "amd64" ;;
	aarch64 | arm64) echo "arm64" ;;
	*)
		echo "unsupported arch: $(uname -m)" >&2
		exit                                1
		;;
	esac
}
GOOS="$(detect_os)"
GOARCH="$(detect_arch)"

# ============================================================
# Task 1: Validate Prerequisites
# ============================================================
if [ ! -d "$swa_release_dir" ]; then
	echo "✗ swa-release/ directory not found at $swa_release_dir"
	exit 1
fi

# ============================================================
# Task 2: Extract Helm Charts
# ============================================================

# Extract swa-agent helm chart
agent_tgz=$(find "$helm_dir" -maxdepth 1 -name "swa-agent*.tgz" -type f | head -1)
if [ -z "$agent_tgz" ]; then
	echo "✗ swa-agent*.tgz not found in $helm_dir"
	exit 1
fi

rm -rf "$helm_dir/swa-agent"
mkdir -p "$helm_dir/swa-agent"
tar -xzf "$agent_tgz" -C "$helm_dir/swa-agent" --strip-components=1
echo "Extracted: $(basename "$agent_tgz")"

# Extract swa-server helm chart
server_tgz=$(find "$helm_dir" -maxdepth 1 -name "swa-server*.tgz" -type f | head -1)
if [ -z "$server_tgz" ]; then
	echo "✗ swa-server*.tgz not found in $helm_dir"
	exit 1
fi

rm -rf "$helm_dir/swa-server"
mkdir -p "$helm_dir/swa-server"
tar -xzf "$server_tgz" -C "$helm_dir/swa-server" --strip-components=1
echo "Extracted: $(basename "$server_tgz")"
