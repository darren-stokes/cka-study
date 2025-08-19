#!/bin/sh

ubuntu() {
    # Install Docker and add current user to the Docker group
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io curl apt-transport-https ca-certificates gnupg
    usermod -aG docker `whoami`

    # Install K3D
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

    # Configure Apt repo for Kubectl
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    chmod 644 /etc/apt/sources.list.d/kubernetes.list
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # Install Kubectl
    apt-get update && apt-get install -y kubectl
}

# Get OS
OS=`awk -F '=' '/^NAME=/ {print $NF}' /etc/os-release | sed -e 's/\"//g' | tr '[:upper:]' '[:lower:]'`

# Run the correct installation steps
case "$OS" in
    ubuntu|debian)
        ubuntu;;
    *)
        echo "Unsupported OS! Please install Docker and K3D manually following these steps: https://k3d.io/stable/#requirements"
esac

K3D_TEST=`k3d --help &>/dev/null && echo 0 || echo 1`

if [[ $K3D_TEST -eq 0 ]]
then
    echo -e "K3D installed succesfully!\nTo start your first cluster, run \"k3d cluster create cka-cluster --servers 1 --agents 2 --kubeconfig-switch-context\""
else
    echo "Something went wrong during the installation. Please check the output and inspect any errors"
fi