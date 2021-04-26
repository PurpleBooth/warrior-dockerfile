FROM debian:stable-slim as builder

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
       git \
    && rm -rf /var/lib/apt/lists/*

# Setup patched wget with lua support
WORKDIR /tmp

RUN git clone https://github.com/ArchiveTeam/wget-lua.git /tmp/wget
RUN curl --silent "https://api.github.com/repos/ArchiveTeam/wget-lua/releases/latest" \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/' \
    | xargs -I {} git -C wget checkout {}

WORKDIR /tmp/wget
ARG TLSTYPE=openssl
RUN set -eux \
 && case "${TLSTYPE}" in openssl) SSLPKG=libssl-dev;; gnutls) SSLPKG=gnutls-dev;; *) echo "Unknown TLSTYPE ${TLSTYPE}"; exit 1;; esac \
 && echo "deb http://deb.debian.org/debian $(dpkg --status tzdata|grep Provides|cut -f2 -d'-')-backports main contrib" > /etc/apt/sources.list.d/backports.list \
 && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io update \
 && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io install "${SSLPKG}" build-essential git bzip2 bash rsync gcc zlib1g-dev autoconf flex make automake gettext libidn11 autopoint texinfo gperf ca-certificates wget pkg-config libpsl-dev libidn2-dev lua5.1-dev \
 && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -qqy --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-unsafe-io -t buster-backports install libzstd-dev zstd \
 && cd /tmp/wget \
 && ./bootstrap \
 && ./configure --with-ssl="${TLSTYPE}" -disable-nls \
 && make -j $(nproc) \
 && src/wget -V | grep -q lua

FROM debian:stable-slim
LABEL version="1.0.0" \
    description="ArchiveTeam Warrior container"

ENV DEBIAN_FRONTEND noninteractive
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
        flex \
    && rm -rf /var/lib/apt/lists/*

# Install warrior
RUN pip3 install requests \
    && pip3 install six \
    && pip3 install warc \
    && pip3 install requests \
    && pip3 install six \
    && pip3 install warc \
    && pip3 install zstandard \
    && pip3 install seesaw

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

COPY --from=builder /tmp/wget/src/wget ./data/wget-at

# Expose web interface port
EXPOSE 8001

VOLUME "$HOME/data"
VOLUME "$HOME/projects"

ENTRYPOINT ["warrior.sh"]
CMD ["run-warrior3"]
