# Dockerfile for libssh 0.9.x (based on Debian Bullseye)

# `libssh-builder` is just an intermediate image used for building and does
# not require labels, so we can disable that linter rule.
# hadolint ignore=DL3049
FROM debian:bullseye AS libssh-builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ca-certificates \
    curl \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
ARG VERSION
RUN mkdir /src && \
    curl -s "https://gitlab.com/libssh/libssh-mirror/-/archive/libssh-${VERSION}/libssh-mirror-libssh-${VERSION}.tar.gz" | tar xzf - && \
    mv "libssh-mirror-libssh-${VERSION}" /src/libssh
WORKDIR /src/libssh

ARG USERNAME=sshattacker
ARG PASSWORD=secret

# Make the old filename "ssh_server_fork.c" a hardlink to the new one in libssh
# >= 0.10.0 to make it compatible with this Dockerfile.
RUN if [ ! -e  examples/ssh_server_fork.c ]; then ln examples/ssh_server.c examples/ssh_server_fork.c ; fi
RUN sed -i "s/myuser/${USERNAME}/g" examples/ssh_server_fork.c && \
    sed -i "s/mypassword/${PASSWORD}/g" examples/ssh_server_fork.c

WORKDIR /src/libssh/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/install .. && \
    make -j "$(nproc)" && \
    make install

FROM debian:bullseye AS libssh-server
ARG VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl-dev \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*
COPY host_keys /install/host_keys/
COPY --from=libssh-builder /install /usr/
COPY --from=libssh-builder /src/libssh/build/examples /install/examples/
LABEL "ssh.implementation.name"="libssh" \
    "ssh.implementation.version"="${VERSION}" \
    "ssh.implementation.type"="server"
ENTRYPOINT [ "/install/examples/ssh_server_fork" ]
CMD [ "-p", "22", \
  "-k", "/install/host_keys/ssh_host_dsa_key", \
  "-k", "/install/host_keys/ssh_host_ecdsa_key", \
  "-k", "/install/host_keys/ssh_host_rsa_key", \
  "-k", "/install/host_keys/ssh_host_ed25519_key", \
  "0.0.0.0" ]
EXPOSE 22

FROM debian:bullseye AS libssh-client
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DOTSSH=dotssh-client
COPY "${DOTSSH}" "/root/.ssh/"

RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl-dev \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*
COPY --from=libssh-builder /install /usr/
COPY --from=libssh-builder /src/libssh/build/examples /install/examples/

ARG VERSION
LABEL "ssh.implementation.name"="libssh" \
    "ssh.implementation.version"="${VERSION}" \
    "ssh.implementation.type"="client"
ENTRYPOINT [ "/install/examples/ssh-client" ]
