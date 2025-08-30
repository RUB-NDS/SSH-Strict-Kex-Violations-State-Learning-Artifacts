# Dockerfile for the SSH server included in Golang x/crypto
# Authentication is disabled for this implementation
#
# Further information can be found at:
# - https://pkg.go.dev/golang.org/x/crypto/ssh

FROM golang:1.24

WORKDIR /usr/src/app

# Install go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy source code and build SSH sample server
COPY . .
RUN go build -v -o /usr/local/bin/app ./...

ENTRYPOINT ["app"]
EXPOSE 22
