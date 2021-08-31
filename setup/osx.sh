#!/usr/bin/env bash

if hash brew 2>/dev/null; then
  echo "Homebrew is already installed!"
else
  echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  sudo chown -R $(whoami) /usr/local/bin

  echo
  echo "Adding brew to your PATH..."
  echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile
fi

echo
echo "Updating Homebrew..."
brew update

brew tap homebrew/cask
# brew tap homebrew/versions

if hash git 2>/dev/null; then
  echo "Git is already installed!"
else
  echo "Installing Git..."
  brew install git
fi

if hash VBoxManage 2>/dev/null; then
  echo "VirtualBox is already installed!"
else
  echo "Installing VirtualBox..."
  brew install --cask virtualbox
fi

if hash docker 2>/dev/null; then
  echo "Docker is already installed!"
else
  echo "Installing Docker for Mac..."
  brew install docker
fi

if hash kubectl 2>/dev/null; then
  echo "Kubectl is already installed!"
else
  echo "Installing kubectl..."
  brew install kubernetes-cli
fi

if hash minikube 2>/dev/null; then
  echo "Minikube is already installed!"
else
  echo "Installing minikube..."
  brew install minikube
fi

if hash terraform 2>/dev/null; then
  echo "Terraform is already installed!"
else
  echo "Installing terraform..."
  brew install terraform
fi

if hash helm 2>/dev/null; then
  echo "Helm is already installed!"
else
  echo "Installing Helm..."
  brew install kubernetes-helm
fi

if hash gcloud 2>/dev/null; then
  echo "Google Cloud SDK is already installed!"
else
  echo "Installing Google Cloud SDK..."
  brew install --cask google-cloud-sdk
fi
