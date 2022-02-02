#!/bin/bash
. /etc/profile.d/xdgenv.sh

for i in ${XDG_CONFIG_HOME}/*; do
	git -C $i pull --quiet
done
git -C ${HOME}/.ssh pull --quiet

exec bash -lc "exec $@"
