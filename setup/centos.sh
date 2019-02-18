#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echo "Not running as root"
  exit
fi

curl -so /etc/yum.repos.d/virtualbox.repo http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOF
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum update -y
yum install -y unzip

PACKAGES_TO_INSTALL=""

if hash javac 2>/dev/null; then
  echo "Java is already installed!"
else
  echo "Installing Java..."
  PACKAGES_TO_INSTALL+=" java-1.8.0-openjdk"
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
  PACKAGES_TO_INSTALL+=" binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms VirtualBox-5.2"
fi

if hash docker 2>/dev/null; then
  echo "Docker is already installed!"
else
  echo "Installing Docker..."
  PACKAGES_TO_INSTALL+=" docker"
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

yum install -y $PACKAGES_TO_INSTALL

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
