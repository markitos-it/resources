#!/bin/bash
# Uninstall goenv on macOS and clean zsh environment variables.
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

if [[ -d "$GOENV_ROOT" ]]; then
	echo "Removing goenv from: $GOENV_ROOT"
	rm -rf "$GOENV_ROOT"
else
	echo "goenv directory not found, skipping: $GOENV_ROOT"
fi

if [[ -f "$ZSHENV_FILE" ]]; then
	tmp_file="${ZSHENV_FILE}.tmp"
	awk '
		$0 != "export GOENV_ROOT=\"$HOME/.goenv\"" &&
		$0 != "export PATH=\"$GOENV_ROOT/bin:$PATH\"" &&
		$0 != "eval \"$(goenv init -)\""
	' "$ZSHENV_FILE" > "$tmp_file"
	mv "$tmp_file" "$ZSHENV_FILE"
	if ! grep -q 'GOENV_ROOT|goenv init -' "$ZSHENV_FILE" 2>/dev/null; then
		echo "Removed goenv entries from $ZSHENV_FILE"
	else
		echo "Cleaned known goenv lines in $ZSHENV_FILE"
	fi
else
	echo "$ZSHENV_FILE not found, skipping."
fi

echo "Done. Restart your terminal or run: source $ZSHENV_FILE"