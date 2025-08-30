# Dockerfile for the libssh SSH example server
#
# Further information can be found at:
# - https://www.libssh.org/

FROM debian:bullseye
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ca-certificates \
    curl \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Obtain libssh source code
ARG VERSION=0.11.1
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
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j "$(nproc)" && \
    make install

# Copy hostkeys
COPY host_keys /etc/ssh/host_keys/

LABEL "ssh.implementation.name"="libssh" \
    "ssh.implementation.version"="${VERSION}" \
    "ssh.implementation.type"="server"

ENTRYPOINT [ "/src/libssh/build/examples/ssh_server_fork" ]
CMD [ "-p", "22", \
  "-k", "/etc/ssh/host_keys/ssh_host_dsa_key", \
  "-k", "/etc/ssh/host_keys/ssh_host_ecdsa_key", \
  "-k", "/etc/ssh/host_keys/ssh_host_rsa_key", \
  "-k", "/etc/ssh/host_keys/ssh_host_ed25519_key", \
  "0.0.0.0" ]
EXPOSE 22
