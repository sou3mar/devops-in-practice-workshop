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
