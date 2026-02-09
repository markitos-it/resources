#!/bin/bash
# Install goenv on macOS and set up zsh environment variables.
#:[.'.]:>- ==================================================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
#:[.'.]:>- ==================================================================================

set -euo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
	echo "This script requires bash. Run: bash $0"
	exit 1
fi

GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
ZSHENV_FILE="$HOME/.zshenv"
RECENT_COUNT=5

echo "Installing goenv into: $GOENV_ROOT"

if [[ ! -d "$GOENV_ROOT" ]]; then
	git clone https://github.com/go-nv/goenv.git "$GOENV_ROOT"
else
	echo "goenv already exists, skipping clone."
fi

touch "$ZSHENV_FILE"

if ! grep -q 'export GOENV_ROOT=' "$ZSHENV_FILE"; then
	echo 'export GOENV_ROOT="$HOME/.goenv"' >> "$ZSHENV_FILE"
fi

if ! grep -q 'export PATH="$GOENV_ROOT/bin:$PATH"' "$ZSHENV_FILE"; then
	echo 'export PATH="$GOENV_ROOT/bin:$PATH"' >> "$ZSHENV_FILE"
fi

if ! grep -q 'eval "$(goenv init -)"' "$ZSHENV_FILE"; then
	echo 'eval "$(goenv init -)"' >> "$ZSHENV_FILE"
fi

# Load goenv for this script session
export GOENV_ROOT="$GOENV_ROOT"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"

stable_versions="$(goenv install -l | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$')"
if [[ -z "$stable_versions" ]]; then
	echo "No stable Go versions found in goenv list."
	exit 1
fi

latest_version="$(printf "%s\n" "$stable_versions" | sort -V | tail -1)"
latest_major="$(printf "%s" "$latest_version" | awk -F. '{print $1}')"
latest_minor_num="$(printf "%s" "$latest_version" | awk -F. '{print $2}')"

lts_minor=""
if [[ "$latest_minor_num" -gt 0 ]]; then
	lts_minor="$latest_major.$((latest_minor_num - 1))"
fi

lts_version=""
if [[ -n "$lts_minor" ]]; then
	lts_version="$(printf "%s\n" "$stable_versions" | grep -E "^${lts_minor}\." | sort -V | tail -1)"
fi

recent_versions="$(printf "%s\n" "$stable_versions" | sort -V | tail -n "$RECENT_COUNT")"

declare -a display_options=()
declare -a version_options=()

add_option() {
	local label="$1"
	local version="$2"
	local v

	if [[ -z "$version" ]]; then
		return
	fi

	if [[ ${version_options[@]+set} ]]; then
		for v in "${version_options[@]}"; do
			if [[ "$v" == "$version" ]]; then
				return
			fi
		done
	fi

	display_options+=("$label - $version")
	version_options+=("$version")
}

add_option "Latest" "$latest_version"
add_option "LTS (previous minor)" "$lts_version"

while IFS= read -r v; do
	add_option "Recent" "$v"
done <<< "$recent_versions"

options_count=0
if [[ ${version_options[@]+set} ]]; then
	options_count=${#version_options[@]}
fi

if [[ "$options_count" -eq 0 ]]; then
	echo "No installable versions found."
	exit 1
fi

echo "Choose a Go version to install:"
idx=1
for opt in "${display_options[@]}"; do
	echo "  [$idx] $opt"
	idx=$((idx + 1))
done

read -r -p "Enter number: " choice
if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "$options_count" ]]; then
	echo "Invalid selection."
	exit 1
fi

TARGET_VERSION="${version_options[$((choice - 1))]}"

echo "Installing Go $TARGET_VERSION"
goenv install -s "$TARGET_VERSION"
goenv global "$TARGET_VERSION"

echo "Done. Restart your terminal or run: source $ZSHENV_FILE"

