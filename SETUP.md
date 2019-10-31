# Pre-Workshop Setup

To follow along with the hands-on exercises, I recommend that you perform this
setup before the workshop, since it will require you to download and install
different tools, and that can be time-consuming and risky given unreliable wi-fi
connectivity.

## Installing Required Tools

These are the tools required for the workshop and the links for installation
instructions if you want to install them manually:

* [Java](https://java.com/en/download/) 11+
* [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [Docker](https://docs.docker.com/install/) 18+
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) 1.9.4+
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) 5.2+
* [Install minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
0.30.0+
* [helm](https://github.com/kubernetes/helm/blob/master/docs/install.md) 2.8+
* [terraform](https://www.terraform.io/intro/getting-started/install.html) 0.11+
* [Google Cloud SDK tools](https://cloud.google.com/sdk/downloads) 196+

### Auto-Install on Mac OS X

You can run the [`setup-workstation.sh`](./setup-workstation.sh) script to
install the required tools using [HomeBrew](https://brew.sh/). After installing,
if you didn't use HomeBrew before, you will probably need to restart your
shell to add the path to the binaries to your `PATH`.

Then you can continue to the
[Google Cloud Platform Account Setup](#google-cloud-platform-account-setup)
section.

### Auto-Install on Windows

*(This was tested on Windows 10)*

I recommend installing [Git for Windows](https://gitforwindows.org), and use the
Git Bash application for cloning the repository, executing the setup script, and
going through the exercises of this workshop.

Once installed, right-click the "Git Bash" icon on your desktop and select
"Run as administrator", then click "Yes" on the popup that appears. Now you can
clone de repository and you can execute the
[`./setup-workstation.sh`](./setup-workstation.sh) script to install the
required tools using [Chocolatey](https://chocolatey.org). After installation,
you will need to restart your shell to add the path to the binaries to your
`PATH`.

Note: this setup will install Docker Toolbox, which allows running Docker on
Windows using Docker-Machine on a VirtualBox VM. This requires virtualization
features to be enabled. Once the install script completes and you restart your
shell, run the following command to create the `docker-machine` VM:

```shell
$ docker-machine create -d virtualbox default
Creating CA: C:\Users\Danilo\.docker\machine\certs\ca.pem
Creating client certificate: C:\Users\Danilo\.docker\machine\certs\cert.pem
Running pre-create checks...

...

Docker is up and running!
```

Once the docker-machine is running, run the following command to setup the
docker CLI client:

```shell
$ eval $(docker-machine env default)
```

Then you can continue to the
[Google Cloud Platform Account Setup](#google-cloud-platform-account-setup)
section.

### Auto-Install on Linux

*(This was tested on Ubuntu trusty and CentOS 7)*

You can run the [`setup-workstation.sh`](./setup-workstation.sh) script to
install the required tools. Make sure you run it as `root`:

```shell
$ sudo ./setup-workstation.sh
```

On CentOS 7, you need to start the Docker service:

```shell
$ sudo service docker start
```

Then you can continue to the
[Google Cloud Platform Account Setup](#google-cloud-platform-account-setup)
section.

## Google Cloud Platform Account Setup

You will need a working Google Cloud Platform account for the second half of the
workshop.

If you don't have one already, you can sign-up for a Google Cloud Platform
[free 12 months trial](https://cloud.google.com/free/). Once you sign-up, you
can create a project for the workshop and name it "DevOps Workshop".

## Download large files

1. **Docker Images**: download the following Docker images by running (use
  `sudo` on Linux):
  * `docker pull openjdk:11-oracle`
  * `docker pull mysql:5.7`
2. **Maven Dependencies**: have Maven download all dependencies by running:
  * `./mvnw clean install`
3. **Minikube VM**: ensure you have the minikube VirtualBox VM image by running:
  * `minikube start --kubernetes-version v1.12.7 --memory 2048`
  * `minikube stop`
