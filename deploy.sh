#!/usr/bin/env bash
set -xe

echo "Deploying pet-db..."
kubectl apply -f kubernetes/mysql.yml --namespace default

IMAGE_VERSION=${GO_PIPELINE_LABEL:-latest}
PROJECT_ID=${GCLOUD_PROJECT_ID:-devops-workshop-123}
echo "Deploying pet-web image version: $IMAGE_VERSION"

cat kubernetes/web.yml | sed "s/\(image: \).*$/\1us.gcr.io\/$PROJECT_ID\/pet-app:$IMAGE_VERSION/" | kubectl apply -f - --namespace default
