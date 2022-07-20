#!/bin/bash

# Cloud9 Bootstrap Script
#
# Testing on Amazon Linux 2
#
# 1. Installs homebrew
# 2. Upgrades to latest AWS CLI
#
# Usually takes about 8 minutes to complete

set -exo pipefail
exec 2> >(tee -a "/tmp/c9bootstrap.log")
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function _logger() {
    echo -e "$(date) ${YELLOW}[*] $@ ${NC}"
}

function update_system() {
    _logger "[+] Updating system packages"
    sudo yum update -y --skip-broken
}

function update_python_packages() {
    _logger "[+] Upgrading Python pip and setuptools"
    python3 -m pip install --upgrade pip setuptools --user

    _logger "[+] Installing latest AWS CLI"
    # --user installs into $HOME/.local/bin/aws. After this is installed, remove the prior version
    # in /usr/bin/. The --upgrade isn't necssary on a new install, but saft to leave in if Cloud9
    # ever installs the aws-cli this way.
    echo "PATH=$PATH:$HOME/.local/bin:$HOME/bin" >> ~/.bashrc
    python3 -m pip install --upgrade --user awscli
    if [[ -f /usr/bin/aws ]]; then
        sudo rm -rf /usr/bin/aws*
    fi
}

function install_utility_tools() {
    _logger "[+] Installing jq and yq"
    sudo yum install -y jq
    wget -O yq_linux_amd64.tar.gz https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64.tar.gz
    sudo -- sh -c 'tar -xvzf yq_linux_amd64.tar.gz && mv yq_linux_amd64 /usr/bin/yq'
}

function configure_aws_cli() {
    _logger "[+] Configuring AWS CLI for Cloud9..."
    echo "export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >> ~/.bashrc
    echo "export AWS_REGION=\$AWS_DEFAULT_REGION" >> ~/.bashrc
    echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
    source ~/.bashrc

}


function configure_bash_profile() {

    _logger "[+] Configuring AWS CLI for Cloud9..."
    echo "export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}" | tee -a ~/.bash_profile
    echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
    echo "export TIMESTAMP=$(date +%s)" | tee -a ~/.bash_profile
    source  ~/.bash_profile 
    . ~/.bashrc
    PATH="$PATH:$HOME/.local/bin"
    aws configure set default.region ${AWS_REGION}
    aws configure get default.region

}

function disable_c9_temp_creds() {
    _logger "[+] Disabling AWS managed temporary credentials for Cloud9..."
    aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
}
function cleanup() {
    if [[ -d $SAM_INSTALL_DIR ]]; then
        rm -rf $SAM_INSTALL_DIR
    fi
}

function main() {
    update_system
    update_python_packages
    install_utility_tools
    configure_aws_cli
    configure_bash_profile
    disable_c9_temp_creds
    cleanup

    echo -e "${RED} [!!!!!!!!!] To be safe, I suggest closing this terminal and opening a new one! ${NC}"
    _logger "[+] Restarting Shell to reflect changes"
    exec ${SHELL}
}

main
