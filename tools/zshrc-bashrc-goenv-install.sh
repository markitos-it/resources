#!/usr/bin/env bash
set -euo pipefail

# goenv installer for macOS and Linux (bash/zsh)
#:[.'.]:>- ==================================================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
#:[.'.]:>- ==================================================================================

# Configuration
GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
RECENT_COUNT=5

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_error() {
	echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
	echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
	echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
	echo -e "${YELLOW}⚠️  $1${NC}"
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1
}

# Check required commands
if ! need_cmd git; then
	print_error "git is required."
	exit 1
fi

# Detect OS and set profile file
os_name="$(uname -s)"
if [[ "$os_name" == "Darwin" ]]; then
	profile_file="$HOME/.zshenv"
	shell_name="zsh"
elif [[ "$os_name" == "Linux" ]]; then
	# Linux puede usar bash o zsh, priorizamos zsh si existe
	if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
		profile_file="$HOME/.zshenv"
		shell_name="zsh"
	else
		profile_file="$HOME/.bashrc"
		shell_name="bash"
	fi
else
	print_error "Unsupported OS: $os_name"
	exit 1
fi

print_info "Detected OS: $os_name ($shell_name)"
print_info "Profile file: $profile_file"
print_info "Installing goenv into: $GOENV_ROOT"
echo ""

# Clone or update goenv
if [[ ! -d "$GOENV_ROOT" ]]; then
	print_info "Cloning goenv repository..."
	git clone https://github.com/go-nv/goenv.git "$GOENV_ROOT"
	print_success "goenv cloned successfully"
else
	print_warning "goenv already exists at $GOENV_ROOT"
	read -p "Do you want to update it? (y/N): " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		print_info "Updating goenv..."
		cd "$GOENV_ROOT" && git pull && cd - > /dev/null
		print_success "goenv updated"
	fi
fi

# Configure profile file
touch "$profile_file"

if grep -q 'export GOENV_ROOT=' "$profile_file"; then
	print_warning "goenv configuration already exists in $profile_file"
else
	print_info "Adding goenv configuration to $profile_file..."
	cat >> "$profile_file" <<'EOF'
# goenv configuration
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"
EOF
	print_success "Configuration added"
fi

# Load goenv for this script session
export GOENV_ROOT="$GOENV_ROOT"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"

print_info "Fetching available Go versions..."

# Get stable versions
stable_versions="$(goenv install -l | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)"

if [[ -z "$stable_versions" ]]; then
	print_error "No stable Go versions found in goenv list."
	exit 1
fi

# Calculate versions
latest_version="$(printf "%s\n" "$stable_versions" | tail -1)"
latest_major="$(printf "%s" "$latest_version" | awk -F. '{print $1}')"
latest_minor_num="$(printf "%s" "$latest_version" | awk -F. '{print $2}')"

# LTS calculation
lts_minor=""
if [[ "$latest_minor_num" -gt 0 ]]; then
	lts_minor="$latest_major.$((latest_minor_num - 1))"
fi

lts_version=""
if [[ -n "$lts_minor" ]]; then
	lts_version="$(printf "%s\n" "$stable_versions" | grep -E "^${lts_minor}\." | tail -1)"
fi

# Recent versions
recent_versions="$(printf "%s\n" "$stable_versions" | tail -n "$RECENT_COUNT")"

# Build options
declare -a display_options=()
declare -a version_options=()

add_option() {
	local label="$1"
	local version="$2"
	local v

	if [[ -z "$version" ]]; then
		return
	fi

	# Check for duplicates
	if [[ ${#version_options[@]} -gt 0 ]]; then
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

# Check if we have options
options_count=${#version_options[@]}

if [[ "$options_count" -eq 0 ]]; then
	print_error "No installable versions found."
	exit 1
fi

# Display menu
echo ""
echo "🎯 Choose a Go version to install:"
echo "=================================="
idx=1
for opt in "${display_options[@]}"; do
	echo "  [$idx] $opt"
	idx=$((idx + 1))
done
echo ""

read -r -p "Enter number (1-$options_count): " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "$options_count" ]]; then
	print_error "Invalid selection."
	exit 1
fi

TARGET_VERSION="${version_options[$((choice - 1))]}"

echo ""
print_info "Installing Go $TARGET_VERSION..."
goenv install -s "$TARGET_VERSION"
print_success "Go $TARGET_VERSION installed"

print_info "Setting Go $TARGET_VERSION as global version..."
goenv global "$TARGET_VERSION"
print_success "Global version set"

echo ""
print_success "Installation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart your terminal or run: source $profile_file"
echo "   2. Verify installation: go version"
echo "   3. Check goenv versions: goenv versions"
echo ""
echo "💡 Configuration added to: $profile_file"
echo "   This ensures Go is available in all shell contexts (interactive, scripts, cron)"
echo ""