#:[.'.]:>-==================================================================================
#:[.'.]:>- Alias para configurar git con un solo comando. Personaliza los valores antes de usarlo.
#:[.'.]:>- Asegúrate de reemplazar "put your name here", "put your github email here", y "github" con tus datos reales.
#:[.'.]:>- Inserta este alias en tu .zshrc o .bashrc para usarlo en tu terminal.
#:[.'.]:>-==================================================================================
alias gitsets='git config user.name "Marco Antonio - The Way of the Artisan" && \
git config user.email "markitos.es.info@gmail.com" && \
git config core.sshCommand "ssh -i ~/.ssh/github -o IdentitiesOnly=yes" && \
git config core.editor "code --wait" && \
git config init.defaultBranch main && \
git config pull.rebase false && \
git config push.default simple && \
git config credential.helper osxkeychain && \
git config pull.rebase false && \
git config core.filemode false'
#:[.'.]:>-==================================================================================

#:[.'.]:>-==================================================================================
#:[.'.]:>- Alias para comandos comunes de git y navegación rápida en el sistema de archivos
#:[.'.]:>- Personaliza las rutas en los alias de navegación según tu estructura de directorios.
#:[.'.]:>- Inserta estos alias en tu .zshrc o .bashrc para usarlos en tu terminal.
#:[.'.]:>-==================================================================================
alias ggs="git status"
alias ggp="git pull"
alias ccdd="cd && cd development"
alias ccdg="cd && cd development/github/"
alias ccdr="cd && cd development/github/markitos-it/resources"
#:[.'.]:>-==================================================================================


#:[.'.]:>-==================================================================================
#:[.'.]:>- Alias para automatizar el proceso de agregar, commitear y pushear cambios a git con un solo comando.
#:[.'.]:>- Personaliza el mensaje de commit al usar el alias.
#:[.'.]:>- Inserta este alias en tu .zshrc o .bashrc para usarlo en tu terminal.
#:[.'.]:>-==================================================================================
ggwork() {
    local message="$1"

    # Si no pasas mensaje, te lo pide para no fallar
    if [ -z "$message" ]; then
        printf "❌ Error: Debes proporcionar un mensaje para el commit.\n"
        printf "Uso: ggwork 'mi mensaje de commit'\n"
        return 1
    fi

    printf "${GREEN}#:[.'.]:>- [ STATUS INICIAL ]${NC}\n"
    git status

    printf "\n#:[.'.]:>- ⏳ Pausa de seguridad (5s) antes del proceso...\n"
    printf "#:[.'.]:>- ⏳ Esperando... Presiona CTRL+C para cancelar.\n"
    sleep 5

    printf "\n#:[.'.]:>- [ AGREGANDO CAMBIOS ]\n"
    git add .

    printf "\n#:[.'.]:>- [ COMMITTING ]\n"
    git commit -m "$message"

    printf "\n#:[.'.]:>- [ PUSHING TO REMOTE ]\n"
    git push

    printf "\n#:[.'.]:>- [ STATUS FINAL ]\n"
    git status

    printf "\n#:[.'.]:>- ✅ Despliegue finalizado con éxito.\n\n"
}
#:[.'.]:>-==================================================================================
