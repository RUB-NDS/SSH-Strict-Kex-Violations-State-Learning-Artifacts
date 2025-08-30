# Dockerfile for the Dropbear SSH server
#
# Further information can be found at:
# - https://matt.ucc.asn.au/dropbear/dropbear.html
# - https://github.com/mkj/dropbear

FROM alpine:3.22.1 AS dropbear-builder
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# Install Dropbear build dependencies
RUN apk add --no-cache bzip2 build-base zlib-dev

# Obtain Dropbear source code
ARG VERSION=2025.87
RUN wget -O - -q "https://matt.ucc.asn.au/dropbear/releases/dropbear-${VERSION}.tar.bz2" | bunzip2 | tar -xf -
WORKDIR "/dropbear-${VERSION}"

# Configure, build and install dropbear
RUN ./configure && \
    make PROGRAMS="dropbear" -j "$(nproc)" && \
    make PROGRAMS="dropbear" install

# Copy hostkeys
COPY hostkeys/dropbear_*_host_key /etc/dropbear/

# Set up SSH user, configure a password, add authorized keys and fix `.ssh` dir
# permissions.
ARG USERNAME=sshattacker
ARG PASSWORD=secret
ARG AUTHORIZED_KEYS_FILE=authorized_keys
COPY "${AUTHORIZED_KEYS_FILE}" "/home/${USERNAME}/.ssh/authorized_keys"
RUN adduser -D "${USERNAME}" && \
    echo "${USERNAME}:${PASSWORD}" | chpasswd && \
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}" && \
    chmod -R g=,o= "/home/${USERNAME}/.ssh"

LABEL ssh.implementation.name="dropbear" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="server"

ENTRYPOINT [ "dropbear", "-FEB" ]
EXPOSE 22
