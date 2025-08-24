# Dockerfile for the SSH daemon included in Erlang/OTP
#
# Further information can be found at:
# - https://www.erlang.org/doc/apps/ssh/introduction.html
# - https://www.erlang.org/doc/man/ssh_app

ARG VERSION
# `erlang-ssh-base` is just an intermediate image and does not require labels,
# so we can disable that linter rule.
# hadolint ignore=DL3049
FROM erlang:${VERSION}-alpine AS erlang-ssh-base
SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN apk add --update --no-cache openssl expect

# Server image
FROM erlang-ssh-base AS erlang-ssh-server
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ARG USERNAME=sshattacker
ARG PASSWORD=secret
ARG DOTSSH=dotssh-server
RUN adduser -D "${USERNAME}" && echo "${USERNAME}:${PASSWORD}" | chpasswd
COPY --chown="${USERNAME}:${USERNAME}" "${DOTSSH}" "/home/${USERNAME}/.ssh/"
RUN chmod -R g=,o= "/home/${USERNAME}/.ssh"

COPY hostkeys/* /etc/ssh/
ARG VERSION
LABEL ssh.implementation.name="erlang-ssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="server"
ENTRYPOINT [ "/usr/local/bin/erl", "-noshell", "-eval", "ssh:start()" , "-eval" ]
CMD [ "ssh:daemon(22)" ]
EXPOSE 22

# Client image
FROM erlang-ssh-base AS erlang-ssh-client
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ARG USERNAME=sshattacker
ARG DOTSSH=dotssh-client
COPY "${DOTSSH}" "/root/.ssh/"

ARG VERSION
LABEL ssh.implementation.name="erlang-ssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="client"
ENTRYPOINT [ "/usr/local/bin/erl", "-noshell", "-eval", "ssh:start()", "-eval" ]

# Automated client image
FROM erlang-ssh-base AS erlang-ssh-client-automated
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

COPY start_client.exp /usr/local/bin
WORKDIR "/usr/local/bin"

ARG VERSION
LABEL ssh.implementation.name="erlang-ssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="client-automated"
ENTRYPOINT [ "expect" , "start_client.exp" ]
