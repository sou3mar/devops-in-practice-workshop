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

First, let's initialize Helm using `helm init`, and update the repository using
`helm repo update`:

```shell
$ helm init
$HELM_HOME has been configured at /Users/dsato/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

Now let's search for the GoCD chart and find out details about it using the
`helm search` and `helm inspect` commands:

```shell
$ helm search -l gocd
NAME       	CHART VERSION	APP VERSION	DESCRIPTION                                                 
stable/gocd	1.9.1        	19.3.0     	GoCD is an open-source continuous delivery server to mode...
stable/gocd	1.9.0        	19.3.0     	GoCD is an open-source continuous delivery server to mode...
stable/gocd	1.8.1        	19.2.0     	GoCD is an open-source continuous delivery server to mode...

...
$ helm inspect stable/gocd --version 1.9.1
appVersion: 19.3.0
description: GoCD is an open-source continuous delivery server to model and visualize
  complex workflows with ease.
home: https://www.gocd.org/
icon: https://gocd.github.io/assets/images/go-icon-black-192x192.png
keywords:

...
```

In order to use Role-Based Access Control (RBAC), the GoCD chart requires us to
bind a service account with the `cluster-admin` role. We can bind it to the default
`kube-system` account by running:

```shell
$ kubectl create clusterrolebinding clusterRoleBinding --clusterrole=cluster-admin --serviceaccount=kube-system:default
clusterrolebinding "clusterRoleBinding" created
```

Now we can install the GoCD chart on a `gocd` namespace by running the `helm install`
command:

```shell
$ helm install --name gocd-app --namespace gocd --version 1.9.1 stable/gocd
NAME:   gocd-app
LAST DEPLOYED: Wed May  8 13:38:34 2019
NAMESPACE: gocd
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME            DATA  AGE
gocd-app        1     1s

...
```

The creation of the GoCD infrastructure can take several minutes. To check that
the deployments completed, you can use the `kubectl` command:

```shell
$ kubectl get deployments --namespace gocd
NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
gocd-app-agent    0         0         0            0           3m
gocd-app-server   1         1         1            1           3m
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
pipeline. Click on the "ADMIN" tab and select "Elastic Profiles", then
click the "+ Elastic Agent Profile" button and set the following configuration:

* Id: `docker-jdk`
* Select the "Config Properties" option
* Image: `dtsato/gocd-agent-docker-dind-jdk:v19.3.0`
* Privileged: check

Then click "Save".

Now we can create our application pipeline! Clicking on the "ADMIN" tab and
selecting "Pipelines" takes us to the pipeline admin screen. Clicking on "Create
a new pipeline within this group" will take us to the pipeline creation wizard.
We will provide the name "PetClinic" and click on "NEXT" to move to the next
page.

We will configure our material type to use a "Git" repository, point it to
your Github repository URL and branch - in this case
https://github.com/dtsato/devops-in-practice-workshop.git and `master`. You can
test the connection is configured properly by clicking the "CHECK CONNECTION"
button. If everything is OK, you can click "NEXT" to move to the final page.

Let's configure the stages and jobs of this pipeline. We'll start with a `commit`
stage, with an initial job called `build-and-publish` that will use our `docker-jdk`
Elastic Agent Profile. We will add an initial task of type "More..." which
allows us to setup the command and arguments below:

* Command: `./mvnw`
* Arguments: `clean package`

When we click "FINISH", we are taken to the pipeline admin page, which allows us
to add more jobs. Expanding the `build-and-publish` job and opening the "Tasks"
tab, we can click on "Add new task", select "More...", and configure it to build
and tag a Docker image (on all the bash command arguments, add a line break
between the `-c` option and the rest of the arguments):

* Command: `bash`
* Arguments: `-c docker build --tag pet-app:$GO_PIPELINE_LABEL --build-arg JAR_FILE=target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar .`

Then we can add another task to authenticate to Google Container Registry:

* Command: `bash`
* Arguments: `-c docker login -u _json_key -p"$(echo $GCLOUD_SERVICE_KEY | base64 -d)" https://us.gcr.io`

We need a task to tag the Docker image for publication:

* Command: `bash`
* Arguments: `-c docker tag pet-app:$GO_PIPELINE_LABEL us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL`

And finally we need a task to publish the Docker image to Google Container Registry:

* Command: `bash`
* Arguments: `-c docker push us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL`

You might have noticed that we are referencing a few environment variables in
our tasks. `$GO_PIPELINE_LABEL` is defined by GoCD as a unique number for every
time the pipeline executes. The other variables we need to define by going into
the "Environment Variables" tab and creating the following (replace with your
project ID):

* Environment Variables:
  * `MAVEN_OPTS=-Xmx1024m`
  * `GCLOUD_PROJECT_ID=devops-workshop-123`
* Secure Variables:
  * `GCLOUD_SERVICE_KEY=[...]`

Replace the project ID, and for the `GCLOUD_SERVICE_KEY` use the output we saved
from Exercise 9 (Terraform apply).

After we click "SAVE", go back to the "Job Settings" tab and configure the
Elastic Profile Id field to use the `docker-jdk` profile.

Before we can test our pipeline, make sure you commit and push all your local
changes to your GitHub repository:

```shell
$ git add -A .
$ git commit -m"Initial commit for pipeline"
$ git push origin master
```

Then we can test executing our pipeline by un-pausing it.
