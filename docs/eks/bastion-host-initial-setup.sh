#!/bin/bash

set -xeou pipefail

sudo apt update
sudo apt upgrade -y
sudo apt install fish -y

install_aws_cli() {
  # install aws cli
  sudo apt install unzip >/dev/null
  sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" >/dev/null
  unzip awscliv2.zip >/dev/null
  sudo ./aws/install >/dev/null
  echo "################## aws successfully installed"
}

install_kubectl() {
    # install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
    curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
    curl -LO https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    echo "################## kubectl successfully installed"
}

install_helm() {
  # install helm
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  echo "################## helm successfully installed"
}

install_aws_iam_authenticator() {
  # install aws_iam_authenticator
  # current version: v0.6.28
  curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.28/aws-iam-authenticator_0.6.28_linux_amd64
  chmod +x ./aws-iam-authenticator
  sudo mkdir -p $HOME/bin && sudo cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
  echo 'export PATH=$PATH:$HOME/bin' >>~/.bashrc
  echo "################## aws-iam-authenticator successfully installed"
}

function init() {
  install_aws_cli || true
  install_kubectl || true
  install_helm || true
  install_aws_iam_authenticator || true
}

init