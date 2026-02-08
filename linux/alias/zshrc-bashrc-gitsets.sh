alias gitsets='git config user.name "put your name here" && \
git config user.email "put your github email here" && \
git config core.sshCommand "ssh -i ~/.ssh/put-private-key -o IdentitiesOnly=yes" && \
git config core.editor "code --wait" && \
git config init.defaultBranch main && \
git config pull.rebase false && \
git config push.default simple && \
git config credential.helper osxkeychain && \
git config core.filemode false'