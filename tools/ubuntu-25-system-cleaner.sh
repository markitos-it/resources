#!/usr/bin/env bash
set -euo pipefail

# ubuntu-25-system-cleaner.sh - Script para limpiar y optimizar sistemas Ubuntu 25
#:[.'.]:>- ==================================================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
#:[.'.]:>- ==================================================================================

echo ""
echo ""
echo "🧹 Iniciando limpieza quirúrgica..."
echo "🔍 Eliminando paquetes huérfanos de Go..."
go clean -modcache -cache
echo "🔍 Eliminando paquetes huérfanos de Snap..."
snap list --all | awk '/desactivado/{print $1, $3}' | while read -r snapname rev; do sudo snap remove "$snapname" --revision="$rev"; done
echo "🔍 Limpiando caché y logs..."
rm -rf ~/.cache/thumbnails/*
sudo journalctl --vacuum-time=3d
echo "🔍 Limpiando caché de Code..."
rm -rf ~/.config/Code/CachedData/*
echo "🔍 Limpiando caché de Google Chrome..."
rm -rf ~/.config/google-chrome/Default/Cache/*
rm -rf ~/.config/google-chrome/ShaderCache/*


echo "🔍 Limpiando paquetes huérfanos de APT..."
sudo apt autoremove --purge -y
echo "🔍 Limpiando caché de APT..."
sudo apt autoclean

echo ""
echo "✅ Teseo está optimizado."
echo ""
echo ""
