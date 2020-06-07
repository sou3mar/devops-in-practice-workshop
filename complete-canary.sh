#!/usr/bin/env bash
set -xe

echo "Completing canary release of pet-db..."

IMAGE_VERSION=${GO_PIPELINE_LABEL:-latest}
PROJECT_ID=${GCLOUD_PROJECT_ID:-devops-workshop-123}
CURRENT_VERSION=$(kubectl get deployment pet-web --namespace default -o jsonpath="{..image}" | cut -d':' -f2)
echo "Updating pet-web deployment from version $CURRENT_VERSION to $IMAGE_VERSION"

cat kubernetes/web.yml | sed "s/\(image: \).*$/\1us.gcr.io\/$PROJECT_ID\/pet-app:$IMAGE_VERSION/" | kubectl apply -f - --namespace default
