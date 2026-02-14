#!/usr/bin/env bash
#:[.'.]:>- ==================================================================================
#:[.'.]:>- Marco Antonio - markitos devsecops kulture
#:[.'.]:>- The Way of the Artisan
#:[.'.]:>- markitos.es.info@gmail.com
#:[.'.]:>- 🌍 https://github.com/orgs/markitos-it/repositories
#:[.'.]:>- 📺 https://www.youtube.com/@markitos_devsecops
#:[.'.]:>- ==================================================================================


#:[.'.]:>-==================================================================================
#:[.'.]:>- Alias para configurar git con un solo comando. Personaliza los valores antes de usarlo.
#:[.'.]:>- Asegúrate de reemplazar "put your name here", "put your github email here", y "put-private-key" con tus datos reales.
#:[.'.]:>- Inserta este alias en tu .zshrc o .bashrc para usarlo en tu terminal.
#:[.'.]:>-==================================================================================
alias gitsets='git config user.name "put your name here" && \
git config user.email "put your github email here" && \
git config core.sshCommand "ssh -i ~/.ssh/put-private-key -o IdentitiesOnly=yes" && \
git config core.editor "code --wait" && \
git config init.defaultBranch main && \
git config pull.rebase false && \
git config push.default simple && \
git config credential.helper osxkeychain && \
git config pull.rebase false && \
git config core.filemode false'
#:[.'.]:>-==================================================================================
