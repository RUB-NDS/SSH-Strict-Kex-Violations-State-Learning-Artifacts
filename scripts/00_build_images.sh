#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Set up variables for directories
SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
ARTIFACTS_DIR=$(readlink -f "$SCRIPTS_DIR/..")
cd $ARTIFACTS_DIR
LOG_FILE="$ARTIFACTS_DIR/logs/build_images_$(date +'%Y%m%d_%H%M%S').log"
rm -rf $LOG_FILE && mkdir -p "$ARTIFACTS_DIR/logs" && touch $LOG_FILE

function log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# Check that the script is invoked without sudo
if [[ $SUDO_USER ]]; then
   log "${RED}[!] This script should not be run with sudo.${NC}"
   exit 1
fi

# Check available CPU cores
CPU_CORES=$(nproc)
if [[ $CPU_CORES -lt 8 ]]; then
   log "${YELLOW}[~] We recommend having at least 8 CPU cores available when running these artifacts. Running with less may impact performance.${NC}"
fi

function build_impl_images() {
    log "${GREEN}[+] Building SSH server images...${NC}"
    log "    - AsyncSSH"
    cd ${ARTIFACTS_DIR}/code/impl/asyncssh
    docker compose build >> $LOG_FILE 2>&1
    log "    - Dropbear"
    cd ${ARTIFACTS_DIR}/code/impl/dropbear
    docker compose build >> $LOG_FILE 2>&1
    log "    - Erlang SSH"
    cd ${ARTIFACTS_DIR}/code/impl/erlang-ssh
    docker compose build >> $LOG_FILE 2>&1
    log "    - Golang"
    cd ${ARTIFACTS_DIR}/code/impl/golang
    docker compose build >> $LOG_FILE 2>&1
    log "    - libssh"
    cd ${ARTIFACTS_DIR}/code/impl/libssh
    docker compose build >> $LOG_FILE 2>&1
    log "    - OpenSSH"
    cd ${ARTIFACTS_DIR}/code/impl/openssh
    docker compose build >> $LOG_FILE 2>&1
    log "    - TinySSH"
    cd ${ARTIFACTS_DIR}/code/impl/tinyssh
    docker compose build >> $LOG_FILE 2>&1
    cd ${ARTIFACTS_DIR}
}

function build_tool_images() {
    log "${GREEN}[+] Building tool images...${NC}"
    log "    - SSH-Attacker"
    docker build -t ssh-attacker:2.0.4-SL \
                 -t ssh-attacker:latest \
                 ${ARTIFACTS_DIR}/code/ssh_attacker >> $LOG_FILE 2>&1
    log "    - SSH-State-Learner"
    docker build -t ssh-state-learner:1.0.0 \
                 -t ssh-state-learner:latest \
                 ${ARTIFACTS_DIR}/code/ssh_state_learner >> $LOG_FILE 2>&1
}

if ! command -v docker &> /dev/null; then
    log "${RED}[!] Docker is not installed. Please install Docker and try again.${NC}"
    log "${YELLOW}[~] You can install Docker by following the official guide: https://docs.docker.com/engine/install/ubuntu/ ${NC}"
    exit 1
fi
build_impl_images
build_tool_images
log "${GREEN}[+] Evaluation environment ready to use!${NC}"
