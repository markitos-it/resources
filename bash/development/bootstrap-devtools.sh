#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
# ============================================================

# ── Flags ─────────────────────────────────────────────────────
ALL_YES=false
for arg in "$@"; do
    [[ "$arg" == "--all-yes" ]] && ALL_YES=true
done

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────
print_error()   { echo -e "${RED}✖  $1${NC}" >&2; }
print_success() { echo -e "${GREEN}✔  $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ  $1${NC}"; }
print_warn()    { echo -e "${YELLOW}⚠  $1${NC}"; }
print_kv()      { echo -e "${CYAN}▸  ${BOLD}$1${NC}${CYAN}: $2${NC}"; }
print_skip()    { echo -e "${DIM}⊘  $1 — omitido${NC}"; }
print_already() { echo -e "${GREEN}✔  $1 — ya instalado, actualizando...${NC}"; }
print_line()    { echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

pause() {
    echo ""
    for i in 2 1; do
        echo -ne "${YELLOW}⏳ Continuando en ${i}s...${NC}\r"
        sleep 1
    done
    echo -e "${GREEN}▶  Arrancando...          ${NC}"
    echo ""
}

ask_confirm() {
    if [[ "$ALL_YES" == true ]]; then return 0; fi
    while true; do
        echo -ne "${YELLOW}${BOLD}¿Continuar? [y/n]: ${NC}"
        read -r reply
        case "$reply" in
            [Yy]) return 0 ;;
            [Nn]) print_warn "Instalación cancelada."; exit 0 ;;
            *)    print_warn "Responde y o n." ;;
        esac
    done
}

ask_install() {
    local tool="$1"
    if [[ "$ALL_YES" == true ]]; then
        print_info "--all-yes: instalando/actualizando ${tool} automáticamente"
        return 0
    fi
    echo ""
    while true; do
        echo -ne "${YELLOW}¿Instalar/actualizar ${BOLD}${tool}${NC}${YELLOW}? [y/n]: ${NC}"
        read -r reply
        case "$reply" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            *)    print_warn "Responde y o n." ;;
        esac
    done
}

sudo_init() {
    if sudo -n true 2>/dev/null; then
        print_success "sudo — ticket activo, no se necesita contraseña"
        return 0
    fi
    echo ""
    print_info "Se necesita sudo para instalar dependencias del sistema."
    print_info "Introduce tu contraseña una sola vez — no se usará root para nada más."
    echo ""
    if sudo -v; then
        print_success "sudo autenticado — no se volverá a pedir durante esta sesión"
        ( while true; do sudo -n true; sleep 50; done ) &
        SUDO_KEEPALIVE_PID=$!
        trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
    else
        print_error "No se pudo autenticar sudo. Abortando."
        exit 1
    fi
    echo ""
}

section_start() {
    local tool="$1" desc="$2"
    echo ""
    echo ""
    echo -e "${CYAN}#:[.'.]:>- ===================================================================================${NC}"
    echo -e "${CYAN}#:[.'.]:>-${NC} ${BOLD}STARTOF.${tool}${NC} ${BLUE}- ${desc}${NC}"
    echo -e "${CYAN}#:[.'.]:>- ===================================================================================${NC}"
    echo ""
}

section_end() {
    local tool="$1" desc="$2"
    echo ""
    echo -e "${CYAN}#:[.'.]:>- ===================================================================================${NC}"
    echo -e "${CYAN}#:[.'.]:>-${NC} ${BOLD}ENDOF.${tool}${NC} ${BLUE}- ${desc}${NC}"
    echo -e "${CYAN}#:[.'.]:>- ===================================================================================${NC}"
    echo ""
    echo ""
}

append_if_missing() {
    local line="$1" file="$2"
    touch "$file"
    if ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
        print_success "Añadido → ${file}"
        echo -e "${DIM}  ${line}${NC}"
    else
        echo -e "${DIM}✔  profile ya tiene → ${line}${NC}"
    fi
}

# ── Detect OS & profile ───────────────────────────────────────
OS_NAME="$(uname -s)"
if [[ "$OS_NAME" == "Darwin" ]] || [[ "$SHELL" == *"zsh"* ]] || [[ -n "${ZSH_VERSION:-}" ]]; then
    PROFILE_FILE="$HOME/.zshrc"
    SHELL_NAME="zsh"
else
    PROFILE_FILE="$HOME/.bashrc"
    SHELL_NAME="bash"
fi

# ── Detect arch for gcloud ────────────────────────────────────
detect_arch() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "$os" in
        Linux)
            case "$arch" in
                x86_64|amd64)  echo "linux-x86_64" ;;
                aarch64|arm64) echo "linux-arm" ;;
                *)             echo "" ;;
            esac ;;
        Darwin)
            case "$arch" in
                x86_64|amd64)  echo "darwin-x86_64" ;;
                arm64)         echo "darwin-arm" ;;
                *)             echo "" ;;
            esac ;;
        *) echo "" ;;
    esac
}

NVM_DIR="$HOME/.nvm"
NVM_VERSION="v0.40.3"
TFENV_ROOT="$HOME/.tfenv"
GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
GCLOUD_DIR="${GCLOUD_INSTALL_DIR:-$HOME/google-cloud-sdk}"
GCLOUD_ARCH="${GCLOUD_ARCH:-$(detect_arch)}"

INSTALLED_NVM=false
INSTALLED_TFENV=false
INSTALLED_GOENV=false
INSTALLED_GCLOUD=false

# ════════════════════════════════════════════════════════════
#  PLAN
# ════════════════════════════════════════════════════════════
echo ""
print_line
echo -e "${CYAN}${BOLD}Artisan DevTools Bootstrap  •  nvm · tfenv · goenv · gcloud${NC}"
echo -e "${DIM}markitos devsecops kulture — The Way of the Artisan${NC}"
print_line
echo ""

if [[ "$ALL_YES" == true ]]; then
    echo -e "${GREEN}${BOLD}Modo --all-yes${NC}${DIM} (sin confirmaciones, instala todo)${NC}"
else
    echo -e "${YELLOW}${BOLD}Modo interactivo${NC}${DIM} (se preguntará por cada herramienta)${NC}"
fi

echo ""
echo -e "${BOLD}Entorno${NC}"
print_kv "OS"      "$OS_NAME  /  $SHELL_NAME"
print_kv "Arch"    "$GCLOUD_ARCH"
print_kv "Profile" "$PROFILE_FILE"

echo ""
echo -e "${BOLD}Qué se instalará/actualizará y dónde${NC}"
[[ -d "$NVM_DIR"    ]] && echo -e "${YELLOW}①${NC}  ${BOLD}nvm${NC}    ${DIM}→${NC}  ${CYAN}${NVM_DIR}${NC}  ${GREEN}(ya existe — actualizará)${NC}" \
                        || echo -e "${YELLOW}①${NC}  ${BOLD}nvm${NC}    ${DIM}→${NC}  ${CYAN}${NVM_DIR}${NC}  ${DIM}(nueva instalación)${NC}"
[[ -d "$TFENV_ROOT" ]] && echo -e "${YELLOW}②${NC}  ${BOLD}tfenv${NC}  ${DIM}→${NC}  ${CYAN}${TFENV_ROOT}${NC}  ${GREEN}(ya existe — actualizará)${NC}" \
                        || echo -e "${YELLOW}②${NC}  ${BOLD}tfenv${NC}  ${DIM}→${NC}  ${CYAN}${TFENV_ROOT}${NC}  ${DIM}(nueva instalación)${NC}"
[[ -d "$GOENV_ROOT" ]] && echo -e "${YELLOW}③${NC}  ${BOLD}goenv${NC}  ${DIM}→${NC}  ${CYAN}${GOENV_ROOT}${NC}  ${GREEN}(ya existe — actualizará)${NC}" \
                        || echo -e "${YELLOW}③${NC}  ${BOLD}goenv${NC}  ${DIM}→${NC}  ${CYAN}${GOENV_ROOT}${NC}  ${DIM}(nueva instalación)${NC}"
[[ -d "$GCLOUD_DIR" ]] && echo -e "${YELLOW}④${NC}  ${BOLD}gcloud${NC} ${DIM}→${NC}  ${CYAN}${GCLOUD_DIR}${NC}  ${GREEN}(ya existe — actualizará)${NC}" \
                        || echo -e "${YELLOW}④${NC}  ${BOLD}gcloud${NC} ${DIM}→${NC}  ${CYAN}${GCLOUD_DIR}${NC}  ${DIM}(nueva instalación)${NC}"

echo ""
echo -e "${BOLD}Qué se añadirá a ${CYAN}${PROFILE_FILE}${NC}${BOLD} (solo si no existe)${NC}"
echo -e "${DIM}① nvm    — NVM_DIR, carga nvm.sh y bash_completion${NC}"
echo -e "${DIM}② tfenv  — \$HOME/.tfenv/bin en PATH${NC}"
echo -e "${DIM}③ goenv  — GOENV_ROOT, bin en PATH, goenv init, GOROOT/GOPATH${NC}"
echo -e "${DIM}④ gcloud — source path.bash.inc + completion.bash.inc${NC}"

echo ""
print_line
ask_confirm
sudo_init

# ════════════════════════════════════════════════════════════
#  PREREQS
# ════════════════════════════════════════════════════════════
section_start "PREREQS" "Verificando dependencias del sistema"

for cmd in curl git tar python3; do
    if need_cmd "$cmd"; then
        print_success "$cmd → $(command -v "$cmd")"
    else
        print_error "$cmd no encontrado — instálalo antes de continuar."
        exit 1
    fi
done

print_info "Instalando dependencias vía apt..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    build-essential libssl-dev libreadline-dev \
    zlib1g-dev libbz2-dev libffi-dev libsqlite3-dev unzip
print_success "Dependencias del sistema OK"

section_end "PREREQS" "Sistema listo"
pause

# ════════════════════════════════════════════════════════════
#  NVM
# ════════════════════════════════════════════════════════════
if ask_install "nvm (Node Version Manager)"; then

    section_start "NVM" "Node Version Manager — gestión de versiones de Node.js"

    print_kv "Repositorio" "https://github.com/nvm-sh/nvm"
    print_kv "Versión nvm" "$NVM_VERSION"
    print_kv "Directorio"  "$NVM_DIR"
    print_kv "Profile"     "$PROFILE_FILE"

    if [[ -d "$NVM_DIR/.git" ]]; then
        print_already "nvm en $NVM_DIR"
        git -C "$NVM_DIR" fetch --tags --quiet
        git -C "$NVM_DIR" checkout --quiet "$NVM_VERSION"
    elif [[ -d "$NVM_DIR" ]]; then
        print_warn "$NVM_DIR existe pero no es un repo git; se reutiliza sin actualizar versión"
    else
        print_info "Primera instalación de nvm (git clone)..."
        git clone --depth=1 --branch "$NVM_VERSION" https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    fi

    append_if_missing "export NVM_DIR=\"\$HOME/.nvm\"" "$PROFILE_FILE"
    append_if_missing "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" "$PROFILE_FILE"
    append_if_missing "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" "$PROFILE_FILE"

    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! need_cmd node; then
        print_info "Instalando Node.js LTS..."
        nvm install --lts
        nvm alias default node
    else
        print_info "node $(node --version) ya instalado — omitiendo descarga"
    fi

    print_success "nvm $(nvm --version)"
    print_success "node $(node --version) — npm $(npm --version)"
    print_kv "Versión activa" "$(nvm current)"
    print_kv "Ubicación node" "$(command -v node)"

    INSTALLED_NVM=true
    section_end "NVM" "Node Version Manager listo"
    pause

else
    print_skip "nvm"
fi

# ════════════════════════════════════════════════════════════
#  TFENV
# ════════════════════════════════════════════════════════════
if ask_install "tfenv (Terraform Version Manager)"; then

    section_start "TFENV" "Terraform Version Manager — gestión de versiones de Terraform"

    print_kv "Repositorio" "https://github.com/tfutils/tfenv"
    print_kv "Directorio"  "$TFENV_ROOT"
    print_kv "Profile"     "$PROFILE_FILE"

    if [[ -d "$TFENV_ROOT" ]]; then
        print_already "tfenv en $TFENV_ROOT"
        cd "$TFENV_ROOT" && git pull --quiet && cd - > /dev/null
        print_success "tfenv actualizado con git pull"
    else
        print_info "Clonando tfenv en $TFENV_ROOT..."
        git clone --depth=1 https://github.com/tfutils/tfenv.git "$TFENV_ROOT"
        print_success "tfenv clonado"
    fi

    append_if_missing "export PATH=\"\$HOME/.tfenv/bin:\$PATH\"" "$PROFILE_FILE"
    export PATH="$TFENV_ROOT/bin:$PATH"

    if need_cmd terraform; then
        print_info "$(terraform --version | head -1) ya instalado — omitiendo descarga"
        tfenv use latest 2>/dev/null || true
    else
        print_info "Instalando última versión de Terraform..."
        tfenv install latest
        tfenv use latest
    fi

    print_success "tfenv $(tfenv --version)"
    print_success "$(terraform --version | head -1)"
    print_kv "Ubicación terraform"  "$(command -v terraform)"
    print_kv "Versiones instaladas" "$(tfenv list | tr '\n' ' ')"

    INSTALLED_TFENV=true
    section_end "TFENV" "Terraform Version Manager listo"
    pause

else
    print_skip "tfenv"
fi

# ════════════════════════════════════════════════════════════
#  GOENV
# ════════════════════════════════════════════════════════════
if ask_install "goenv (Go Version Manager)"; then

    section_start "GOENV" "Go Version Manager — gestión de versiones de Go"

    print_kv "Repositorio" "https://github.com/go-nv/goenv"
    print_kv "Directorio"  "$GOENV_ROOT"
    print_kv "Profile"     "$PROFILE_FILE"

    if [[ -d "$GOENV_ROOT" ]]; then
        print_already "goenv en $GOENV_ROOT"
        cd "$GOENV_ROOT" && git pull --quiet && cd - > /dev/null
        print_success "goenv actualizado con git pull"
    else
        print_info "Clonando goenv en $GOENV_ROOT..."
        git clone --quiet https://github.com/go-nv/goenv.git "$GOENV_ROOT"
        print_success "goenv clonado"
    fi

    append_if_missing "export GOENV_ROOT=\"\$HOME/.goenv\""      "$PROFILE_FILE"
    append_if_missing "export PATH=\"\$GOENV_ROOT/bin:\$PATH\""  "$PROFILE_FILE"
    append_if_missing "eval \"\$(goenv init -)\""                "$PROFILE_FILE"
    append_if_missing "export PATH=\"\$GOROOT/bin:\$PATH\""      "$PROFILE_FILE"
    append_if_missing "export PATH=\"\$GOPATH/bin:\$PATH\""      "$PROFILE_FILE"

    export GOENV_ROOT="$GOENV_ROOT"
    export PATH="$GOENV_ROOT/bin:$PATH"
    eval "$(goenv init -)"

    RECENT_COUNT=5
    print_info "Obteniendo versiones disponibles de Go..."
    stable_versions="$(goenv install -l | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)"
    latest_version="$(printf "%s\n" "$stable_versions" | tail -1)"
    latest_major="$(printf "%s" "$latest_version"     | awk -F. '{print $1}')"
    latest_minor_num="$(printf "%s" "$latest_version" | awk -F. '{print $2}')"

    lts_version=""
    if [[ "$latest_minor_num" -gt 0 ]]; then
        lts_minor="$latest_major.$((latest_minor_num - 1))"
        lts_version="$(printf "%s\n" "$stable_versions" | grep -E "^${lts_minor}\." | tail -1)"
    fi
    recent_versions="$(printf "%s\n" "$stable_versions" | tail -n "$RECENT_COUNT")"

    declare -a display_options=()
    declare -a version_options=()

    add_option() {
        local label="$1" version="$2" v
        [[ -z "$version" ]] && return
        for v in "${version_options[@]+"${version_options[@]}"}"; do
            [[ "$v" == "$version" ]] && return
        done
        display_options+=("$label - $version")
        version_options+=("$version")
    }

    add_option "Latest           " "$latest_version"
    add_option "LTS (prev minor) " "$lts_version"
    while IFS= read -r v; do
        add_option "Recent           " "$v"
    done <<< "$recent_versions"

    options_count=${#version_options[@]}

    if [[ "$ALL_YES" == true ]]; then
        TARGET_VERSION="$latest_version"
        print_info "--all-yes: seleccionando Go ${TARGET_VERSION} (latest)"
    else
        echo ""
        echo -e "${BOLD}${CYAN}🎯 Selecciona la versión de Go a instalar:${NC}"
        print_line
        current_global="$(goenv global 2>/dev/null || echo "")"
        idx=1
        for opt in "${display_options[@]}"; do
            marker=""
            [[ "${opt}" == *"$current_global"* ]] && marker="  ${GREEN}← actual${NC}"
            echo -e "${YELLOW}[$idx]${NC} $opt${marker}"
            idx=$((idx + 1))
        done
        echo ""
        while true; do
            read -r -p "Introduce número (1-${options_count}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$options_count" ]]; then
                break
            fi
            print_warn "Introduce un número entre 1 y ${options_count}."
        done
        TARGET_VERSION="${version_options[$((choice - 1))]}"
    fi

    echo ""
    print_info "Instalando Go ${TARGET_VERSION} (se omite si ya existe)..."
    goenv install -s "$TARGET_VERSION"
    goenv global "$TARGET_VERSION"

    GO_PREFIX="$(goenv prefix)"
    export GOROOT="$GO_PREFIX"
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$GOROOT/bin:$PATH"
    export PATH="$GOPATH/bin:$PATH"

    print_success "$(go version)"
    print_kv "Ubicación go"   "$(command -v go)"
    print_kv "GOROOT"         "$GOROOT"
    print_kv "GOPATH"         "$GOPATH"
    print_kv "Versión global" "$(goenv global)"

    INSTALLED_GOENV=true
    section_end "GOENV" "Go Version Manager listo"
    pause

else
    print_skip "goenv"
fi

# ════════════════════════════════════════════════════════════
#  GCLOUD
# ════════════════════════════════════════════════════════════
if ask_install "gcloud (Google Cloud SDK)"; then

    section_start "GCLOUD" "Google Cloud SDK — CLI oficial de Google Cloud"

    if [[ -z "$GCLOUD_ARCH" ]]; then
        print_error "Arquitectura no soportada. Usa GCLOUD_ARCH=linux-x86_64 para forzarla."
        exit 1
    fi

    # Obtener última versión desde el JSON oficial
    print_info "Consultando última versión disponible..."
    GCLOUD_VERSION="$(
        curl -fsSL "https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json" | \
        python3 -c 'import json,sys;print(json.load(sys.stdin).get("version",""))'
    )"
    if [[ -z "$GCLOUD_VERSION" ]]; then
        print_error "No se pudo determinar la versión de gcloud."
        exit 1
    fi

    print_kv "Versión"     "$GCLOUD_VERSION"
    print_kv "Arch"        "$GCLOUD_ARCH"
    print_kv "Directorio"  "$GCLOUD_DIR"
    print_kv "Profile"     "$PROFILE_FILE"

    if [[ -d "$GCLOUD_DIR" ]]; then
        # Ya existe — actualizar con gcloud components update
        print_already "gcloud en $GCLOUD_DIR"
        if [[ -x "$GCLOUD_DIR/bin/gcloud" ]]; then
            print_info "Actualizando componentes con gcloud components update..."
            "$GCLOUD_DIR/bin/gcloud" components update --quiet
            print_success "gcloud actualizado"
        else
            print_warn "Directorio existe pero gcloud no encontrado — reinstalando..."
            rm -rf "$GCLOUD_DIR"
        fi
    fi

    # Instalación fresca si no existe (o fue borrado arriba)
    if [[ ! -d "$GCLOUD_DIR" ]]; then
        TARBALL="google-cloud-cli-${GCLOUD_VERSION}-${GCLOUD_ARCH}.tar.gz"
        DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${TARBALL}"

        tmp_dir="$(mktemp -d)"

        print_info "Descargando ${TARBALL}..."
        curl -fsSL "$DOWNLOAD_URL" -o "$tmp_dir/$TARBALL"

        print_info "Extrayendo en $(dirname "$GCLOUD_DIR")..."
        mkdir -p "$(dirname "$GCLOUD_DIR")"
        tar -xzf "$tmp_dir/$TARBALL" -C "$(dirname "$GCLOUD_DIR")"

        if [[ ! -x "$GCLOUD_DIR/bin/gcloud" ]]; then
            print_error "gcloud no encontrado tras la extracción."
            exit 1
        fi

        print_info "Ejecutando install.sh..."
        "$GCLOUD_DIR/install.sh" --quiet
        rm -rf "$tmp_dir"
        print_success "gcloud instalado"
    fi

    # Profile
    if [[ "$SHELL_NAME" == "zsh" ]]; then
        append_if_missing "source '${GCLOUD_DIR}/path.zsh.inc'"        "$PROFILE_FILE"
        append_if_missing "source '${GCLOUD_DIR}/completion.zsh.inc'"  "$PROFILE_FILE"
    else
        append_if_missing "source '${GCLOUD_DIR}/path.bash.inc'"        "$PROFILE_FILE"
        append_if_missing "source '${GCLOUD_DIR}/completion.bash.inc'"  "$PROFILE_FILE"
    fi

    # Cargar en sesión actual
    if [[ "$SHELL_NAME" == "zsh" ]]; then
        [[ -f "${GCLOUD_DIR}/path.zsh.inc" ]]       && source "${GCLOUD_DIR}/path.zsh.inc"
        [[ -f "${GCLOUD_DIR}/completion.zsh.inc" ]] && source "${GCLOUD_DIR}/completion.zsh.inc"
    else
        [[ -f "${GCLOUD_DIR}/path.bash.inc" ]]       && source "${GCLOUD_DIR}/path.bash.inc"
        [[ -f "${GCLOUD_DIR}/completion.bash.inc" ]] && source "${GCLOUD_DIR}/completion.bash.inc"
    fi

    print_success "$(gcloud --version | head -1)"
    print_kv "Ubicación gcloud" "$(command -v gcloud)"

    INSTALLED_GCLOUD=true
    section_end "GCLOUD" "Google Cloud SDK listo"
    pause

else
    print_skip "gcloud"
fi

# ════════════════════════════════════════════════════════════
#  HEALTH CHECKER
# ════════════════════════════════════════════════════════════
section_start "CHECKER" "Verificando que todo está correctamente instalado"

check_ok=true

if [[ "$INSTALLED_NVM" == true ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if need_cmd node; then
        print_success "nvm: $(nvm --version) | node: $(node --version) | npm: $(npm --version)"
        print_kv "node bin" "$(command -v node)"
    else
        print_error "node no encontrado tras instalar nvm"
        check_ok=false
    fi
else
    echo -e "${DIM}⊘  nvm — no instalado en esta ejecución${NC}"
fi

if [[ "$INSTALLED_TFENV" == true ]]; then
    export PATH="$TFENV_ROOT/bin:$PATH"
    if need_cmd terraform; then
        print_success "tfenv: $(tfenv --version) | $(terraform --version | head -1)"
        print_kv "terraform bin" "$(command -v terraform)"
    else
        print_error "terraform no encontrado tras instalar tfenv"
        check_ok=false
    fi
else
    echo -e "${DIM}⊘  tfenv — no instalado en esta ejecución${NC}"
fi

if [[ "$INSTALLED_GOENV" == true ]]; then
    export GOENV_ROOT="$GOENV_ROOT"
    export PATH="$GOENV_ROOT/bin:$PATH"
    eval "$(goenv init -)" 2>/dev/null || true
    GO_PREFIX="$(goenv prefix 2>/dev/null || echo "")"
    if [[ -n "$GO_PREFIX" ]]; then
        export GOROOT="$GO_PREFIX"
        export PATH="$GOROOT/bin:$PATH"
    fi
    if need_cmd go; then
        print_success "goenv: $(goenv --version) | $(go version)"
        print_kv "go bin"  "$(command -v go)"
        print_kv "GOROOT"  "${GOROOT:-n/a}"
        print_kv "GOPATH"  "${GOPATH:-$HOME/go}"
        print_kv "global"  "$(goenv global)"
    else
        print_error "go no encontrado tras instalar goenv"
        check_ok=false
    fi
else
    echo -e "${DIM}⊘  goenv — no instalado en esta ejecución${NC}"
fi

if [[ "$INSTALLED_GCLOUD" == true ]]; then
    if need_cmd gcloud; then
        print_success "$(gcloud --version | head -1)"
        print_kv "gcloud bin" "$(command -v gcloud)"
    else
        print_error "gcloud no encontrado tras la instalación"
        check_ok=false
    fi
else
    echo -e "${DIM}⊘  gcloud — no instalado en esta ejecución${NC}"
fi

echo ""
print_line
if [[ "$check_ok" == true ]]; then
    echo -e "${GREEN}${BOLD}✅ Checker OK — todo operativo${NC}"
else
    echo -e "${RED}${BOLD}✖  Checker detectó errores — revisa los mensajes arriba${NC}"
fi
print_line

section_end "CHECKER" "Health check completado"

# ════════════════════════════════════════════════════════════
#  RESUMEN FINAL
# ════════════════════════════════════════════════════════════
echo ""
print_line
echo -e "${GREEN}${BOLD}Bootstrap completado${NC}"
print_line
echo ""
print_kv "Profile" "$PROFILE_FILE"
echo ""
echo -e "${YELLOW}▸ Recarga el shell:${NC}  ${CYAN}source ${PROFILE_FILE}${NC}"
echo ""
echo -e "${DIM}#:[.'.]:>- The Way of the Artisan 🥷${NC}"
echo ""