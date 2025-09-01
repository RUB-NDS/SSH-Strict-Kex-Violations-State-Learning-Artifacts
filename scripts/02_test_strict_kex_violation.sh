#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
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

function select_violation() {
    VIOLATIONS=(
        "AsyncSSH (C2 - DHGEX)"
        "Dropbear (C4)"
        "Erlang SSH (C3)"
        "Lancom LCOS (C3)"
        "libssh (C2 - DHGEX)"
        "Tectia SSH (C1)"
        "Tectia SSH (C3)"
        "TinySSH (C4)"
    )
    log "${CYAN}[?] Select a strict KEX violation to test:${NC}"
    select VIOLATION in "${VIOLATIONS[@]}"; do
        case $VIOLATION in
            "${VIOLATIONS[0]}")
                SSH_IMPL="asyncssh"
                SSH_IMPL_NAME="AsyncSSH"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_dh_gex_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/asyncssh_dhgex_strict_kex_violation.xml"
                break
                ;;
            "${VIOLATIONS[1]}")
                SSH_IMPL="dropbear"
                SSH_IMPL_NAME="Dropbear"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_ecdh_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/dropbear_strict_kex_violation.xml"
                break
                ;;
            "${VIOLATIONS[2]}")
                SSH_IMPL="erlang-ssh"
                SSH_IMPL_NAME="Erlang SSH"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_ecdh_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/erlang_strict_kex_violation.xml"
                break
                ;;
            "${VIOLATIONS[3]}")
                SSH_IMPL="lancom-lcos"
                SSH_IMPL_NAME="Lancom LCOS"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_ecdh_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/lancom_strict_kex_violation.xml"
                break
                ;;
            "${VIOLATIONS[4]}")
                SSH_IMPL="libssh"
                SSH_IMPL_NAME="libssh"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_dh_gex_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/libssh_dhgex_strict_kex_violation.xml"
                break
                ;;
            "${VIOLATIONS[5]}")
                SSH_IMPL="tectia-ssh"
                SSH_IMPL_NAME="Tectia SSH"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_ecdh_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/tectia_c1_strict_kex_violation.xml"
                break
                ;;
            "${VIOLATIONS[6]}")
                SSH_IMPL="tectia-ssh"
                SSH_IMPL_NAME="Tectia SSH"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_ecdh_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/tectia_c3_strict_kex_violation.xml"
                break
                ;;
            "${VIOLATIONS[7]}")
                SSH_IMPL="tinyssh"
                SSH_IMPL_NAME="TinySSH"
                POC_CONFIG="$ARTIFACTS_DIR/code/ssh_attacker/resources/configs/kex_ecdh_config.xml"
                POC_WORKFLOW_TRACE="$ARTIFACTS_DIR/code/pocs/strict_kex_violations/tinyssh_strict_kex_violation.xml"
                break
                ;;
            *)
                log "${RED}[!] Invalid selection. Please try again.${NC}"
                ;;
        esac
    done
    log "${GREEN}[+] Selected violation: $VIOLATION${NC}"
    log "    - Implementation: $SSH_IMPL_NAME"
    log "    - POC Workflow Trace: $POC_WORKFLOW_TRACE"
}

function start_server() {
    log "${GREEN}[+] Starting $SSH_IMPL_NAME server...${NC}"
    case $SSH_IMPL in
        "asyncssh"|"dropbear"|"erlang-ssh"|"libssh"|"tinyssh")
            IS_DOCKERIZED_SERVER=true
            cd "$ARTIFACTS_DIR/code/impl/$SSH_IMPL"
            docker-compose up -d |& tee -a $LOG_FILE
            SERVER_HOST="host.docker.internal"
            SERVER_PORT=$(docker compose port server 22 | awk -F: '{print $2}')
            cd "$ARTIFACTS_DIR"
            ;;
        "lancom-lcos")
            log "    - Note: Lancom LCOS is a network device operating system. As such, it requires manual installation and configuration on a suitable network device or as an appliance."
            log "    - We recommend using the Lancom LCOS vRouter which can be deployed as a virtual machine (no license required). The following appliance can be deployed on VMware Workstation Pro or other virtualization platforms supporting OVA applicances."
            log "    - Appliance: https://ftp.lancom.de/LANCOM-Archive/LC-vRouter/LC-vRouter-10.90.0126-Rel.ova"
            log "    - Manual: https://www.lancom-systems.com/fileadmin/download/documentation/Installation_Guide/IG_vRouter_EN.pdf"
            read -p "    - Enter the hostname where the Lancom LCOS server is running: " SERVER_HOST
            read -p "    - Enter the port where the Lancom LCOS server is running: " SERVER_PORT
            ;;
        "tectia-ssh")
            log "    - Note: Tectia SSH is a commercial Windows-based SSH server. As such, it requires manual installation and configuration on a host system."
            log "    - Historical versions of Tectia SSH are not available for download. Therefore, results may deviate from those obtained during evaluation."
            log "    - Tectia SSH does not offer a free version but provides a trial version that can be used for analysis."
            log "    - Trial form: https://info.ssh.com/tectia-ssh-client-server-trial-download"
            read -p "    - Enter the hostname where the Tectia SSH server is running: " SERVER_HOST
            read -p "    - Enter the port where the Tectia SSH server is running: " SERVER_PORT
            ;;
    esac
    log "    - Server running at $SERVER_HOST:$SERVER_PORT"
}

function stop_servers() {
    if [[ $IS_DOCKERIZED_SERVER != true ]]; then
        return
    fi
    log "${GREEN}[+] Stopping $SSH_IMPL server...${NC}"
    cd "$ARTIFACTS_DIR/code/impl/$SSH_IMPL"
    docker-compose down |& tee -a $LOG_FILE
    cd "$ARTIFACTS_DIR"
}

function run_ssh_client() {
    log "${GREEN}[+] Running SSH-Attacker client with POC workflow trace...${NC}"
    docker run --rm \
        -v "$POC_WORKFLOW_TRACE":/trace.xml \
        -v "$POC_CONFIG":/config.xml \
        ssh-attacker:latest \
        -connect "$SERVER_HOST:$SERVER_PORT" \
        -config /config.xml \
        -workflow_input /trace.xml |& tee -a $LOG_FILE
    log "${GREEN}[+] SSH-Attacker client run completed.${NC}"
    log "    - If the PoC was successful, you should see that the workflow trace was executed as planned in the tool's last output line."
}

select_violation
trap 'stop_servers' EXIT
start_server
run_ssh_client
