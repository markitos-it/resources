#:[.'.]:>- ==================================================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-public/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
#:[.'.]:>- ==================================================================================


#:[.'.]:>- ==================================================================================
#:[.'.]:>- grepin - Buscar texto en la salida de un comando o en una cadena
#:[.'.]:>- Uso: grepin <busqueda> [cadena]
#:[.'.]:>- Si se proporciona una cadena, se busca en ella. De lo contrario, se busca en la entrada estándar.
#:[.'.]:>- Ejemplo: ls /etc/ | grepin passwd
#:[.'.]:>- Ejemplo: grepin "error" "Este es un mensaje de error"
#:[.'.]:>- Ejemplo: grepin "syslogd" < /var/log/system.log
#:[.'.]:>- Ejemplo: whoami | grepin "$USER*"
#:[.'.]:>- ==================================================================================
grepin() {
  if [[ $# -lt 1 ]]; then
    echo "Uso: grepin <busqueda> [cadena]"
    return 1
  fi

  local needle="$1"
  if [[ $# -ge 2 ]]; then
    echo "$2" | grep --color=always -i "$needle"
  else
    grep --color=always -i "$needle"
  fi
}