#!/bin/bash
#:[.'.]:>- =============================================================================
#:[.'.]:>- AUTOR: Markitos IT - https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- CONTACTO: markitos.es.info@gmai.com
#:[.'.]:>- FECHA: Enero 2026
#:[.'.]:>- DESCRIPCIÓN: Script para configurar Service Account y Workload Identity
#:[.'.]:>- Script para configurar Service Account y Workload Identity Federation
#:[.'.]:>- para publicar imágenes Docker desde GitHub Actions a GCP Artifact Registry
#:[.'.]:>- Federation para publicar imágenes Docker desde GitHub Actions
#:[.'.]:>- =============================================================================

#:[.'.]:>- =============================================================================
#:[.'.]:>- ¿POR QUÉ WORKLOAD IDENTITY FEDERATION?
#:[.'.]:>- =============================================================================
#:[.'.]:>- Tradicionalmente, para conectar GitHub Actions con GCP necesitarías:
#:[.'.]:>- 1. Crear una clave JSON del service account
#:[.'.]:>- 2. Guardarla como secret en GitHub
#:[.'.]:>- 3. GitHub la usa para autenticarse
#
#:[.'.]:>- PROBLEMAS de este enfoque:
#:[.'.]:>- - Las claves JSON son credenciales de larga duración (no expiran automáticamente)
#:[.'.]:>- - Si la clave se filtra, alguien puede usarla indefinidamente
#:[.'.]:>- - Hay que rotarlas manualmente periódicamente
#:[.'.]:>- - Se almacenan como texto plano en los secrets de GitHub
#
#:[.'.]:>- SOLUCIÓN: Workload Identity Federation
#:[.'.]:>- - NO requiere claves JSON
#:[.'.]:>- - GitHub genera tokens temporales (duran minutos, no años)
#:[.'.]:>- - Si se filtra un token, expira automáticamente muy pronto
#:[.'.]:>- - La autenticación se basa en la identidad del repositorio de GitHub
#:[.'.]:>- - Google verifica que el token viene realmente de GitHub
#:[.'.]:>- - Más seguro y sin mantenimiento de claves
#
#:[.'.]:>- CONCEPTOS CLAVE:
#:[.'.]:>- - WORKLOAD_POOL: Un "grupo" donde viven las identidades externas (GitHub, GitLab, etc)
#:[.'.]:>- - WORKLOAD_PROVIDER: Configuración específica del proveedor (en este caso GitHub OIDC)
#:[.'.]:>- - SERVICE_ACCOUNT: La cuenta de GCP que tendrá permisos para publicar imágenes
#:[.'.]:>- - OIDC: Estándar de autenticación que GitHub y GCP usan para intercambiar tokens
#
#:[.'.]:>- SEGURIDAD:
#:[.'.]:>- - En DESARROLLO: Actualmente usando valores hardcodeados en el script
#:[.'.]:>-   para facilitar el setup inicial y pruebas rápidas
#:[.'.]:>- - En PRODUCCIÓN: Estos valores deberían venir de:
#:[.'.]:>-   * Variables de entorno (export VAR=value antes de ejecutar)
#:[.'.]:>-   * Archivo de configuración externo (.env no versionado en git)
#:[.'.]:>-   * Secret Manager de GCP (gcloud secrets versions access)
#:[.'.]:>-   * Parámetros de entrada al script (./script.sh --project=X --repo=Y)
#:[.'.]:>- - NUNCA commitear credenciales reales en el repositorio
#:[.'.]:>- - Usar .gitignore para excluir archivos con datos sensibles como un local.env y en produccion se genera el production.env por ejemplo
#
#:[.'.]:>- =============================================================================

#:[.'.]:>- =============================================================================
#:[.'.]:>- VARIABLES DE CONFIGURACIÓN - CAMBIA ESTOS VALORES SEGÚN TU PROYECTO
#
#:[.'.]:>- - PROJECT_ID: ID del proyecto de GCP donde está Artifact Registry
#:[.'.]:>- - REGION: Región donde está ubicado el repositorio de Artifact Registry
#:[.'.]:>- - REPOSITORY: Nombre del repositorio de Artifact Registry (debe existir previamente)
#:[.'.]:>- - SERVICE_ACCOUNT_NAME: Nombre para la nueva cuenta de servicio
#:[.'.]:>- - WORKLOAD_POOL_NAME: Nombre para el Workload Identity Pool
#:[.'.]:>- - WORKLOAD_PROVIDER_NAME: Nombre para el Workload Identity Provider
#:[.'.]:>- - GITHUB_ORG: Organización o usuario de GitHub donde está el repositorio
#:[.'.]:>- - GITHUB_REPO: Nombre del repositorio de GitHub donde están los workflows
#:[.'.]:>- =============================================================================
PROJECT_ID="put-your-project-id-here" # ej: markitos-it-labs-course-basic
REGION="put-your-artifact-registry-region-here" # ej: us-central1
REPOSITORY="put-your-artifact-registry-repo-here" # ej: private
SERVICE_ACCOUNT_NAME="put-your-service-account-name-here" # ej: gh-publisher
WORKLOAD_POOL_NAME="put-your-workload-pool-name-here" # ej: gh-pool
WORKLOAD_PROVIDER_NAME="put-your-workload-provider-name-here" # ej: gh-provider
GITHUB_ORG="put-your-github-org-here" # ej: markitos-it
GITHUB_REPO="put-your-github-repo-here" # ej: markitos-it-app-website

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 1: CREAR SERVICE ACCOUNT
#:[.'.]:>- =============================================================================
#:[.'.]:>- Crea una cuenta de servicio dedicada para que GitHub Actions publique imágenes
#:[.'.]:>- Esta cuenta tendrá permisos limitados solo para escribir en Artifact Registry
echo "Creando service account..."
gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
  --project=${PROJECT_ID} \
  --display-name="GitHub Actions Publisher" \
  --description="Service account para publicar imágenes Docker desde GitHub Actions"

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 2: ASIGNAR PERMISOS AL SERVICE ACCOUNT
#:[.'.]:>- =============================================================================
#:[.'.]:>- Otorga el rol "Artifact Registry Writer" al service account
#:[.'.]:>- Este rol permite subir imágenes Docker al repositorio de Artifact Registry
echo "Asignando rol de Artifact Registry Writer..."
gcloud artifacts repositories add-iam-policy-binding ${REPOSITORY} \
  --location=${REGION} \
  --project=${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 3: CREAR WORKLOAD IDENTITY POOL
#:[.'.]:>- =============================================================================
#:[.'.]:>- Crea un "pool" de identidades para conectar servicios externos (GitHub)
#:[.'.]:>- Workload Identity Federation permite autenticación sin claves JSON
echo "Creando Workload Identity Pool..."
gcloud iam workload-identity-pools create ${WORKLOAD_POOL_NAME} \
  --project=${PROJECT_ID} \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  --description="Pool para autenticar GitHub Actions workflows"

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 4: CREAR WORKLOAD IDENTITY PROVIDER (OIDC)
#:[.'.]:>- =============================================================================
#:[.'.]:>- Configura GitHub como proveedor de identidad usando OIDC
#:[.'.]:>- - issuer-uri: Endpoint de GitHub para tokens OIDC
#:[.'.]:>- - attribute-mapping: Mapea claims del token JWT a atributos de GCP
#:[.'.]:>- - attribute-condition: Solo permite repos del propietario especificado
echo "Creando Workload Identity Provider para GitHub..."
gcloud iam workload-identity-pools providers create-oidc ${WORKLOAD_PROVIDER_NAME} \
  --project=${PROJECT_ID} \
  --location="global" \
  --workload-identity-pool=${WORKLOAD_POOL_NAME} \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner=='${GITHUB_ORG}'"

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 5: OBTENER PROJECT NUMBER (necesario para el siguiente paso)
#:[.'.]:>- =============================================================================
#:[.'.]:>- El PROJECT_NUMBER es diferente del PROJECT_ID y se necesita para el binding
echo "Obteniendo Project Number..."
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
echo "Project Number: ${PROJECT_NUMBER}"

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 6: PERMITIR QUE EL POOL IMPERSONE AL SERVICE ACCOUNT
#:[.'.]:>- =============================================================================
#:[.'.]:>- Autoriza al Workload Identity Pool a actuar como el service account
#:[.'.]:>- Solo los workflows del repositorio específico podrán usar esta cuenta
echo "Configurando binding entre Workload Identity y Service Account..."
gcloud iam service-accounts add-iam-policy-binding \
  ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID} \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_POOL_NAME}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 7: OBTENER LOS VALORES PARA GITHUB SECRETS
#:[.'.]:>- =============================================================================
echo ""
echo "============================================================================="
echo "CONFIGURACIÓN COMPLETADA"
echo "============================================================================="
echo ""
echo "Ahora configura estos SECRETS en GitHub:"
echo ""
echo "1. WIF_PROVIDER:"
echo "   projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_POOL_NAME}/providers/${WORKLOAD_PROVIDER_NAME}"
echo ""
echo "2. WIF_SERVICE_ACCOUNT:"
echo "   ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo ""
echo "============================================================================="
echo ""

#:[.'.]:>- =============================================================================
#:[.'.]:>- PASO 7: OBTENER LOS VALORES PARA GITHUB SECRETS
#:[.'.]:>- =============================================================================
echo ""
echo "============================================================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "============================================================================="
echo ""
echo "📋 Configura estos SECRETS en tu repositorio de GitHub:"
echo "   ${GITHUB_ORG}/${GITHUB_REPO}"
echo ""
echo "   Settings > Secrets and variables > Actions > New repository secret"
echo ""
echo "-----------------------------------------------------------------------------"
echo "Secret 1:"
echo "-----------------------------------------------------------------------------"
echo "Nombre: WIF_PROVIDER"
echo ""
echo "Valor (copia esto):"
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_POOL_NAME}/providers/${WORKLOAD_PROVIDER_NAME}"
echo ""
echo "-----------------------------------------------------------------------------"
echo "Secret 2:"
echo "-----------------------------------------------------------------------------"
echo "Nombre: WIF_SERVICE_ACCOUNT"
echo ""
echo "Valor (copia esto):"
echo "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo ""
echo "-----------------------------------------------------------------------------"
echo "Secret 3 (ruta completa del registry):"
echo "-----------------------------------------------------------------------------"
echo "Nombre: GAR_REGISTRY"
echo ""
echo "Valor (copia esto):"
echo "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}"
echo ""
echo "============================================================================="
echo ""


#:[.'.]:>- =============================================================================
#:[.'.]:>- CONFIGURACIÓN EN GITHUB
#:[.'.]:>- =============================================================================
#:[.'.]:>- Para completar la configuración, debes agregar estos secretos en GitHub:
#
#:[.'.]:>- 1. Ve a tu repositorio en GitHub
#:[.'.]:>- 2. Settings > Secrets and variables > Actions
#:[.'.]:>- 3. Click en "New repository secret"
#:[.'.]:>- 4. Agrega los siguientes secretos:
#
#:[.'.]:>-    Nombre: WIF_PROVIDER
#:[.'.]:>-    Valor: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/<put-your-workload-pool-name-here>/providers/<put-your-workload-provider-name-here>
#
#:[.'.]:>-    Nombre: WIF_SERVICE_ACCOUNT
#:[.'.]:>-    Valor: <put-your-service-account-name-here>@<put-your-project-id-here>.iam.gserviceaccount.com
#
#:[.'.]:>- Estos secretos son usados en el workflow publish-image.yaml para autenticarse
#:[.'.]:>- con GCP sin necesidad de claves JSON, usando Workload Identity Federation
#:[.'.]:>- =============================================================================