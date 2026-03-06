#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
# ============================================================
#
# USAGE:
#   export PROJECT_ID=put-your-project-id-here
#   export PROJECT_NUMBER=put-your-project-number-here
#   export GITHUB_ORG=put-your-github-org-here
#   export GITHUB_REPO=put-your-github-repo-here
#   export ARTIFACT_REGISTRY_REPO=put-your-artifact-registry-repo-here
#
#   bash bin/gcp/publish-to-gcp-from-github-action.sh
#   bash bin/gcp/publish-to-gcp-from-github-action.sh --all-yes
#
# ============================================================

# ── Flags ─────────────────────────────────────────────────────
ALL_YES=false
for arg in "$@"; do
    [[ "$arg" == "--all-yes" ]] && ALL_YES=true
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        sed -n '/^# USAGE:/,/^# ===/p' "$0"
        exit 0
    fi
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
print_line()    { echo -e "${CYAN}────────────────────────────────���─────────────────────${NC}"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

pause() {
    echo ""
    for i in 5 4 3 2 1; do
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
            [Nn]) print_warn "Operación cancelada."; exit 0 ;;
            *)    print_warn "Responde y o n." ;;
        esac
    done
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

# ── Config ────────────────────────────────────────────────────
SA_NAME="put-your-sa-name-here"
SA_DISPLAY_NAME="put-your-sa-display-name-here"
SA_DESCRIPTION="put-your-sa-description-here"
WIF_POOL="put-your-wif-pool-name-here"
WIF_PROVIDER="put-your-wif-provider-name-here"
REGION="put-your-artifact-registry-region-here" # ej: us-central1

# ── Required vars ──────────────────────────────────────────────
: "${PROJECT_ID:?❌ Debes exportar PROJECT_ID antes de ejecutar este script}"
: "${PROJECT_NUMBER:?❌ Debes exportar PROJECT_NUMBER antes de ejecutar este script}"
: "${GITHUB_ORG:?❌ Debes exportar GITHUB_ORG (ej: put-your-github-org-here) antes de ejecutar este script}"
: "${GITHUB_REPO:?❌ Debes exportar GITHUB_REPO (ej: put-your-github-repo-here) antes de ejecutar este script}"
: "${ARTIFACT_REGISTRY_REPO:?❌ Debes exportar ARTIFACT_REGISTRY_REPO (ej: put-your-artifact-registry-repo-here) antes de ejecutar este script}"

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
WIF_PROVIDER_FULL="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL}/providers/${WIF_PROVIDER}"
PRINCIPAL_SET="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

# ════════════════════════════════════════════════════════════
#  PLAN
# ════════════════════════════════════════════════════════════
echo ""
print_line
echo -e "${CYAN}${BOLD}GCP GitHub Actions Publisher Setup${NC}"
echo -e "${DIM}markitos devsecops kulture — The Way of the Artisan${NC}"
print_line
echo ""

if [[ "$ALL_YES" == true ]]; then
    echo -e "${GREEN}${BOLD}Modo --all-yes${NC}${DIM} (sin confirmaciones)${NC}"
else
    echo -e "${YELLOW}${BOLD}Modo interactivo${NC}${DIM} (se preguntará antes de continuar)${NC}"
fi

echo ""
echo -e "${BOLD}Configuración${NC}"
print_kv "PROJECT_ID"               "$PROJECT_ID"
print_kv "PROJECT_NUMBER"           "$PROJECT_NUMBER"
print_kv "SA_NAME"                  "$SA_NAME"
print_kv "SA_EMAIL"                 "$SA_EMAIL"
print_kv "GITHUB_ORG"               "$GITHUB_ORG"
print_kv "GITHUB_REPO"              "$GITHUB_REPO"
print_kv "WIF_POOL"                 "$WIF_POOL"
print_kv "WIF_PROVIDER"             "$WIF_PROVIDER"
print_kv "ARTIFACT_REGISTRY_REPO"   "$ARTIFACT_REGISTRY_REPO"
print_kv "REGION"                   "$REGION"
print_kv "PRINCIPAL_SET"            "$PRINCIPAL_SET"

echo ""
echo -e "${BOLD}Pasos que se ejecutarán:${NC}"
echo -e "${YELLOW}①${NC}  Verificar prerrequisitos (gcloud, autenticación, APIs)"
echo -e "${YELLOW}②${NC}  Crear Service Account ${BOLD}${SA_NAME}${NC}"
echo -e "${YELLOW}③${NC}  Asignar rol ${BOLD}roles/artifactregistry.writer${NC} en el proyecto"
echo -e "${YELLOW}④${NC}  Vincular WIF pool → SA para el repo ${BOLD}${GITHUB_ORG}/${GITHUB_REPO}${NC}"
echo -e "${YELLOW}⑤${NC}  Verificar Artifact Registry repository existe"
echo -e "${YELLOW}⑥${NC}  Health check final"

echo ""
print_line
ask_confirm

# ════════════════════════════════════════════════════════════
#  PASO 1 — PRERREQUISITOS
# ════════════════════════════════════════════════════════════
section_start "PREREQS" "Verificando prerrequisitos"

print_info "Verificando gcloud..."
if ! need_cmd gcloud; then
    print_error "gcloud no encontrado. Instala Google Cloud SDK primero."
    exit 1
fi
print_success "gcloud → $(gcloud --version | head -1)"

print_info "Verificando autenticación activa..."
ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -1)"
if [[ -z "$ACTIVE_ACCOUNT" ]]; then
    print_error "No hay cuenta activa en gcloud. Ejecuta: gcloud auth login"
    exit 1
fi
print_success "Cuenta activa: ${ACTIVE_ACCOUNT}"

print_info "Configurando proyecto activo..."
gcloud config set project "${PROJECT_ID}" --quiet
print_success "Proyecto activo: ${PROJECT_ID}"

print_info "Habilitando APIs necesarias..."
gcloud services enable \
    iam.googleapis.com \
    iamcredentials.googleapis.com \
    artifactregistry.googleapis.com \
    --project="${PROJECT_ID}" \
    --quiet
print_success "APIs habilitadas: iam, iamcredentials, artifactregistry"

section_end "PREREQS" "Prerrequisitos verificados"
pause

# ════════════════════════════════════════════════════════════
#  PASO 2 — CREAR SERVICE ACCOUNT
# ════════════════════════════════════════════════════════════
section_start "SERVICE_ACCOUNT" "Creando Service Account"

print_kv "SA Email"       "$SA_EMAIL"
print_kv "Display Name"   "$SA_DISPLAY_NAME"
print_kv "Description"    "$SA_DESCRIPTION"

if gcloud iam service-accounts describe "${SA_EMAIL}" \
    --project="${PROJECT_ID}" \
    --quiet >/dev/null 2>&1; then
    print_warn "La Service Account ${SA_EMAIL} ya existe — omitiendo creación"
else
    print_info "Creando Service Account..."
    gcloud iam service-accounts create "${SA_NAME}" \
        --display-name="${SA_DISPLAY_NAME}" \
        --description="${SA_DESCRIPTION}" \
        --project="${PROJECT_ID}"
    print_success "Service Account creada: ${SA_EMAIL}"
fi

print_info "Verificando SA..."
gcloud iam service-accounts describe "${SA_EMAIL}" \
    --project="${PROJECT_ID}" \
    --format="table(email, displayName, disabled)"

section_end "SERVICE_ACCOUNT" "Service Account lista"
pause

# ════════════════════════════════════════════════════════════
#  PASO 3 — ROL ARTIFACT REGISTRY WRITER
# ════════════════════════════════════════════════════════════
section_start "IAM_ROLES" "Asignando roles IAM"

print_info "Asignando roles/artifactregistry.writer al proyecto..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/artifactregistry.writer" \
    --condition=None \
    --quiet
print_success "Rol roles/artifactregistry.writer asignado"

print_info "Verificando roles actuales de la SA..."
gcloud projects get-iam-policy "${PROJECT_ID}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:${SA_EMAIL}"

section_end "IAM_ROLES" "Roles IAM asignados"
pause

# ════════════════════════════════════════════════════════════
#  PASO 4 — VINCULAR WIF POOL → SA
# ════════════════════════════════════════════════════════════
section_start "WIF_BINDING" "Vinculando Workload Identity Federation"

print_kv "WIF Provider"    "$WIF_PROVIDER_FULL"
print_kv "Principal Set"   "$PRINCIPAL_SET"
print_kv "Repo"            "${GITHUB_ORG}/${GITHUB_REPO}"

print_info "Verificando que el WIF pool existe..."
if ! gcloud iam workload-identity-pools describe "${WIF_POOL}" \
    --location=global \
    --project="${PROJECT_ID}" \
    --quiet >/dev/null 2>&1; then
    print_error "WIF pool '${WIF_POOL}' no encontrado en proyecto ${PROJECT_ID}."
    print_info "Créalo primero o ajusta la variable WIF_POOL."
    exit 1
fi
print_success "WIF pool '${WIF_POOL}' existe"

print_info "Verificando que el WIF provider existe..."
if ! gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER}" \
    --workload-identity-pool="${WIF_POOL}" \
    --location=global \
    --project="${PROJECT_ID}" \
    --quiet >/dev/null 2>&1; then
    print_error "WIF provider '${WIF_PROVIDER}' no encontrado."
    exit 1
fi
print_success "WIF provider '${WIF_PROVIDER}' existe"

print_info "Añadiendo binding Workload Identity User para ${GITHUB_ORG}/${GITHUB_REPO}..."
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
    --member="${PRINCIPAL_SET}" \
    --role="roles/iam.workloadIdentityUser" \
    --project="${PROJECT_ID}"
print_success "Binding WIF → SA creado para ${GITHUB_ORG}/${GITHUB_REPO}"

print_info "Verificando bindings actuales de la SA..."
gcloud iam service-accounts get-iam-policy "${SA_EMAIL}" \
    --project="${PROJECT_ID}"

section_end "WIF_BINDING" "Workload Identity Federation vinculado"
pause

# ════════════════════════════════════════════════════════════
#  PASO 5 — VERIFICAR ARTIFACT REGISTRY
# ════════════════════════════════════════════════════════════
section_start "ARTIFACT_REGISTRY" "Verificando Artifact Registry"

print_kv "Repositorio"  "$ARTIFACT_REGISTRY_REPO"
print_kv "Región"       "$REGION"
print_kv "Proyecto"     "$PROJECT_ID"

if gcloud artifacts repositories describe "${ARTIFACT_REGISTRY_REPO}" \
    --location="${REGION}" \
    --project="${PROJECT_ID}" \
    --quiet >/dev/null 2>&1; then
    print_success "Artifact Registry '${ARTIFACT_REGISTRY_REPO}' existe en ${REGION}"
    gcloud artifacts repositories describe "${ARTIFACT_REGISTRY_REPO}" \
        --location="${REGION}" \
        --project="${PROJECT_ID}" \
        --format="table(name, format, location)"
else
    print_warn "Artifact Registry '${ARTIFACT_REGISTRY_REPO}' no encontrado — creando..."
    gcloud artifacts repositories create "${ARTIFACT_REGISTRY_REPO}" \
        --repository-format=docker \
        --location="${REGION}" \
        --description="Docker repository para GitHub Actions" \
        --project="${PROJECT_ID}"
    print_success "Artifact Registry '${ARTIFACT_REGISTRY_REPO}' creado en ${REGION}"
fi

section_end "ARTIFACT_REGISTRY" "Artifact Registry verificado"
pause

# ════════════════════════════════════════════════════════════
#  PASO 6 — HEALTH CHECK
# ════════════════════════════════════════════════════════════
section_start "CHECKER" "Health check final"

check_ok=true

print_info "Verificando Service Account..."
if gcloud iam service-accounts describe "${SA_EMAIL}" \
    --project="${PROJECT_ID}" --quiet >/dev/null 2>&1; then
    print_success "SA ${SA_EMAIL} existe"
else
    print_error "SA ${SA_EMAIL} NO encontrada"
    check_ok=false
fi

print_info "Verificando rol artifactregistry.writer..."
ROLE_CHECK="$(gcloud projects get-iam-policy "${PROJECT_ID}" \
    --flatten="bindings[].members" \
    --format="value(bindings.role)" \
    --filter="bindings.members:${SA_EMAIL} AND bindings.role:artifactregistry.writer" 2>/dev/null || echo "")"
if [[ -n "$ROLE_CHECK" ]]; then
    print_success "Rol roles/artifactregistry.writer asignado"
else
    print_error "Rol roles/artifactregistry.writer NO encontrado"
    check_ok=false
fi

print_info "Verificando binding WIF..."
BINDING_CHECK="$(gcloud iam service-accounts get-iam-policy "${SA_EMAIL}" \
    --project="${PROJECT_ID}" \
    --format="value(bindings.members)" \
    --flatten="bindings[].members" \
    --filter="bindings.members:${GITHUB_ORG}/${GITHUB_REPO}" 2>/dev/null || echo "")"
if [[ -n "$BINDING_CHECK" ]]; then
    print_success "Binding WIF para ${GITHUB_ORG}/${GITHUB_REPO} existe"
else
    print_error "Binding WIF para ${GITHUB_ORG}/${GITHUB_REPO} NO encontrado"
    check_ok=false
fi

echo ""
print_line
if [[ "$check_ok" == true ]]; then
    echo -e "${GREEN}${BOLD}✅ Checker OK — todo operativo${NC}"
else
    echo -e "${RED}${BOLD}✖  Checker detectó errores — revisa los mensajes arriba${NC}"
    exit 1
fi
print_line

section_end "CHECKER" "Health check completado"

# ════════════════════════════════════════════════════════════
#  RESUMEN FINAL
# ════════════════════════════════════════════════════════════
echo ""
print_line
echo -e "${GREEN}${BOLD}Setup completado${NC}"
print_line
echo ""
print_kv "Service Account"    "$SA_EMAIL"
print_kv "Proyecto"           "$PROJECT_ID"
print_kv "WIF Provider"       "$WIF_PROVIDER_FULL"
print_kv "Repo vinculado"     "${GITHUB_ORG}/${GITHUB_REPO}"
print_kv "Artifact Registry"  "${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPO}"
echo ""
echo -e "${DIM}#:[.'.]:>- The Way of the Artisan 🥷${NC}"
echo ""