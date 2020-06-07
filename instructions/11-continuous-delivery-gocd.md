# Exercise 11 - Continuous Delivery with GoCD

## Goals

* Learn about Continuous Delivery and GoCD
* Learn about Helm and Charts
* Learn about Kubernetes namespaces
* Setup a CI/CD infrastructure using GoCD in our Kubernetes cluster
* Learn about the deployment pipeline and creating its first stage

## Acceptance Criteria

* Initialize helm to deploy charts to our GKE cluster
* Install and configure GoCD chart to use elastic agents
* Create the "PetClinic" pipeline, with a single "commit" stage containing a
single "build-and-publish" job that will compile, test, package the `jar`, build
a docker image, and publish it to GCR

## Step by Step Instructions

First, let's update Helm's repository using `helm repo update`:

```shell
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

Now let's search for the GoCD chart and find out details about it using the
`helm repo search` and `helm show` commands:

```shell
$ helm search repo -l gocd
NAME       	CHART VERSION	APP VERSION	DESCRIPTION                                       
stable/gocd	1.27.0       	20.4.0     	GoCD is an open-source continuous delivery serv...
stable/gocd	1.26.1       	20.3.0     	GoCD is an open-source continuous delivery serv...
stable/gocd	1.26.0       	20.3.0     	GoCD is an open-source continuous delivery serv...

...
$ helm show chart stable/gocd --version 1.27.0
apiVersion: v1
appVersion: 20.4.0
description: GoCD is an open-source continuous delivery server to model and visualize
  complex workflows with ease.
home: https://www.gocd.org/
icon: https://gocd.github.io/assets/images/go-icon-black-192x192.png
keywords:

...
```

Now we can install the GoCD chart on a `gocd` namespace by creating a namespace
and running the `helm install` command:

```shell
$ kubectl create ns gocd
namespace/gocd created
$ helm install gocd-app --namespace gocd --version 1.27.0 stable/gocd
NAME: gocd-app
LAST DEPLOYED: Fri Jun  5 22:46:57 2020
NAMESPACE: gocd
STATUS: deployed
REVISION: 1

...
```

The creation of the GoCD infrastructure can take several minutes. To check that
the deployments completed, you can use the `kubectl` command:

```shell
$ kubectl get deployments --namespace gocd
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
gocd-app-agent    0/0     0            0           66s
gocd-app-server   0/1     1            0           66s
```

Then you can fetch the external URL to the GoCD Server by running:

```shell
$ kubectl get ingress gocd-app-server --namespace=gocd
NAME              HOSTS     ADDRESS         PORTS     AGE
gocd-app-server   *         35.190.56.218   80        13m
```

After the GoCD infrastructure is up, you can access it in the browser using the
external IP above - in this case http://35.190.56.218.

GoCD comes configured with a sample "Hello World" pipeline. For our pipeline, we
need to create an Elastic Agent profile that will be used to launch jobs in our
pipeline. Click on the "ADMIN" tab and select "Elastic Agent Configurations",
then click the "+ Elastic Agent Profile" button and set the following
configuration:

* Elastic Profile Name: `docker-jdk`
* Select the "Config Properties" option
* Image: `dtsato/gocd-agent-docker-dind-jdk:v20.4.0`
* Maximum Memory: `1G`
* Privileged: check

Then click "Save".

Now we can create our application pipeline! Clicking on the "ADMIN" tab and
selecting "Pipelines" takes us to the pipeline admin screen. Clicking on "+ Add
new pipeline" will take us to the pipeline creation wizard.

In Part 1, we will configure our material type to use a "Git" repository, point
it to your Github repository URL and branch - in this case
https://github.com/dtsato/devops-in-practice-workshop.git and `master`. You can
test the connection is configured properly by clicking the "Test Connection"
button. In Part 2, we will provide the name "PetClinic".

In Parts 3 and 4, let's configure the stages and jobs of this pipeline. We'll
start with a `commit` stage, with an initial job called `build-and-publish`.
For tasks, we can type the following commands in the prompt, which will define
one task for each line (without the leading `$` character):

```bash
$ ./mvnw clean package
$ bash -c "docker build --tag pet-app:$GO_PIPELINE_LABEL --build-arg JAR_FILE=target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar ."
$ bash -c "docker login -u _json_key -p\"$(echo $GCLOUD_SERVICE_KEY | base64 -d)\" https://us.gcr.io"
$ bash -c "docker tag pet-app:$GO_PIPELINE_LABEL us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL"
$ bash -c "docker push us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL"
```

You might have noticed that we are referencing a few environment variables in
our tasks. `$GO_PIPELINE_LABEL` is defined by GoCD as a unique number for every
time the pipeline executes. The other variables we need to define by expanding
the "Advanced Settings" and creating the following (replace with your
project ID):

* Plain Text Variables:
  * `MAVEN_OPTS=-Xmx1024m`
  * `GCLOUD_PROJECT_ID=devops-workshop-123`
* Secure Variables:
  * `GCLOUD_SERVICE_KEY=[...]`

Replace the project ID, and for the `GCLOUD_SERVICE_KEY` use the output we saved
from Exercise 9 (Terraform apply).

After we click "Save + Edit Full Config", expand the `build-and-publish` job,
click on the "Job Settings" tab and configure the Elastic Agent Profile Id field
to use the `docker-jdk` profile. Then click the "SAVE" button.

Before we can test our pipeline, make sure you commit and push all your local
changes to your GitHub repository:

```shell
$ git add -A .
$ git commit -m"Initial commit for pipeline"
$ git push origin master
```

Then we can test executing our pipeline by un-pausing it.
