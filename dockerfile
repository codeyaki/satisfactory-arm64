FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG GID=1000
ARG UID=1000
ARG FEX_UID=1001

#FEX 에뮬 관련
ENV CMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake/Qt5

RUN apt-get update && \
    apt-get install -y \
    git \
    cmake \
    ninja-build \
    pkg-config \
    ccache \
    clang \
    llvm \
    lld \
    binfmt-support \
    libsdl2-dev \
    libepoxy-dev \
    libssl-dev \
    python-setuptools \
    g++-x86-64-linux-gnu \
    nasm \
    python3-clang \
    libstdc++-10-dev-i386-cross \
    libstdc++-10-dev-amd64-cross \
    libstdc++-10-dev-arm64-cross \
    squashfs-tools \
    squashfuse \
    libc-bin \
    expect \
    curl \
    sudo \
    fuse \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    qtdeclarative5-dev qml-module-qtquick2 \
    binfmt-support

RUN sudo useradd -u ${FEX_UID} -m -s /bin/bash fex && \
    sudo usermod -aG sudo fex && \
    echo "fex ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/fex

USER fex

WORKDIR /home/fex

RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja .. && \
    ninja

WORKDIR /home/fex/FEX/Build

RUN sudo ninja install && \
    sudo update-binfmts --enable

RUN sudo groupadd -g ${GID} steam && \
    sudo useradd -u ${UID} -g ${GID} -m -s /bin/bash steam && \
    sudo apt-get update && \
    sudo apt-get install -y wget

USER root

RUN echo 'root:steamcmd' | chpasswd

USER steam

WORKDIR /home/steam/.fex-emu/RootFS/

RUN wget -O Ubuntu_22_04.tar.gz https://www.dropbox.com/scl/fi/16mhn3jrwvzapdw50gt20/Ubuntu_22_04.tar.gz?rlkey=4m256iahwtcijkpzcv8abn7nf && \
    tar xzf Ubuntu_22_04.tar.gz && \
    rm ./Ubuntu_22_04.tar.gz

WORKDIR /home/steam/.fex-emu

RUN echo '{"Config":{"RootFS":"Ubuntu_22_04"}}' > ./Config.json

WORKDIR /home/steam/steamcmd

RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    chown -R steam:steam .

RUN FEXInterpreter /home/steam/steamcmd/steamcmd.sh +quit

USER root

WORKDIR ~

#satisfactory 서버 시작
ENV AUTOSAVENUM="5" \
    DEBIAN_FRONTEND="noninteractive" \
    DEBUG="false" \
    DISABLESEASONALEVENTS="false" \
    GAMECONFIGDIR="/config/gamefiles/FactoryGame/Saved" \
    GAMESAVESDIR="/home/steam/.config/Epic/FactoryGame/Saved/SaveGames" \
    LOG="true" \
    MAXOBJECTS="2162688" \
    MAXPLAYERS="4" \
    MAXTICKRATE="30" \
    MULTIHOME="::" \
    PGID="1000" \
    PUID="1000" \
    SERVERGAMEPORT="7777" \
    SERVERMESSAGINGPORT="8888" \
    SERVERSTREAMING="true" \
    SKIPUPDATE="false" \
    STEAMAPPID="1690800" \
    STEAMBETA="false" \
    TIMEOUT="30" \
    VMOVERRIDE="false" \
    STEAMBETA="false" \
    SKIPUPDATE="false"

# hadolint ignore=DL3008
RUN set -x \
 && sudo apt-get update \
 && sudo apt-get install -y gosu xdg-user-dirs curl jq tzdata --no-install-recommends \
 && sudo rm -rf /var/lib/apt/lists/* \
# && sudo groupmod -g ${GID} steam \
# && sudo usermod -u ${UID} steam \
 && sudo mkdir -p /home/steam/.local/share/Steam/ \
 && sudo mkdir -p /tmp/dumps/ \
# && sudo cp -R /root/.local/share/Steam/steamcmd/ /home/steam/.local/share/Steam/steamcmd/ \
# && sudo chown -R ${UID}:${GID} /home/steam/.local/ \
 && gosu nobody true

RUN sudo mkdir -p /config \
 && sudo chown steam:steam /config

COPY ./scripts/init.sh /
COPY --chown=steam:steam ./scripts/healthcheck.sh ./scripts/run.sh /home/steam/

RUN sudo chmod +x /init.sh /home/steam/healthcheck.sh /home/steam/run.sh

HEALTHCHECK --timeout=30s --start-period=300s CMD bash /home/steam/healthcheck.sh

WORKDIR /config
ARG VERSION="DEV"
ENV VERSION=$VERSION
LABEL version=$VERSION
STOPSIGNAL SIGINT
EXPOSE 7777/udp 7777/tcp 8888/tcp

ENTRYPOINT ["/init.sh" ]
