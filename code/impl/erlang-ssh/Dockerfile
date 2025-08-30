# Dockerfile for the SSH daemon included in Erlang/OTP
# Authentication is disabled for this implementation
#
# Further information can be found at:
# - https://www.erlang.org/doc/apps/ssh/introduction.html
# - https://www.erlang.org/doc/man/ssh_app

ARG VERSION=27.3.0.0

FROM erlang:${VERSION}-alpine
SHELL ["/bin/ash", "-o", "pipefail", "-c"]
# Install runtime dependencies
RUN apk add --update --no-cache openssl

# Copy hostkeys
COPY hostkeys/* /etc/ssh/

ARG VERSION
LABEL ssh.implementation.name="erlang-ssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="server"

ENTRYPOINT [ "/usr/local/bin/erl", "-noshell", "-eval", "ssh:start()" , "-eval" ]
CMD [ "ssh:daemon(22)" ]
EXPOSE 22
