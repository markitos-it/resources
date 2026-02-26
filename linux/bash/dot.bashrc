#:[.'.]:>-==================================================================================
#:[.'.]:>- Configuración personalizada de Git
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
#:[.'.]:>- Alias personalizados para Git y navegación
#:[.'.]:>-==================================================================================
alias ggs="git status"
alias ggp="git pull"
alias ggcm="git commit -m "

alias ccdd="cd && cd development"
alias ccdg="cd && cd development/github/"
alias ccdr="cd && cd development/github/markitos-it/resources"
#:[.'.]:>-==================================================================================

#:[.'.]:>-==================================================================================
#:[.'.]:>- Cargar funciones bash personalizadas
#:[.'.]:>-==================================================================================
if [ -f "$HOME/.bash_functions" ]; then
    . "$HOME/.bash_functions"
fi
#:[.'.]:>-==================================================================================
