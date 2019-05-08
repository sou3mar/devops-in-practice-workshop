# Exercise 12 - Extending the Deployment Pipeline

## Goals

* Extend the pipeline to deploy the application to GKE

## Acceptance Criteria

* Update the `deploy.sh` script to pass the image tag version from the
`$GO_PIPELINE_LABEL` environment variable
* Configure a new Elastic Agent Profile that can execute `kubectl` commands
* Add a new "deploy" stage to the "PetClinic" pipeline, with a single "deploy"
job that will configure `kubectl` to authenticate to GKE and execute the
`deploy.sh` script

## Step by Step Instructions

First, let's update our `deploy.sh` script to deploy to the default namespace
and overwrite the docker image spec when the `$GO_PIPELINE_LABEL` environment
variable is present. We will also use the `$GCLOUD_PROJECT_ID` variable when
present (you can change the default value to match your Project ID when running
locally):

```bash
#!/usr/bin/env bash
set -xe

echo "Deploying pet-db..."
kubectl apply -f kubernetes/mysql.yml --namespace default

IMAGE_VERSION=${GO_PIPELINE_LABEL:-latest}
PROJECT_ID=${GCLOUD_PROJECT_ID:-devops-workshop-123}
echo "Deploying pet-web image version: $IMAGE_VERSION"

cat kubernetes/web.yml | sed "s/\(image: \).*$/\1us.gcr.io\/$PROJECT_ID\/pet-app:$IMAGE_VERSION/" | kubectl apply -f - --namespace default
```

Now let's configure a new Elastic Agent Profile in GoCD by visiting the "ADMIN"
menu and clicking on "Elastic Profiles". We can then "+ Elastic Agent Profile"
with the following configuration:

* Id: `kubectl`
* Select the "Config Properties" option
* Image: `dtsato/gocd-agent-docker-dind-gcloud-kubectl:v19.3.0`
* Privileged: checked

Once the profile is saved, we can configure the new stage of our pipeline, by
going to the "ADMIN" menu, clicking "Pipelines", and opening the "PetClinic"
pipeline. Opening the "Stages" tab, we can create the new stage with the
following configuration (again adding a line break after the `-c` argument):

* Stage name: `deploy`
* Initial job name: `deploy`
* Task type: "More..."
* Command: `bash`
* Arguments: `-c echo $GCLOUD_SERVICE_KEY | base64 -d > secret.json && chmod 600 secret.json`

Once again, we will need to configure the environment variables for the new
`deploy` job:

* Environment Variables:
  * `GCLOUD_CLUSTER=devops-workshop-gke`
  * `GCLOUD_ZONE=us-central1-a`
  * `GCLOUD_PROJECT_ID=devops-workshop-123`
* Secure Variables:
  * `GCLOUD_SERVICE_KEY=[...]`

Remember to replace the project ID and the `GCLOUD_SERVICE_KEY` variables with
the same values used previously. We also need to go to the "Job Settings" tab
and configure the Elastic Profile Id to `kubectl`.

We can go back to the "Tasks" tab and add the other tasks:

* Activate service account:
  * Command: `bash`
  * Arguments: `-c gcloud auth activate-service-account --key-file secret.json`
* Configure kubectl to connect to GKE:
  * Command: `bash`
  * Arguments: `-c gcloud container clusters get-credentials $GCLOUD_CLUSTER --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_ID`
* Deploy:
  * Command: `./deploy.sh`
* Cleanup:
  * Command: `bash`
  * Arguments: `-c rm secret.json`

Now, when you commit and push your changes to the `deploy.sh` script, GoCD will
pick up the change in the Git repository and trigger a new run of the pipeline,
which should succeed both the `commit` and `deploy` stage. If you want to verify
that the changes are applied to the application, you can include in your commit
a change to the web UI as well, in order to verify that the change was
propagated all the way to production.
