FROM fedora:latest AS base
RUN dnf -yq update

#
# neovim build image
#
FROM base AS build
RUN dnf -yq group install "C Development Tools and Libraries"
RUN dnf -yq install git

RUN git clone --depth=1 https://github.com/neovim/neovim.git

RUN dnf -yq install cmake unzip gettext

ARG VERSION=master
RUN cd neovim && git checkout ${VERSION} && make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=/install install


#
# final image
#
FROM base
RUN dnf -yq install less which tmux openssh-clients git dnf-plugins-core
RUN dnf -yq remove vim-minimal
RUN dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
RUN dnf -yq install docker-ce-cli
RUN dnf -yq install ripgrep fd-find
RUN dnf -yq install python3 python3-pip ruby-devel nodejs

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
RUN useradd neomux
RUN echo 'neomux ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/neomux
RUN touch /var/run/docker.sock && chown root:neomux /var/run/docker.sock

RUN npm install -g neovim

# install the user configuration
USER neomux
RUN source /etc/profile.d/xdgenv.sh && \
	git clone https://github.com/ganreshnu/config-tmux.git ${XDG_CONFIG_HOME}/tmux && \
	git clone https://github.com/ganreshnu/config-nvim.git ${XDG_CONFIG_HOME}/nvim && \
	git clone https://github.com/ganreshnu/config-openssh.git ${HOME}/.ssh && \
	git clone https://github.com/ganreshnu/config-gnupg.git ${XDG_CONFIG_HOME}/gnupg && \
	git clone https://github.com/wbthomason/packer.nvim.git ${XDG_DATA_HOME}/nvim/site/pack/packer/start/packer.nvim

RUN source /etc/profile.d/xdgenv.sh && \
	chmod go-rwx ${XDG_CONFIG_HOME}/gnupg
RUN pip3 install --user --upgrade pynvim

WORKDIR /home/neomux
CMD [ "sh", "-lc", "exec tmux -f ${XDG_CONFIG_HOME}/tmux/tmux.conf" ]
