#!/bin/bash -i
. /etc/profile.d/xdgenv.sh

for i in ${XDG_CONFIG_HOME}/*; do
	git -C $i pull --quiet
done
git -C ${HOME}/.ssh pull --quiet

nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

if [[ $1 == 'powershell-alias' ]]; then
	cat "/usr/share/profile.ps1"
	exit
fi

exec $@

