#:[.'.]:>-==================================================================================
#:[.'.]:>- Funciones bash personalizadas
#:[.'.]:>-==================================================================================

#:[.'.]:>-==================================================================================
#:[.'.]:>- Función ggwork: Automatiza el flujo de trabajo de Git con una pausa de seguridad.
#:[.'.]:>- Uso:
#:[.'.]:>-   ggwork "Mensaje de commit"
#:[.'.]:>- Características:
#:[.'.]:>-   - Verifica que se proporcione un mensaje de commit.
#:[.'.]:>-   - Muestra el estado inicial del repositorio.
#:[.'.]:>-   - Pausa de 5 segundos para permitir cancelación.
#:[.'.]:>-   - Agrega todos los cambios, hace commit y push al remoto.
#:[.'.]:>-   - Muestra el estado final del repositorio.
#:[.'.]:>-==================================================================================
function ggwork() {
    local message="${1:-}"
    local prefix="[GGWORK]"

    if [ -z "$message" ]; then
        printf "%s [ERROR] Debes proporcionar un mensaje para el commit.\n" "$prefix"
        printf "%s [INFO]  Uso: ggwork 'mi mensaje de commit'\n" "$prefix"
        return 1
    fi

    printf "%s [INFO]  Status inicial\n" "$prefix"
    git status

    printf "%s [INFO]  Pausa de seguridad antes del proceso\n" "$prefix"
    printf "%s [INFO]  Esperando 5 segundos. Presiona Ctrl+C para cancelar\n" "$prefix"
    sleep 5

    printf "%s [INFO]  Agregando cambios\n" "$prefix"
    git add .

    printf "%s [INFO]  Commit\n" "$prefix"
    git commit -m "$message"

    printf "%s [INFO]  Push al remoto\n" "$prefix"
    git push

    printf "%s [INFO]  Status final\n" "$prefix"
    git status

    printf "%s [OK]    Despliegue finalizado con exito\n" "$prefix"
}
#:[.'.]:>==================================================================================
