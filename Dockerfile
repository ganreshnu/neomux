FROM fedora:latest AS base
RUN dnf -yq update && dnf -yq install git

#
# neovim build image
#
FROM base AS build
RUN dnf -yq group install "C Development Tools and Libraries"

RUN git clone --depth=1 https://github.com/neovim/neovim.git

RUN dnf -yq install cmake unzip gettext

ARG VERSION=master
RUN cd neovim && git checkout ${VERSION} && make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=/install install


#
# final image
#
FROM base
RUN dnf -yq install dnf-plugins-core && \
	dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
RUN dnf -yq install docker-ce-cli tmux zsh openssh-clients less which procps-ng \
	ripgrep fd-find \
	python3 python3-pip nodejs
RUN dnf -yq remove vim-minimal

COPY xdgenv.sh /etc/profile.d/xdgenv.sh
COPY editor.sh /etc/profile.d/editor.sh

COPY --from=build /install /usr/local
RUN ln -s /usr/local/bin/nvim /usr/bin/vi \
	&& ln -s /usr/local/bin/nvim /usr/bin/ex \
	&& ln -s /usr/local/bin/nvim /usr/bin/view \
	&& ln -s /usr/local/bin/nvim /usr/bin/vim \
	&& ln -s /usr/local/bin/nvim /usr/bin/vimdiff \
	&& ln -s /usr/local/bin/nvim /usr/bin/editor

# add the primary user
RUN mkdir /tmp/skel && useradd --shell /bin/zsh --create-home --skel /tmp/skel neomux && rmdir /tmp/skel
RUN echo 'neomux ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/neomux
RUN touch /var/run/docker.sock && chown root:neomux /var/run/docker.sock

RUN npm install -g neovim
RUN pip3 install --upgrade pynvim

COPY entry.sh /usr/local/bin/entry.sh

# install the user configuration
USER neomux
RUN source /etc/profile.d/xdgenv.sh && \
	git clone https://github.com/ganreshnu/config-zsh.git ${XDG_CONFIG_HOME}/zsh && \
	git clone https://github.com/ganreshnu/config-tmux.git ${XDG_CONFIG_HOME}/tmux && \
	git clone https://github.com/ganreshnu/config-openssh.git ${HOME}/.ssh && \
	chmod go-rwx ${HOME}/.ssh && \
	git clone https://github.com/ganreshnu/config-gnupg.git ${XDG_CONFIG_HOME}/gnupg && \
	chmod go-rwx ${XDG_CONFIG_HOME}/gnupg && \
	git clone https://github.com/ganreshnu/config-nvim.git ${XDG_CONFIG_HOME}/nvim && \
	git clone https://github.com/wbthomason/packer.nvim.git ${XDG_DATA_HOME}/nvim/site/pack/packer/start/packer.nvim

WORKDIR /home/neomux
ENTRYPOINT [ "/usr/local/bin/entry.sh" ]
CMD [ "tmux", "-f", "${XDG_CONFIG_HOME}/tmux/tmux.conf" ]

