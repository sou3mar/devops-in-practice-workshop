#!/usr/bin/env bash
set +e

PROJECT_ID=${GCLOUD_PROJECT_ID:-devops-workshop-123}

function deleteGlobalResource {
  RESOURCE=$1
  for id in $(gcloud compute $RESOURCE list --global --project=$PROJECT_ID --format='get(name)'); do
    gcloud compute $RESOURCE delete $id --global -q
  done
}

function deleteRegionalResource {
  RESOURCE=$1
  REGION=$2
  for id in $(gcloud compute $RESOURCE list --filter='region:($REGION)' --project=$PROJECT_ID --format='get(name)'); do
    gcloud compute $RESOURCE delete $id --region $REGION -q
  done
}

function deleteResource {
  RESOURCE=$1
  for id in $(gcloud compute $RESOURCE list --project=$PROJECT_ID --format='get(name)'); do
    gcloud compute $RESOURCE delete $id -q
  done
}

function deleteServiceAccount {
  ACCOUNT=$1
  ROLES="roles/storage.admin roles/container.admin"
  for role in $ROLES; do
    gcloud projects remove-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com --role ${role} -q
  done
  gcloud iam service-accounts delete ${ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com -q
}

function deleteContainerImages {
  APP=$1
  for image in $(gcloud container images list-tags us.gcr.io/${PROJECT_ID}/${APP} --format='get(digest)'); do
    gcloud container images delete --force-delete-tags -q us.gcr.io/${PROJECT_ID}/${APP}@${image}
  done
}

function deleteDisks {
  for id_and_zone in $(gcloud compute disks list --project=$PROJECT_ID --format='csv[no-heading](name,zone.basename())'); do
    id=$(echo $id_and_zone | cut -d',' -f1)
    zone=$(echo $id_and_zone | cut -d',' -f2)
    gcloud compute disks delete $id --zone $zone -q
  done
}

function destroy {
  set -x
  deleteContainerImages "pet-app"
  deleteServiceAccount "gocd-agent"
  deleteGlobalResource "forwarding-rules"
  deleteRegionalResource "forwarding-rules" "us-central1"
  deleteResource "target-http-proxies"
  deleteResource "target-tcp-proxies"
  deleteResource "url-maps"
  deleteGlobalResource "backend-services"
  deleteRegionalResource "backend-services" "us-central1"
  deleteResource "health-checks"
  deleteRegionalResource "target-pools" "us-central1"
  deleteDisks
}

echo "*****************************************************************"
echo "* !!!!!!!!!!!!!!!!!!!!!!!!   WARNING   !!!!!!!!!!!!!!!!!!!!!!!! *"
echo "*****************************************************************"
echo "* This script will delete ALL cloud resources on the project:   *"
echo "* - $PROJECT_ID                                         *"
echo "*                                                               *"
echo "* Some error messages will be displayed if the resource doesn't *"
echo "* exist. Please ignore those.                                   *"
echo "*****************************************************************"

read -p "Continue (y/n)?" choice
case $choice in
  y|Y ) destroy;;
  * ) echo "Aborting.";;
esac
