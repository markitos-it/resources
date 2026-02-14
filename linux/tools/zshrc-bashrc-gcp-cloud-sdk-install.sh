#!/usr/bin/env bash
set -euo pipefail

# Simple gcloud CLI installer for Linux (bash) and macOS (zsh)
# Usage:
#   bash cloud-sdk
#
# Optional env vars:
#   GCLOUD_INSTALL_DIR  (default: $HOME/google-cloud-sdk)
#   GCLOUD_VERSION      (default: latest)
#   GCLOUD_ARCH         (default: autodetect; examples: linux-x86_64, linux-arm, darwin-x86_64, darwin-arm)

need_cmd() {
	command -v "$1" >/dev/null 2>&1
}

if ! need_cmd curl; then
	echo "Error: curl is required." >&2
	exit 1
fi

if ! need_cmd tar; then
	echo "Error: tar is required." >&2
	exit 1
fi

if ! need_cmd python3 && ! need_cmd python; then
	echo "Error: python3 (or python) is required." >&2
	exit 1
fi

INSTALL_DIR="${GCLOUD_INSTALL_DIR:-$HOME/google-cloud-sdk}"

detect_arch() {
	local os arch
	os="$(uname -s)"
	arch="$(uname -m)"
	case "$os" in
		Linux)
			case "$arch" in
				x86_64|amd64)
					echo "linux-x86_64"
					;;
				aarch64|arm64)
					echo "linux-arm"
					;;
				*)
					echo ""
					;;
			esac
			;;
		Darwin)
			case "$arch" in
				x86_64|amd64)
					echo "darwin-x86_64"
					;;
				arm64)
					echo "darwin-arm"
					;;
				*)
					echo ""
					;;
				esac
			;;
		*)
			echo ""
			;;
	esac
}

ARCH="${GCLOUD_ARCH:-$(detect_arch)}"
if [[ -z "$ARCH" ]]; then
	echo "Error: unsupported architecture. Set GCLOUD_ARCH manually." >&2
	exit 1
fi

get_latest_version() {
	local json_url version
	json_url="https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json"
	if need_cmd python3; then
		version="$(
			curl -fsSL "$json_url" | \
				python3 -c 'import json,sys;print(json.load(sys.stdin).get("version",""))'
		)"
	else
		version="$(
			curl -fsSL "$json_url" | \
				python -c 'import json,sys;print(json.load(sys.stdin).get("version",""))'
		)"
	fi
	if [[ -z "$version" ]]; then
		echo "Error: could not determine latest version." >&2
		exit 1
	fi
	echo "$version"
}

VERSION="${GCLOUD_VERSION:-$(get_latest_version)}"
TARBALL="google-cloud-cli-${VERSION}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${TARBALL}"

tmp_dir="$(mktemp -d)"
cleanup() {
	rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "Downloading ${TARBALL}..."
curl -fsSL "$DOWNLOAD_URL" -o "$tmp_dir/$TARBALL"

mkdir -p "$(dirname "$INSTALL_DIR")"
echo "Extracting to $(dirname "$INSTALL_DIR")..."
tar -xzf "$tmp_dir/$TARBALL" -C "$(dirname "$INSTALL_DIR")"

if [[ ! -x "$INSTALL_DIR/bin/gcloud" ]]; then
	echo "Error: gcloud binary not found after extraction." >&2
	exit 1
fi

echo "Installing components..."
"$INSTALL_DIR/install.sh" --quiet

append_if_missing() {
	local line file
	line="$1"
	file="$2"
	if [[ -f "$file" ]]; then
		if ! grep -qF "$line" "$file"; then
			echo "$line" >> "$file"
		fi
	else
		echo "$line" >> "$file"
	fi
}

os_name="$(uname -s)"
if [[ "$os_name" == "Darwin" ]]; then
	profile_file="$HOME/.zshrc"
	append_if_missing "source '$INSTALL_DIR/path.zsh.inc'" "$profile_file"
	append_if_missing "source '$INSTALL_DIR/completion.zsh.inc'" "$profile_file"
else
	profile_file="$HOME/.bashrc"
	append_if_missing "source '$INSTALL_DIR/path.bash.inc'" "$profile_file"
	append_if_missing "source '$INSTALL_DIR/completion.bash.inc'" "$profile_file"
fi

echo "Done. Open a new terminal or run:"
echo "  source '$profile_file'"
echo "Then verify with:"
echo "  gcloud --version"
