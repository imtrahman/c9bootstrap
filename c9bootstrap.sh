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
    sudo yum clean all
    sudo yum update -y --skip-broken
}

function update_python_packages() {
    _logger "[+] Upgrading Python pip and setuptools"
    python3 -m pip install --upgrade pip setuptools --user

    _logger "[+] Installing latest AWS CLI"
}

function install_utility_tools() {
    _logger "[+] Installing jq and yq"
    sudo yum install -y jq
    wget -O yq_linux_amd64.tar.gz https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64.tar.gz
    sudo -- sh -c 'tar -xvzf yq_linux_amd64.tar.gz && mv yq_linux_amd64 /usr/bin/yq'
    cd $/HOME/environment/
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
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
    aws configure set default.region ${AWS_REGION}
    aws configure get default.region

}

function disable_c9_temp_creds() {
    _logger "[+] Disabling AWS managed temporary credentials for Cloud9..."
    aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
}
function cleanup() {
    sudo rm -rf ./aws ./awscliv2.zip
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
    #exec ${SHELL}
    sudo shutdown -r now
}

main
