# Exercise 10 - Deploying to the Cloud

## Goals

* Learn about Google Container Registry (GCR)
* Re-deploying our application to the cloud

## Acceptance Criteria

* Configure Docker to use `gcloud` as a Container Registry credential helper
* Publish the `pet-web` Docker image to Google Container Registry using the
`docker push` command
* Re-create the MySQL password secret in GKE cluster
* Re-deploy entire application to GKE cluster

## Step by Step Instructions

First, let's configure `gcloud` as a credential helper in Docker:

```shell
$ gcloud auth configure-docker
The following settings will be added to your Docker config file
located at [/Users/dsato/.docker/config.json]:
 {
  "credHelpers": {
    "gcr.io": "gcloud",
    "us.gcr.io": "gcloud",
    "eu.gcr.io": "gcloud",
    "asia.gcr.io": "gcloud",
    "staging-k8s.gcr.io": "gcloud"
  }
}

Do you want to continue (Y/n)?  Y

Docker configuration file updated.
```

Since we stopped our local minikube cluster, we can reconfigure Docker to use
our local Docker host, by running:

```shell
$ unset $(env | grep DOCKER_ | cut -d'=' -f1)
```

**NOTE: If you are on Windows, or using `docker-machine`, run this command
instead:**

```shell
$ eval $(docker-machine env default)
```

Now we can tag and push our local `pet-web` Docker image to GCR in the US region
using the `docker tag` and `docker push` commands. Don't forget to replace the
value of the project ID with your own:

```shell
$ docker tag pet-app us.gcr.io/devops-workshop-123/pet-app:latest
$ docker push us.gcr.io/devops-workshop-123/pet-app
The push refers to repository [us.gcr.io/devops-workshop-123/pet-app]
b2327ded0b8e: Pushed
685fdd7e6770: Layer already exists
c9b26f41504c: Layer already exists
cd7100a72410: Layer already exists
latest: digest: sha256:ac317e98ec1bee6680b888ec2de907264493ce78567a72d0de7e98aa0aa411da size: 1159
```

Now we can test that the docker image was published to Google Container Registry
using the `gcloud` command:

```shell
$ gcloud container images list-tags us.gcr.io/devops-workshop-123/pet-app
DIGEST        TAGS    TIMESTAMP
ac317e98ec1b  latest  2018-04-05T21:39:18
```

Now let's re-create the MySQL password as a secret in GKE:

```shell
$ kubectl create secret generic mysql-pass --from-literal password=S3cr3t
secret "mysql-pass" created
$ kubectl get secrets
NAME                  TYPE                                  DATA      AGE
default-token-z9bfd   kubernetes.io/service-account-token   3         23m
mysql-pass            Opaque                                1         9s
```

Before we can re-deploy, we need to make a few updates to our Kubernetes
definition files to run on GKE. First, let's add an argument to ignore the
`lost+found` dir in the container spec for the MySQL pod definition under
`kubernetes/mysql.yml`:

```yaml
...
spec:
  containers:
  - image: mysql:5.7
    name: mysql
    args:
     - "--ignore-db-dir=lost+found"
...
```

Then we need to update the container spec for the web application to pull the
image from GCR, by updating the pod definition under `kubernetes/web.yml` to
include the GCR URL (replacing your project ID) and changing the `imagePullPolicy`
configuration:

```yaml
...
spec:
  containers:
  - image: us.gcr.io/devops-workshop-123/pet-app:latest
    imagePullPolicy: IfNotPresent
    name: pet-web
...
```

Now let's re-deploy our application stack:

```shell
$ ./deploy.sh
+ kubectl apply -f kubernetes/mysql.yml
service "pet-db" created
persistentvolumeclaim "db-pv-claim" created
deployment "pet-db" created
+ kubectl apply -f kubernetes/web.yml
service "pet-web" created
deployment "pet-web" created
```

Once the deployment is complete we can test that the Kubernetes pods and
services are available:

```shell
$ kubectl get pods
NAME                       READY     STATUS    RESTARTS   AGE
pet-db-6d5697cdbd-jgstp    1/1       Running   0          1h
pet-web-68c4fffc48-j28mq   1/1       Running   0          1m
$ kubectl get services
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)          AGE
kubernetes   ClusterIP      10.27.240.1    <none>         443/TCP          2h
pet-db       ClusterIP      10.27.241.43   <none>         3306/TCP         1h
pet-web      LoadBalancer   10.27.250.13   35.193.31.79   8080:31145/TCP   1h
```

From the `pet-web` service information we can see the external IP and port to
access our application and test it on a browser by accessing, in this case,
http://35.193.31.79:8080
