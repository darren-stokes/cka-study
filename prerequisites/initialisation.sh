#!/bin/sh

redhat_pkg_manager(){
    # As the RedHat family is quite diverse, figure out what package manager is used
    if command -v dnf >/dev/null; then
        echo "dnf"
    elif command -v microdnf >/dev/null; then
        microdnf install -y dnf
        echo "dnf"
    elif command -v yum >/dev/null; then
        echo "yum"
    else
        echo "No supported Red Hat package manager found"
        exit 1
    fi
}

alpine() {
    # Install Docker and add current user to the Docker group
    apk add -q --update docker openrc bash curl util-linux-login kubectl 1>/dev/null
    DOCKER_GID=`getent group docker | awk -F ':' '{print $3}'`
    addgroup -g $DOCKER_GID `whoami` 1>/dev/null

    # Get k3d
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash 1>/dev/null
}

redhat(){
    # Determine installer
    INSTALLER=$(redhat_pkg_manager)

    $INSTALLER -y install dnf-plugins-core
    $INSTALLER -y config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
}

ubuntu() {
    # Install Docker and add current user to the Docker group
    apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io curl apt-transport-https ca-certificates gnupg 1>/dev/null
    usermod -aG docker `whoami` 1>/dev/null

    # Install K3D
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash 1>/dev/null

    # Configure Apt repo for Kubectl
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
    chmod 644 /etc/apt/sources.list.d/kubernetes.list
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # Install Kubectl
    apt-get update -qq && apt-get install -qq -y kubectl
}

# Get OS
OS=`awk -F '=' '/^NAME=/ {print $NF}' /etc/os-release | sed -e 's/\"//g' | tr '[:upper:]' '[:lower:]'`

# Run the correct installation steps
case "$OS" in
    alpine*)
        alpine;;
    redhat*)
        redhat;;
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