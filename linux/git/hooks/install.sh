#!/bin/bash

#:[.'.]:>- ===================================================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- markitos.es.info@gmail.com
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
#:[.'.]:>- ===================================================================================

#:[.'.]:>- Descripción:
#:[.'.]:>- Este script se encarga de instalar y configurar los Git Hooks para el proyecto Markitos-it,
#:[.'.]:>- utilizando un archivo de configuración YAML específico.
#:[.'.]:>- Asegura que pre-commit esté instalado y luego instala los hooks definidos en config.yaml.

#:[.'.]:>- Uso:
#:[.'.]:>- 1. Coloca este script en la carpeta .git/hooks de tu repositorio.
#:[.'.]:>- 2. Asegúrate de que config.yaml esté en la misma carpeta que este script.
#:[.'.]:>- 3. Ejecuta el script para instalar los hooks: `bash install.sh`

#:[.'.]:>- Variables de color para mensajes en terminal.
GREEN='\033[0;32m'
NC='\033[0m'

#:[.'.]:>- Paso 0: Espacio inicial, aviso y confirmacion del usuario.
echo
echo
echo -e "${GREEN}🔧 Este script hara lo siguiente:${NC}"
echo "  - Verificar si pre-commit esta instalado."
echo "  - Instalar pre-commit via apt si no existe."
echo "  - Instalar los Git Hooks usando config.yaml."
echo
read -r -p "Deseas continuar? (Yes/No): " CONFIRM
case "$CONFIRM" in
    y|Y|yes|YES|Yes)
        echo -e "${GREEN}✅ Continuando...${NC}"
        ;;
    *)
        echo "Cancelado por el usuario."
        exit 0
        ;;
esac

#:[.'.]:>- Paso 1: Mensaje inicial para indicar preparación de hooks.
echo -e "${GREEN}🔧 Configurando entorno de Git Hooks para Markitos-it...${NC}"

#:[.'.]:>- Paso 2: Resolver ruta absoluta del script para ubicar config.yaml.
#:[.'.]:>- Opciones:
#:[.'.]:>- - readlink -f: canonicaliza ruta en Linux.
#:[.'.]:>- - alternativa portable: usar pwd + dirname.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CONFIG_FILE="$SCRIPT_DIR/config.yaml"

#:[.'.]:>- Paso 3: Verificar si pre-commit está instalado.
#:[.'.]:>- command -v devuelve no-cero si no existe el binario.
if ! command -v pre-commit &> /dev/null; then
    #:[.'.]:>- Paso 3.1: Instalación automática vía apt.
    #:[.'.]:>- Opciones:
    #:[.'.]:>- - pipx install pre-commit (recomendado en algunos entornos).
    #:[.'.]:>- - pip install --user pre-commit.
    echo "📦 Instalando pre-commit vía apt..."
    sudo apt update && sudo apt install pre-commit -y
fi

#:[.'.]:>- Paso 4: Instalar hooks de pre-commit usando config explícita.
#:[.'.]:>- Opciones útiles:
#:[.'.]:>- - pre-commit install --hook-type pre-push
#:[.'.]:>- - pre-commit install --install-hooks (descarga hooks al instalar)
#:[.'.]:>- - pre-commit run --all-files (ejecución manual completa)
pre-commit install --config "$CONFIG_FILE"

#:[.'.]:>- Paso 5: Confirmación final de instalación.
echo -e "${GREEN}✅ Hooks instalados correctamente usando $CONFIG_FILE${NC}"
echo
#:[.'.]:>- Fin del script.
