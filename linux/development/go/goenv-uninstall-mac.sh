#!/usr/bin/env bash
set -euo pipefail

# goenv uninstaller for macOS and Linux (bash/zsh)
#:[.'.]:>- ==================================================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
#:[.'.]:>- ==================================================================================

# Configuration
GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"

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

verify_removal() {
	echo ""
	echo "🔍 Verifying goenv removal..."
	echo "=============================="
	echo ""
	
	local all_clean=true
	
	# Check goenv command
	if command -v goenv >/dev/null 2>&1; then
		print_error "goenv is still available: $(which goenv)"
		all_clean=false
	else
		print_success "goenv command not found"
	fi
	
	# Check go command
	if command -v go >/dev/null 2>&1; then
		print_warning "go is still available: $(which go)"
		echo "   Version: $(go version)"
		echo "   (This might be a system Go installation)"
	else
		print_success "go command not found"
	fi
	
	# Check directory
	if [[ -d "$GOENV_ROOT" ]]; then
		print_error "goenv directory still exists: $GOENV_ROOT"
		all_clean=false
	else
		print_success "goenv directory removed"
	fi
	
	# Check environment variables (in a new shell to avoid cached values)
	if bash -c '[[ -n "${GOENV_ROOT:-}" ]]' 2>/dev/null; then
		print_error "GOENV_ROOT still set in environment"
		all_clean=false
	else
		print_success "GOENV_ROOT not set"
	fi
	
	# Check profile file
	if [[ -f "$profile_file" ]] && grep -q 'goenv' "$profile_file" 2>/dev/null; then
		print_warning "goenv references still found in $profile_file"
		all_clean=false
	else
		print_success "Profile file is clean"
	fi
	
	echo ""
	if [[ "$all_clean" == true ]]; then
		print_success "All checks passed! goenv has been completely removed."
	else
		print_warning "Some issues detected. You may need to manually clean up."
	fi
	echo ""
}

# Detect OS and set profile file
os_name="$(uname -s)"
if [[ "$os_name" == "Darwin" ]]; then
	profile_file="$HOME/.zshenv"
	shell_name="zsh"
elif [[ "$os_name" == "Linux" ]]; then
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

echo "🗑️  goenv Uninstaller"
echo "===================="
echo ""
print_warning "This will remove goenv and all installed Go versions!"
print_info "goenv directory: $GOENV_ROOT"
print_info "Profile file: $profile_file"
echo ""

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	print_info "Uninstall cancelled."
	exit 0
fi

echo ""

# Remove goenv directory
if [[ -d "$GOENV_ROOT" ]]; then
	print_info "Removing goenv from: $GOENV_ROOT"
	rm -rf "$GOENV_ROOT"
	print_success "goenv directory removed"
else
	print_warning "goenv directory not found: $GOENV_ROOT"
fi

# Clean profile file
if [[ -f "$profile_file" ]]; then
	# Create backup
	backup_file="${profile_file}.backup-$(date +%Y%m%d-%H%M%S)"
	cp "$profile_file" "$backup_file"
	print_info "Backup created: $backup_file"
	
	# Remove goenv configuration block
	print_info "Removing goenv configuration from $profile_file..."
	
	tmp_file="${profile_file}.tmp"
	
	# Remove the entire goenv configuration block
	awk '
		BEGIN { in_goenv_block = 0 }
		/# goenv configuration/ { in_goenv_block = 1; next }
		in_goenv_block && /^export PATH="\$GOPATH\/bin:\$PATH"/ { in_goenv_block = 0; next }
		in_goenv_block { next }
		{ print }
	' "$profile_file" > "$tmp_file"
	
	mv "$tmp_file" "$profile_file"
	
	# Verify removal
	if grep -q 'goenv' "$profile_file" 2>/dev/null; then
		print_warning "Some goenv references might still exist in $profile_file"
		print_info "Please review manually: $profile_file"
	else
		print_success "goenv configuration removed from $profile_file"
	fi
else
	print_warning "$profile_file not found, skipping."
fi

# Clean up environment variables in current session
unset GOENV_ROOT 2>/dev/null || true
unset GOROOT 2>/dev/null || true
unset GOPATH 2>/dev/null || true

echo ""
print_success "Uninstall complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart your terminal or run: source $profile_file"
echo "   2. Verify removal with the verification tool"
echo ""
echo "💾 Backup saved at: $backup_file"

# Ask if user wants to verify
echo ""
read -p "Do you want to verify the removal now? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
	verify_removal
else
	echo ""
	print_info "You can verify manually later by running:"
	echo "   source $profile_file && bash $0 --verify"
fi

echo ""