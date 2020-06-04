#!/usr/bin/env powershell
#Requires -RunAsAdministrator

if (-Not (Test-Path -Path "$env:ProgramData\Chocolatey")) {
  Write-Output "Installing Chocolatey.."
  Set-ExecutionPolicy Bypass -Scope Process -Force;
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
  Write-Output 'Ensuring chocolatey commands are on the path'

  $chocoExePath = Join-Path "$env:ProgramData\Chocolatey" 'bin'

  if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
    $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine);
  }
}

if (Get-Command javac -ErrorAction SilentlyContinue) {
  Write-Output "Java is already installed!"
} else {
  choco install -y openjdk11
}

if (Get-Command VBoxManage -ErrorAction SilentlyContinue) {
  Write-Output "VirtuaBox is already installed!"
} else {
  choco install -y virtualbox
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
  Write-Output "Docker is already installed!"
} else {
  choco install -y docker-desktop
}

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
  Write-Output "Kubectl is already installed!"
} else {
  choco install -y kubernetes-cli
}

if (Get-Command minikube -ErrorAction SilentlyContinue) {
  Write-Output "Minikube is already installed!"
} else {
  choco install -y minikube
}

if (Get-Command terraform -ErrorAction SilentlyContinue) {
  Write-Output "Terraform is already installed!"
} else {
  choco install -y terraform
}

if (Get-Command helm -ErrorAction SilentlyContinue) {
  Write-Output "Helm is already installed!"
} else {
  choco install -y kubernetes-helm
}

if (Get-Command gcloud -ErrorAction SilentlyContinue) {
  Write-Output "Google Cloud SDK is already installed!"
} else {
  Write-Output "Installing Google Cloud SDK..."
  (New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
  Start-Process $env:Temp\GoogleCloudSDKInstaller.exe -ArgumentList "/S /allusers" -Wait -Verb RunAs
  Write-Output "OK"
}

Write-Output "Please restart your to ensure Docker installation completes and your PATH is updated"
