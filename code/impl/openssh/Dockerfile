# Dockerfile for OpenSSH 8+ (based on Debian Bullseye)

ARG USERNAME=sshattacker
ARG PASSWORD=secret

# `openssh-builder` is just an intermediate image and does not require labels,
# so we can disable that linter rule.
# hadolint ignore=DL3049
FROM debian:bullseye AS openssh-builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
ARG VERSION
RUN mkdir /src && curl -s https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${VERSION}.tar.gz | tar xzf - -C /src
COPY patches /src
WORKDIR "/src/openssh-${VERSION}"

# Patch build errors due to wrong variable names in an ifdef'ed DEBUG_KEXDH
# section that went out-of-sync with the rest of the code.
RUN if ! printf "%s\n%s\n" "8.4" "${VERSION}" | sort -c -g; then \
        patch -p1 < /src/0001-Fix-Wimplicit-function-declaration-errors-when-DEBUG-v8.0-v8.3.patch; \
    fi

# If `WITH_NONE_CIPHER` is not zero, patch the OpenSSL version to allow using
# the `none` cipher.
ARG WITH_NONE_CIPHER=1
RUN if [ "${WITH_NONE_CIPHER}" -ne 0 ] ; then \
        patch -p1 < /src/0001-Enable-support-for-none-cipher.patch; \
    fi

WORKDIR "/src/openssh-${VERSION}"
RUN ./configure CFLAGS="-DDEBUG_KEX=1 -DDEBUG_KEXDH=1 -DDEBUG_KEXECDH=1" --prefix /install && \
    make -j "$(nproc)" && \
    make install-files install-sysconf host-key

# Common for client and server image.
#
# `openssh-base` is just an intermediate image and does not require labels, so
# we can disable that linter rule.
# hadolint ignore=DL3049
FROM debian:bullseye AS openssh-base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev \
    zlib1g-dev \
    expect\
    && rm -rf /var/lib/apt/lists/*

ARG USERNAME
ARG PASSWORD
RUN useradd --create-home --groups users "${USERNAME}" && \
    echo "${USERNAME}:${PASSWORD}" | chpasswd

# Server image
FROM openssh-base AS openssh-server

RUN useradd --system --no-create-home sshd && mkdir -p "/var/empty"

ARG USERNAME
ARG DOTSSH=dotssh-server
COPY --chown="${USERNAME}:${USERNAME}" "${DOTSSH}" "/home/${USERNAME}/.ssh/"
RUN chmod -R g=,o= "/home/${USERNAME}/.ssh"

ARG VERSION
COPY --from=openssh-builder /install /install
LABEL ssh.implementation.name="openssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="server"

# Rate Limit: Increase `MaxStartups` to make it unlikely to trigger the
# `Exceeded MaxStartups\r\n` issue, even when opening a lot of connections.
#
# FIXME: Although the server starts fine, login seems to be broken for 8.0p1
# and 8.1p1. The server simply closes the connection.
ENTRYPOINT [ "/install/sbin/sshd", "-D", "-e", "-o", "MaxStartups=65536" ]
EXPOSE 22

# Client image
FROM openssh-base AS openssh-client

ARG USERNAME
ARG DOTSSH=dotssh-client
COPY --chown="${USERNAME}:${USERNAME}" "${DOTSSH}" "/home/${USERNAME}/.ssh/"
RUN chmod -R g=,o= "/home/${USERNAME}/.ssh"

ARG VERSION
COPY --from=openssh-builder /install /install
LABEL ssh.implementation.name="openssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="client"
ENTRYPOINT [ "/install/bin/ssh" ]

# Automated client image
FROM openssh-client AS openssh-client-automated

COPY login.exp start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

COPY --from=openssh-builder /install /install
LABEL ssh.implementation.name="openssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="client-automated"
ENTRYPOINT [ "/usr/local/bin/start.sh" ]
