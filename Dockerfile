# Latest stable version of Ubuntu, of course
FROM ubuntu:22.04

LABEL org.opencontainers.image.authors "Jasper Smit <git@jrhrsmit.nl>"
LABEL org.opencontainers.image.description "Kicad 7 and KiRI"
LABEL org.opencontainers.image.url "https://hub.docker.com/r/jrhrsmit/kiri/main"
LABEL org.opencontainers.image.documentation "https://github.com/jrhrsmit/kiri-docker"

ARG DEBIAN_FRONTEND noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG TERM 'dumb'

RUN apt-get update && \
	apt-get install -y \
	sudo \
	git \
	zsh \
	curl \
	coreutils \
	software-properties-common \
	x11-utils \
	x11-xkb-utils \
	xvfb \
	opam \
	build-essential \
	pkg-config \
	libgmp-dev \
	util-linux \
	python-is-python3 \
	python3-pip \
	dos2unix \
	librsvg2-bin \
	imagemagick \
	xdotool \
	rename \
	bc \
	bsdmainutils

# Install latest Kicad
RUN add-apt-repository -y ppa:kicad/kicad-7.0-releases && \
	apt-get update && \
	apt-get install --install-recommends -y kicad

# install dependencies for Mayo
RUN apt-get update  && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
	libocct-data-exchange-dev \
	libocct-draw-dev \
	qtbase5-dev \
	libqt5svg5-dev

# Create user
RUN useradd -rm -d "/home/kiri" -s "/usr/bin/zsh" -g root -G sudo -u 1000 kiri -p kiri

# Run sudo without password
RUN echo "kiri ALL=(ALL) NOPASSWD:ALL" | tee sudo -a "/etc/sudoers"

# Change current user
USER kiri
WORKDIR "/home/kiri"
ENV USER kiri
ENV DISPLAY :0

ENV PATH "${PATH}:/home/kiri/.local/bin"

# Python dependencies
RUN yes | pip3 install \
	"pillow>8.2.0" \
	"six>=1.15.0" \
	"python_dateutil>=2.8.1" \
	"pytz>=2021.1" \
	"typer" \
	"rich" \
	"gitpython" \
	"pathlib>=1.0.1" && \
	pip3 cache purge

# Opam dependencies
RUN yes | opam init --disable-sandboxing && \
	opam switch create 4.10.2 && \
	eval "$(opam env)" && \
	opam update && \
	opam install -y \
	digestif \
	lwt \
	lwt_ppx \
	cmdliner \
	base64 \
	sha \
	tyxml \
	git-unix && \
	opam clean -a -c -s --logs -r && \
	rm -rf ~/.opam/download-cache && \
	rm -rf ~/.opam/repo/*

# Oh-my-zsh, please
RUN zsh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true

# Install Mayo
ENV MAYO_HOME "/home/kiri/.local/share/mayo"
RUN git clone https://github.com/fougue/mayo.git "${MAYO_HOME}" && \
	mkdir ${MAYO_HOME}/mayo-build && \
	cd ${MAYO_HOME}/mayo-build && \
	CASCADE_INC_DIR=`dpkg -L libocct-foundation-dev | grep -i "Standard_Version.hxx" | sed "s/\/Standard_Version.hxx//i"` && \
	CASCADE_LIB_DIR=`dpkg -L libocct-foundation-dev | grep -i "libTKernel.so" | sed "s/\/libTKernel.so//i"` && \
	qmake ${MAYO_HOME} CASCADE_INC_DIR=$CASCADE_INC_DIR CASCADE_LIB_DIR=$CASCADE_LIB_DIR && \
	make -j8 && \
 	ln -s ${MAYO_HOME}/mayo-build/mayo ~/.local/bin

# Install kiri, kidiff and plotgitsch
ARG BUILD_DATE=unknown
ADD https://api.github.com/repos/jrhrsmit/kiri/git/refs/heads/main kiri_version.json
ENV KIRI_HOME "/home/kiri/.local/share/"
RUN git clone --recurse-submodules -j8 https://github.com/jrhrsmit/kiri.git "${KIRI_HOME}/kiri"
RUN cd "${KIRI_HOME}/kiri/submodules/plotkicadsch" && \
	opam pin add -y kicadsch . && \
	opam pin add -y plotkicadsch . && \
	opam install -y plotkicadsch && \
	opam clean -a -c -s --logs -r && \
	rm -rf ~/.opam/download-cache && \
	rm -rf ~/.opam/repo/*

# Opam configuration
RUN echo | tee -a "${HOME}/.zshrc"
RUN echo '# OPAM configuration' | tee -a "${HOME}/.zshrc"
RUN echo "test -r /home/kiri/.opam/opam-init/init.sh && . /home/kiri/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true" | tee -a "${HOME}/.zshrc"

# KiRI environment
RUN echo | tee -a "${HOME}/.zshrc"
RUN echo '# KIRI Environment' | tee -a "${HOME}/.zshrc"
RUN echo 'export KIRI_HOME=${HOME}/.local/share/kiri' | tee -a "${HOME}/.zshrc"
RUN echo 'export PATH=${KIRI_HOME}/submodules/KiCad-Diff/bin:${PATH}' | tee -a "${HOME}/.zshrc"
RUN echo 'export PATH=${KIRI_HOME}/bin:${PATH}' | tee -a "${HOME}/.zshrc"

# Custom commands
RUN echo | tee -a "${HOME}/.zshrc"
RUN echo '# Custom Commands' | tee -a "${HOME}/.zshrc"
RUN echo 'function ip() { awk "/32 host/ { print f } {f= \$2}" /proc/net/fib_trie | sort | uniq | grep -v 127.0.0.1 | head -n1 }' | tee -a "${HOME}/.zshrc"
RUN echo 'alias kiri="kiri -i \$(ip)"' | tee -a "${HOME}/.zshrc"

# Clean unnecessary stuff
RUN sudo apt-get purge -y \
	curl \
	opam \
	build-essential \
	software-properties-common \
	pkg-config \
	libgmp-dev
RUN sudo apt-get -y autoremove && \
	sudo apt-get clean
RUN sudo rm -rf \
	/tmp/* \
	/var/tmp/* \
	/var/lib/apt/lists/*; \
	/usr/share/doc/* \
	/usr/share/info/* \
	/usr/share/man/* || true

# Initialize Kicad config files to skip default popups of setup
COPY config "/home/kiri/.config"
RUN sudo chown -R kiri "/home/kiri/.config"
