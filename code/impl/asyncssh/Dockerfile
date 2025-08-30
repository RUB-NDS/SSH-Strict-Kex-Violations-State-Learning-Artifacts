# Dockerfile for the AsyncSSH SSH server
#
# Further information can be found at:
# - https://asyncssh.readthedocs.io/en/latest/
# - https://github.com/ronf/asyncssh

FROM python:3.13.7

# Install python packages required by the sample server
WORKDIR /app
COPY files/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Install asyncssh in the specified version
ARG VERSION=2.20.0
RUN pip install --no-cache-dir asyncssh==$VERSION

# Copy authorized pubkeys
ARG AUTHORIZED_KEYS_FILE=authorized_keys
COPY "files/${AUTHORIZED_KEYS_FILE}" "authorized_keys"

# Copy server script and RSA host key
COPY files/simple_server.py files/ssh_host_key* ./

# Environment variables are picked up by the simple_server.py script
ARG USERNAME=sshattacker
ARG PASSWORD=secret
ENV SSH_USERNAME="${USERNAME}" SSH_PASSWORD="${PASSWORD}"

LABEL ssh.implementation.name="asyncssh" \
      ssh.implementation.version="${VERSION}" \
      ssh.implementation.type="server"

ENTRYPOINT [ "python", "/app/simple_server.py", "-f", "authorized_keys" ]
EXPOSE 22
