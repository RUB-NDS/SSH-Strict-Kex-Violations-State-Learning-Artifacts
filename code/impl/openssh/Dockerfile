# Dockerfile for the OpenSSH Portable SSH server
#
# Further information can be found at:
# - https://www.openssh.com/
# - https://github.com/openssh/openssh-portable

FROM debian:bullseye
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Obtain OpenSSH source code
ARG VERSION=9.9p2
RUN mkdir /src && curl -s https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${VERSION}.tar.gz | tar xzf - -C /src
WORKDIR "/src/openssh-${VERSION}"

# Build OpenSSH with debug flags enabled
RUN ./configure CFLAGS="-DDEBUG_KEX=1 -DDEBUG_KEXDH=1 -DDEBUG_KEXECDH=1" --prefix /install && \
    make -j "$(nproc)" && \
    make install-files install-sysconf host-key

# Create unprivileged user and user for authentication
ARG USERNAME=sshattacker
ARG PASSWORD=secret
RUN useradd --create-home --groups users "${USERNAME}" && \
    echo "${USERNAME}:${PASSWORD}" | chpasswd
RUN useradd --system --no-create-home sshd && mkdir -p "/var/empty"

# Create .ssh directory for user
ARG DOTSSH=dotssh-server
COPY --chown="${USERNAME}:${USERNAME}" "${DOTSSH}" "/home/${USERNAME}/.ssh/"
RUN chmod -R g=,o= "/home/${USERNAME}/.ssh"

LABEL ssh.implementation.name="openssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="server"

# Rate Limit: Increase `MaxStartups` to make it unlikely to trigger the
# `Exceeded MaxStartups\r\n` issue, even when opening a lot of connections.
# Also disable the new per-source penalties to avoid issues with multiple connections from the same client.
ENTRYPOINT [ "/install/sbin/sshd", "-D", "-e", "-o", "MaxStartups=65536", "-o", "PerSourcePenalties=no" ]
EXPOSE 22
