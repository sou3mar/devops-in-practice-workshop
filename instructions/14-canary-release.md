# Exercise 14 - Canary Release

## Goals

* Learn about Canary Release
* Learn about GoCD manual workflows

## Acceptance Criteria

* Create a `web-canary.yml` kubernetes definition to implement canary releases
* Update the `deploy.sh` script to deploy the canary release only
* Create a `complete-canary.sh` script to complete the canary release rollout
* Extend the PetClinic pipeline to add a new stage with a manual
approval to complete the canary release using the above scripts

## Step by Step Instructions

First, let's create a new `kubernetes/web-canary.yml` file with a deployment
definition similar to the `kubernetes/web.yml` but with a new name and an extra
label `track` with value `canary`:

```yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: pet-web-canary
  labels:
    app: pet
spec:
  selector:
    matchLabels:
      app: pet
      tier: frontend
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: pet
        tier: frontend
        track: canary
    spec:
      containers:
      - image: us.gcr.io/devops-workshop-123/pet-app
        imagePullPolicy: IfNotPresent
        name: pet-web
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: mysql
        - name: PET_DB_DATABASE
          value: petclinic
        - name: PET_DB_USER
          value: petclinic-user
        - name: PET_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 8080
          name: pet-web
        livenessProbe:
          httpGet:
            path: /manage/health
            port: pet-web
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /manage/health
            port: pet-web
          initialDelaySeconds: 30
```

Let's also update the `kubernetes/web.yml` definition to include the label
`track` with value `stable`:

```yaml
...
template:
  metadata:
    labels:
      app: pet
      tier: frontend
      track: stable
...
```

Now we can update our `deploy.sh` script to fetch the current version and keep
it as the stable deploy, but use the new image as the canary release with a new
deployment:

```bash
#!/usr/bin/env bash
set -xe

echo "Deploying pet-db..."
kubectl apply -f kubernetes/mysql.yml --namespace default

IMAGE_VERSION=${GO_PIPELINE_LABEL:-latest}
PROJECT_ID=${GCLOUD_PROJECT_ID:-devops-workshop-123}
CURRENT_VERSION=$(kubectl get deployment pet-web --namespace default -o jsonpath="{..image}" | cut -d':' -f2)
echo "Current version: $CURRENT_VERSION"
echo "Deploying pet-web canary image version: $IMAGE_VERSION"

cat kubernetes/web.yml | sed "s/\(image: \).*$/\1us.gcr.io\/$PROJECT_ID\/pet-app:$CURRENT_VERSION/" | kubectl apply -f - --namespace default
cat kubernetes/web-canary.yml | sed "s/\(image: \).*$/\1us.gcr.io\/$PROJECT_ID\/pet-app:$IMAGE_VERSION/" | kubectl apply -f - --namespace default
```

Now let's create a new `complete-canary.sh` script that will be invoked manually
from our pipeline, when we decide to complete the canary rollout:

```bash
#!/usr/bin/env bash
set -xe

echo "Completing canary release of pet-db..."

IMAGE_VERSION=${GO_PIPELINE_LABEL:-latest}
PROJECT_ID=${GCLOUD_PROJECT_ID:-devops-workshop-123}
CURRENT_VERSION=$(kubectl get deployment pet-web --namespace default -o jsonpath="{..image}" | cut -d':' -f2)
echo "Updating pet-web deployment from version $CURRENT_VERSION to $IMAGE_VERSION"

cat kubernetes/web.yml | sed "s/\(image: \).*$/\1us.gcr.io\/$PROJECT_ID\/pet-app:$IMAGE_VERSION/" | kubectl apply -f - --namespace default
```

Don't forget to make the script executable:

```shell
$ chmod a+x complete-canary.sh
```

Finally, we can update our `PetClinic.gocd.yaml` pipeline configuration file to
add a new manual stage and job to execute the `complete_canary.sh` script, after
the definition of the `deploy` stage:

```yaml
...

- approve-canary:
    fetch_materials: true
    keep_artifacts: false
    clean_workspace: false
    approval:
      type: manual
    jobs:
      complete-canary:
        timeout: 0
        elastic_profile_id: kubectl
        tasks:
        - exec:
            arguments:
            - -c
            - echo $GCLOUD_SERVICE_KEY | base64 -d > secret.json && chmod 600 secret.json
            command: bash
            run_if: passed
        - exec:
            arguments:
            - -c
            - gcloud auth activate-service-account --key-file secret.json
            command: bash
            run_if: passed
        - exec:
            arguments:
            - -c
            - gcloud container clusters get-credentials $GCLOUD_CLUSTER --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_ID
            command: bash
            run_if: passed
        - exec:
            command: ./complete-canary.sh
            run_if: passed
        - exec:
            arguments:
            - -c
            - rm secret.json
            command: bash
            run_if: passed
```

Commit and push the changes and wait until GoCD is updated. Once the pipeline is
updated with the new stage, it will trigger a new execution.You should see it
deploy the new version as a canary release. Then you can test a manual approval
to complete the release.
