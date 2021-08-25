FROM debian:stable-slim as builder-openssl
SHELL ["/usr/bin/env", "bash", "-euo", "pipefail", "-c"]


ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
       git \
    && rm -rf /var/lib/apt/lists/*

ARG TLSTYPE=openssl
ARG SSLPKG=libssl-dev
RUN echo "deb http://deb.debian.org/debian $(dpkg --status tzdata|grep Provides|cut -f2 -d'-')-backports main contrib" > /etc/apt/sources.list.d/backports.list
RUN DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io update
RUN DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io install "${SSLPKG}" build-essential gnulib git bzip2 bash rsync gcc zlib1g-dev autoconf flex make automake gettext libidn11 autopoint texinfo gperf ca-certificates wget pkg-config libpsl-dev libidn2-dev lua5.1-dev
RUN DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io -t "$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')-backports" install libzstd-dev zstd

# Setup patched wget with lua support
WORKDIR /tmp/workdir

COPY wget-lua wget-lua
COPY .git/modules/wget-lua .git/modules/wget-lua
WORKDIR /tmp/workdir/wget-lua
RUN ./bootstrap
RUN ./configure --with-ssl="${TLSTYPE}" -disable-nls
RUN make -j "$(nproc)"
RUN src/wget -V | grep -q lua

FROM debian:stable-slim as builder-gnutls
SHELL ["/usr/bin/env", "bash", "-euo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
       git \
    && rm -rf /var/lib/apt/lists/*

ARG TLSTYPE=gnutls
ARG SSLPKG=gnutls-dev
RUN echo "deb http://deb.debian.org/debian $(dpkg --status tzdata|grep Provides|cut -f2 -d'-')-backports main contrib" > /etc/apt/sources.list.d/backports.list
RUN DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io update
RUN DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io install "${SSLPKG}" build-essential gnulib git bzip2 bash rsync gcc zlib1g-dev autoconf flex make automake gettext libidn11 autopoint texinfo gperf ca-certificates wget pkg-config libpsl-dev libidn2-dev lua5.1-dev
RUN DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io -t "$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')-backports" install libzstd-dev zstd

# Setup patched wget with lua support
WORKDIR /tmp/workdir
COPY wget-lua wget-lua
COPY .git/modules/wget-lua .git/modules/wget-lua
WORKDIR /tmp/workdir/wget-lua
RUN ./bootstrap
RUN ./configure --with-ssl="${TLSTYPE}" -disable-nls
RUN make -j "$(nproc)"
RUN src/wget -V | grep -q lua


FROM debian:stable-slim
LABEL version="1.0.0" \
    description="ArchiveTeam Warrior container"

ENV DEBIAN_FRONTEND noninteractive
SHELL ["/usr/bin/env", "bash", "-euo", "pipefail", "-c"]
# Install dependencies
RUN apt-get update \
    && apt-get install -y \
        curl \
        git \
        jq \
        net-tools \
        libgnutls30 \
        liblua5.1-0 \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        python3-dev \
        sudo \
        wget \
        rsync \
        build-essential \
        lua-socket \
        flex \
    && rm -rf /var/lib/apt/lists/*

# Install warrior
COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY warrior.sh /usr/local/bin/warrior.sh
COPY env-to-json.sh /usr/local/bin/env-to-json.sh

# Setup Warrior User
RUN useradd -d /home/warrior -m -U warrior \
    && echo "warrior ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && mkdir -p "$HOME/data" \
    && chown -R warrior:warrior "$HOME/data"


WORKDIR /home/warrior
USER warrior
RUN mkdir -p "$HOME/projects" \
    && mkdir -p "$HOME/data"

COPY --from=builder-openssl /tmp/workdir/wget-lua/src/wget ./data/wget-at
COPY --from=builder-gnutls /tmp/workdir/wget-lua/src/wget ./data/wget-at-gnutls

# Expose web interface port
EXPOSE 8001

VOLUME "$HOME/data"
VOLUME "$HOME/projects"

ENTRYPOINT ["warrior.sh"]
CMD ["run-warrior3"]
