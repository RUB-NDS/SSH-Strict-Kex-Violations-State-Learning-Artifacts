# Dockerfile for the TinySSH SSH server
#
# Further information can be found at:
# - https://tinyssh.org/
# - https://github.com/janmojzis/tinyssh

FROM alpine:3.22.1
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN apk add --no-cache gzip gnupg build-base ucspi-tcp6

ARG GPG_KEY=D008B0C23D8479E46B9FCB9045DA517496939FF9
ARG VERSION=20250201

# Download the tinyssh source tarball.
RUN wget -q "https://github.com/janmojzis/tinyssh/archive/${VERSION}.tar.gz"

# Use a custom GPGHOME to fetch the GPG key and verify the package signature.
# Tarballs prior to 20180101 are not signed, so we need to skip this step if
# the version to build is older.
RUN if printf '%s\n%s\n' "20180101" "${VERSION}" | sort -c -g; then \
        wget -q "https://github.com/janmojzis/tinyssh/releases/download/${VERSION}/${VERSION}.tar.gz.asc" && \
        GNUPGHOME="$(mktemp -d)" && \
        export GNUPGHOME && \
        gpg --keyserver keyserver.ubuntu.com --recv-keys "$GPG_KEY" && \
        gpg --batch --verify "${VERSION}.tar.gz.asc" "${VERSION}.tar.gz" && \
        { command -v gpgconf > /dev/null && gpgconf --kill all || :; } && \
        rm -rf "$GNUPGHOME" "${VERSION}.tar.gz.asc" ; \
    fi

# Build and install tinyssh according to the instruction on the website [1].
#
# Please note that tinyssh doesn't include its own version in the SSH version
# string by default, except when building a debian package [2]:
#
#    debug1: Remote protocol version 2.0, remote software version tinyssh_noversion c6UalVV3
#
# This is a bit inconvenient when working with multiple tinyssh docker
# containers. Hence, we create a `debian/changelog` file to make sure that the
# version is always included.
#
# Some versions (e.g. 20160726) will fail when the man page directories don't
# exist:
#
#     _tinysshd-install: fatal: unable to stat directory /usr/share/man/man1 (file does not exist)
#     _tinysshd-install: fatal: unable to stat directory /usr/share/man/man8 (file does not exist)
#
# Hence, we create those directories manually before installation to prevent
# this issue.
#
# References:
# [1] https://tinyssh.org/install.html
# [2] https://github.com/janmojzis/tinyssh/blob/97dd9e05f52482e46d660af81547c7c02669c1a2/make-tinyssh.sh#L17
RUN gunzip < ${VERSION}.tar.gz | tar -xf - && \
    mkdir -p "tinyssh-${VERSION}/debian" && \
    echo "tinyssh (${VERSION})" > "tinyssh-${VERSION}/debian/changelog" && \
    make -C "tinyssh-${VERSION}" -j "$(nproc)" && \
    mkdir -p /usr/share/man/man1 /usr/share/man/man8 && \
    PREFIX=/usr make -C "tinyssh-${VERSION}" install && \
    mkdir -p /etc/tinyssh && tinysshd-makekey /etc/tinyssh/sshkeydir

# Set up SSH user, add authorized keys and fix `.ssh` dir permissions.
# Note that tinyssh only works with pubkey authentication, so we don't set a
# password.
ARG USERNAME=sshattacker
ARG AUTHORIZED_KEYS_FILE=authorized_keys
COPY "${AUTHORIZED_KEYS_FILE}" "/home/${USERNAME}/.ssh/authorized_keys"
RUN adduser -D "${USERNAME}" && \
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}" && \
    chmod -R g=,o= "/home/${USERNAME}/.ssh"

LABEL ssh.implementation.name="tinyssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="server"

CMD ["tcpserver", "-HRDl0", "0.0.0.0", "22", "/usr/sbin/tinysshd", "-v", "/etc/tinyssh/sshkeydir"]
EXPOSE 22
