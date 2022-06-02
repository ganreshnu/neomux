#!/bin/bash
. /etc/profile.d/xdgenv.sh

for i in ${XDG_CONFIG_HOME}/*; do
	git -C $i pull --quiet
done
git -C ${HOME}/.ssh pull --quiet

nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

exec bash -lc "exec $@"
#exec tmux -f ${XDG_CONFIG_HOME}/tmux/tmux.conf

