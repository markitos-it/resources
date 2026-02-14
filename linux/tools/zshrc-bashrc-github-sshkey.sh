#!/usr/bin/env bash
# shellcheck disable=SC1090
set -euo pipefail

# GitHub SSH Key Setup for Linux (bash) and macOS (zsh)
# Usage:
#   bash setup-github-ssh.sh
#
# Required env vars:
#   GIT_EMAIL       (default: markitos.es.info@gmail.com)
#   GIT_NAME        (default: Marco Antonio DevSecOps Kulture - El camino del Artesano)
#
# Optional env vars:
#   SSH_KEY_TYPE    (default: ed25519; alternative: rsa)
#   SSH_KEY_FILE    (default: $HOME/.ssh/github)

need_cmd() {
	command -v "$1" >/dev/null 2>&1
}

if ! need_cmd ssh-keygen; then
	echo "Error: ssh-keygen is required." >&2
	exit 1
fi

if ! need_cmd ssh-add; then
	echo "Error: ssh-add is required." >&2
	exit 1
fi

# Required Configuration
EMAIL="${GIT_EMAIL:-markitos.es.info@gmail.com}"
NAME="${GIT_NAME:-Marco Antonio - DevSecOps Kulture. The Way of the Artisan}"

# Validate required parameters
if [[ -z "$EMAIL" ]]; then
	echo "Error: GIT_EMAIL is required." >&2
	echo "Usage: GIT_EMAIL=your@email.com GIT_NAME='Your Name' bash setup-github-ssh.sh" >&2
	exit 1
fi

if [[ -z "$NAME" ]]; then
	echo "Error: GIT_NAME is required." >&2
	echo "Usage: GIT_EMAIL=your@email.com GIT_NAME='Your Name' bash setup-github-ssh.sh" >&2
	exit 1
fi

# Optional Configuration
KEY_TYPE="${SSH_KEY_TYPE:-ed25519}"
KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/github}"
SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"
SSH_ENV="$SSH_DIR/agent.env"

echo "🔐 GitHub SSH Key Setup"
echo "======================="
echo ""
echo "📧 Email: $EMAIL"
echo "👤 Name:  $NAME"
echo "🔑 Key Type: $KEY_TYPE"
echo "📁 Key File: $KEY_FILE"
echo ""

# Create .ssh directory if it doesn't exist
if [[ ! -d "$SSH_DIR" ]]; then
	echo "Creating $SSH_DIR directory..."
	mkdir -p "$SSH_DIR"
	chmod 700 "$SSH_DIR"
fi

# Check if key already exists
if [[ -f "$KEY_FILE" ]]; then
	echo "⚠️  SSH key already exists at $KEY_FILE"
	read -p "Do you want to overwrite it? (y/N): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Aborted."
		exit 0
	fi
fi

# Generate SSH key
echo "Generating $KEY_TYPE SSH key with email: $EMAIL"
ssh-keygen -t "$KEY_TYPE" -C "$EMAIL" -f "$KEY_FILE" -N ""

if [[ ! -f "$KEY_FILE" ]]; then
	echo "Error: SSH key generation failed." >&2
	exit 1
fi

echo "✅ SSH key generated successfully!"
echo ""

# Start or reuse ssh-agent
start_agent() {
	echo "Starting new SSH agent..."
	/usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
	chmod 600 "${SSH_ENV}"
	. "${SSH_ENV}" > /dev/null
}

# Check if agent.env exists and source it
if [ -f "${SSH_ENV}" ]; then
	. "${SSH_ENV}" > /dev/null
	# Check if the agent is still running
	if ! ps -p "${SSH_AGENT_PID:-0}" > /dev/null 2>&1; then
		start_agent
	fi
else
	start_agent
fi

echo "Adding key to ssh-agent..."
ssh-add "$KEY_FILE"

echo "✅ Key added to ssh-agent!"
echo ""

# Check if GitHub config already exists
if [[ -f "$CONFIG_FILE" ]] && grep -q "Host github.com" "$CONFIG_FILE"; then
	echo "⚠️  GitHub configuration already exists in $CONFIG_FILE"
else
	echo "Configuring SSH for GitHub..."
	cat >> "$CONFIG_FILE" << EOF

# GitHub - Added $(date +%Y-%m-%d)
Host github.com
    HostName github.com
    User git
    IdentityFile $KEY_FILE
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF
	chmod 600 "$CONFIG_FILE"
	echo "✅ SSH config updated!"
fi

echo ""

# Auto-load ssh-agent in shell profile
os_name="$(uname -s)"
if [[ "$os_name" == "Darwin" ]]; then
	profile_file="$HOME/.zshrc"
	shell_name="zsh"
else
	profile_file="$HOME/.bashrc"
	shell_name="bash"
fi

# Add ssh-agent smart auto-start to profile
ssh_agent_config=$(cat <<'EOF'
# SSH Agent - Smart start (reuses existing agent)
SSH_ENV="$HOME/.ssh/agent.env"

start_agent() {
	/usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
	chmod 600 "${SSH_ENV}"
	. "${SSH_ENV}" > /dev/null
}

# Check if agent.env exists and source it
if [ -f "${SSH_ENV}" ]; then
	. "${SSH_ENV}" > /dev/null
	# Check if the agent is still running
	if ! ps -p "${SSH_AGENT_PID:-0}" > /dev/null 2>&1; then
		start_agent
	fi
else
	start_agent
fi
EOF

if [[ -f "$profile_file" ]]; then
	# Remove old ssh-agent config if exists
	if grep -q "# SSH Agent - Auto-start" "$profile_file"; then
		echo "Removing old ssh-agent configuration..."
		# Create backup
		cp "$profile_file" "${profile_file}.backup-$(date +%Y%m%d-%H%M%S)"
		# Remove old config (simple version)
		sed -i.tmp '/# SSH Agent - Auto-start/,+3d' "$profile_file" 2>/dev/null || true
		rm -f "${profile_file}.tmp"
	fi
	
	if ! grep -q "# SSH Agent - Smart start" "$profile_file"; then
		echo "Adding smart ssh-agent auto-start to $profile_file..."
		echo "$ssh_agent_config" >> "$profile_file"
		echo "✅ Shell profile updated!"
	else
		echo "⚠️  Smart ssh-agent config already exists in $profile_file"
	fi
fi

# Display public key
echo ""
echo "=========================================="
echo "📋 Tu clave pública SSH (cópiala):"
echo "=========================================="
echo ""
cat "${KEY_FILE}.pub"
echo ""
echo "=========================================="
echo ""
echo "📝 Próximos pasos:"
echo ""
echo "1. Copia la clave pública mostrada arriba"
echo "2. Ve a: https://github.com/settings/ssh/new"
echo "3. Title: $(hostname)-$(date +%Y-%m-%d)"
echo "4. Key Type: Authentication Key"
echo "5. Pega la clave pública"
echo "6. Click 'Add SSH key'"
echo ""
echo "🧪 Para verificar la conexión:"
echo "   ssh -T git@github.com"
echo ""
echo "🔄 Recarga tu shell para aplicar cambios:"
echo "   source $profile_file"
echo ""
echo "✨ Archivos creados:"
echo "   - $KEY_FILE (clave privada - ¡nunca la compartas!)"
echo "   - ${KEY_FILE}.pub (clave pública)"
echo "   - $CONFIG_FILE (configuración SSH)"
echo "   - $SSH_ENV (información del agente SSH)"
echo ""
echo "🧹 Para limpiar agentes antiguos:"
echo "   pkill ssh-agent && source $profile_file"
echo ""