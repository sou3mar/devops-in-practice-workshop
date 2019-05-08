#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echo "Not running as root"
  exit
fi

apt-get update && apt-get install -y apt-transport-https unzip
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
cat <<EOF >/etc/apt/sources.list.d/google-cloud-sdk.list
deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main
EOF
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-get update

PACKAGES_TO_INSTALL=""
if hash javac 2>/dev/null; then
  echo "Java is already installed!"
else
  echo "Installing Java..."
  PACKAGES_TO_INSTALL+=" default-jdk"
fi

if hash git 2>/dev/null; then
  echo "Git is already installed!"
else
  echo "Installing Git..."
  PACKAGES_TO_INSTALL+=" git"
fi

if hash VBoxManage 2>/dev/null; then
  echo "VirtualBox is already installed!"
else
  echo "Installing VirtualBox..."
  PACKAGES_TO_INSTALL+=" virtualbox"
fi

if hash docker 2>/dev/null; then
  echo "Docker is already installed!"
else
  echo "Installing Docker..."
  PACKAGES_TO_INSTALL+=" docker.io"
fi

if hash kubectl 2>/dev/null; then
  echo "Kubectl is already installed!"
else
  echo "Installing kubectl..."
  PACKAGES_TO_INSTALL+=" kubectl"
fi

if hash gcloud 2>/dev/null; then
  echo "Google Cloud SDK is already installed!"
else
  echo "Installing Google Cloud SDK..."
  PACKAGES_TO_INSTALL+=" google-cloud-sdk"
fi

apt-get install -y $PACKAGES_TO_INSTALL

if hash minikube 2>/dev/null; then
  echo "Minikube is already installed!"
else
  echo "Installing minikube..."
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  chmod +x minikube
  mv minikube /usr/local/bin/
fi

if hash terraform 2>/dev/null; then
  echo "Terraform is already installed!"
else
  echo "Installing terraform..."
  curl -Lo terraform.zip https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
  unzip terraform.zip
  mv terraform /usr/local/bin/
  rm terraform.zip
fi

if hash helm 2>/dev/null; then
  echo "Helm is already installed!"
else
  echo "Installing Helm..."
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
  chmod 700 get_helm.sh
  ./get_helm.sh
  rm get_helm.sh
fi
