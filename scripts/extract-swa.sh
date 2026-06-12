#!/bin/bash
set -e

# ============================================================
# Extract SWA Release Tarball
# ============================================================
# Finds the latest swa-release-v*.tgz in dist/ (by semver)
# and extracts it directly to swa-release/ (no subdirectory wrapper)
# ============================================================

echo ""
echo "⚠️  WARNING: The swa-release/ directory contains contents"
echo "    from the tarball. Do not manually edit these files."
echo ""

# Check if dist directory exists
if [ ! -d "dist" ]; then
	echo "✗ dist/ directory not found"
	exit 1
fi

# Find the latest version swa-release*-v*.tgz file (sorted by semver)
TARBALL=$(find dist -maxdepth 1 -name "swa-release*-v*.tgz" -type f | sort -V | tail -1)

if [ -z "$TARBALL" ]; then
	echo "✗ No swa-release*-v*.tgz file found in dist/"
	exit 1
fi

echo "Found: $(basename "$TARBALL")"

# Remove existing swa-release directory
if [ -d "swa-release" ]; then
	rm -rf swa-release
fi

# Create fresh swa-release directory
mkdir -p swa-release

# Extract tarball, stripping top-level directory
if ! tar -xzf "$TARBALL" -C swa-release --strip-components=1; then
	echo "✗ Failed to extract tarball"
	exit 1
fi

echo "Extracted to: swa-release/"
