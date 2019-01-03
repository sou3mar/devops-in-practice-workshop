#!/usr/bin/env python
from gomatic import *
import os, re

print "Updating PetClinic Pipeline..."
go_server_host = re.search('https?://([a-z0-9.\-._~%]+)', os.environ['GO_SERVER_URL']).group(1)
go_server_url = "%s:%s" % (go_server_host, "8153")
configurator = GoCdConfigurator(HostRestClient(go_server_url))
pipeline = configurator\
	.ensure_pipeline_group("sample")\
	.ensure_replacement_of_pipeline("PetClinic")\
	.set_git_material(GitMaterial("https://github.com/dtsato/devops-in-practice-workshop.git", branch="tw-jan-19", ignore_patterns=set(['pipelines/*'])))\
    .ensure_environment_variables({'GCLOUD_PROJECT_ID': 'devops-workshop-123'})\
    .ensure_encrypted_environment_variables({'GCLOUD_SERVICE_KEY': 'AES:v7ui/vIk5/WqCCSvgtMnXQ==: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'})
stage = pipeline.ensure_stage("commit")
job = stage.ensure_job("build-and-publish")\
    .ensure_environment_variables({'MAVEN_OPTS': '-Xmx1024m'})\
    .set_elastic_profile_id("docker-jdk")
job.add_task(ExecTask(['./mvnw', 'clean package']))
job.add_task(ExecTask(['bash', '-c', 'docker build --tag pet-app:$GO_PIPELINE_LABEL --build-arg JAR_FILE=target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar .']))
job.add_task(ExecTask(['bash', '-c', 'docker login -u _json_key -p"$(echo $GCLOUD_SERVICE_KEY | base64 -d)" https://us.gcr.io']))
job.add_task(ExecTask(['bash', '-c', 'docker tag pet-app:$GO_PIPELINE_LABEL us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL']))
job.add_task(ExecTask(['bash', '-c', 'docker push us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL']))
stage = pipeline.ensure_stage("deploy").ensure_environment_variables({'GCLOUD_ZONE': 'us-central1-a', 'GCLOUD_CLUSTER': 'devops-workshop-gke'})
job = stage.ensure_job("deploy").set_elastic_profile_id("kubectl")
job.add_task(ExecTask(['bash', '-c', 'echo $GCLOUD_SERVICE_KEY | base64 -d > secret.json && chmod 600 secret.json']))
job.add_task(ExecTask(['bash', '-c', 'gcloud auth activate-service-account --key-file secret.json']))
job.add_task(ExecTask(['bash', '-c', 'gcloud container clusters get-credentials $GCLOUD_CLUSTER --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_ID']))
job.add_task(ExecTask(['./deploy.sh']))
job.add_task(ExecTask(['bash', '-c', 'rm secret.json']))
stage = pipeline.ensure_stage("approve-canary")
stage.set_has_manual_approval()
job = stage\
	.ensure_job("complete-canary")\
    .ensure_environment_variables({'GCLOUD_ZONE': 'us-central1-a', 'GCLOUD_CLUSTER': 'devops-workshop-gke'})
job.set_elastic_profile_id('kubectl')
job.add_task(ExecTask(['bash', '-c', 'echo $GCLOUD_SERVICE_KEY | base64 -d > secret.json && chmod 600 secret.json']))
job.add_task(ExecTask(['bash', '-c', 'gcloud auth activate-service-account --key-file secret.json']))
job.add_task(ExecTask(['bash', '-c', 'gcloud container clusters get-credentials $GCLOUD_CLUSTER --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_ID']))
job.add_task(ExecTask(['bash', '-c', './complete-canary.sh']))
job.add_task(ExecTask(['bash', '-c', 'rm secret.json']))

configurator.save_updated_config()
