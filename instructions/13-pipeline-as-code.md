# Exercise 13 - Pipeline as Code

## Goals

* Learn about Pipeline as Code
* Learn about GoMatic
* Create a new pipeline for updating GoCD pipelines

## Acceptance Criteria

* Pipeline code should be placed under a new `pipelines` folder at the root of
the project
* Exclude the `pipelines` folder as a trigger to the "PetClinic" pipeline
* Create a new "Meta" pipeline triggered on changes to the `pipelines` folder
only, that executes the python scripts using GoMatic
* Use GoMatic locally to export the current pipeline configurations and convert
them into pipeline scripts

## Step by Step Instructions

### Creating placeholder scripts

First, let's create the folder and a few dummy scripts for each of the
pipelines, to serve as placeholder test scripts:

```shell
$ mkdir pipelines
$ echo "print \"Updating Meta Pipeline...\"" > pipelines/meta_pipeline.py
$ echo "print \"Updating PetClinic Pipeline...\"" > pipelines/pet_clinic_pipeline.py
```

Let's also create a `pipelines/update.sh` script that will be executed by the
meta pipeline to invoke the dummy scripts inside a Docker container with
Python and GoMatic:

```bash
#!/bin/bash
set -xe

CWD=$(cd $(dirname $0) && pwd)
for pipeline in $CWD/*.py; do
  docker run -i --rm -v "$CWD":/usr/src/meta -w /usr/src/meta -e GO_SERVER_URL=$GO_SERVER_URL dtsato/gomatic /bin/bash -c "python $(basename $pipeline)"
done
```

Make sure the new script is executable:

```shell
$ chmod a+x pipelines/update.sh
```

Now let's update the current "PetClinic" pipeline configuration to not trigger
when changes occur to the `pipelines` folder. Click on the "ADMIN" menu and select
"Pipelines". Click on "Edit" for "PetClinc" pipeline and go to the "Materials"
tab. Opening the Git material, add the following configuration to the Blacklist:

* Paths to be excluded: `pipelines/*`

Now we can commit and push our changes to introduce the placeholder scripts and
it should not trigger a pipeline execution.

### Creating the meta pipeline

From the "ADMIN" menu, select "Pipelines", and click on "Create a new pipeline
within this group". The first step will setup the pipeline name to "Meta" and
click "NEXT". Then on the next step, use the following configuration:

* Material Type: `Git`
* URL: Same as before, use the Git URL for your repository
* Branch: `master`
* Blacklist: `pipelines/*`
* Invert the file filter: Checked

Once again, you can test by clicking on "CHECK CONNECTION" before proceeding
with clicking "NEXT". In the final step, use the following configuration:

* Stage Name: `update-pipelines`
* Job Name: `update-pipelines`
* Task Type: `More...`
* Command: `pipelines/update.sh`

We can then click on "FINISH". Going back to the "Job Settings" tab, we can add
the `docker-jdk` Elastic Profile Id to ensure the agent will run. We can now
un-pause the pipeline and test that it runs successfully.

### Pipeline as code for Meta pipeline

Once the build succeeds, let's update the dummy script to setup the pipeline
based on its current state. GoMatic has a feature to export the current pipeline
configuration as code, so we can run this command locally, replacing the IP
address with your GoCD Server public IP from GKE:

```shell
$ docker run -i --rm dtsato/gomatic python -m gomatic.go_cd_configurator -s 35.190.56.218 -p Meta
#!/usr/bin/env python
from gomatic import *
...
```

You can see that at the end of the execution, there is some Python code that we
can copy and paste and use as the template for our pipeline configuration as code.
Paste it on the `pipelines/meta_pipeline.py` script and make a few tweaks:

```python
#!/usr/bin/env python
from gomatic import *
import os, re

print "Updating Meta Pipeline..."

go_server_host = re.search('https?://([a-z0-9.\-._~%]+)', os.environ['GO_SERVER_URL']).group(1)
go_server_url = "%s:%s" % (go_server_host, "8153")
configurator = GoCdConfigurator(HostRestClient(go_server_url))
pipeline = configurator\
	.ensure_pipeline_group("sample")\
	.ensure_replacement_of_pipeline("Meta")\
	.set_git_material(GitMaterial("https://github.com/dtsato/devops-in-practice-workshop.git", branch="master", ignore_patterns=set(['pipelines/*']), invert_filter="True"))
stage = pipeline.ensure_stage("update-pipelines")
job = stage.ensure_job("update-pipelines").set_elastic_profile_id('docker-jdk')
job.add_task(ExecTask(['pipelines/update.sh']))

configurator.save_updated_config()
```

We are adding some code to parse the GoCD Server URL from the environment
variable and removed the named arguments from the last line to actually save the
configuration, and not just do a dry-run.

Once you commit and push this code, the Meta pipeline should trigger again, and
this time the above code will invoke GoMatic.

### Pipeline as code for PetClinic pipeline

Finally, let's extract the pipeline configuration for the "PetClinic" pipeline,
by executing the same GoMatic command locally, changing the pipeline name and
using your GoCD Server URL:

```shell
$ docker run -i --rm dtsato/gomatic python -m gomatic.go_cd_configurator -s 35.190.56.218 -p PetClinic
#!/usr/bin/env python
from gomatic import *
...
```

At the end of the execution, you can once again copy and paste the Python code
into the `pipelines/pet_clinic_pipeline.py` script, and make the same tweaks:

```python
#!/usr/bin/env python
from gomatic import *
import os, re

print "Updating PetClinic Pipeline..."
go_server_host = re.search('https?://([a-z0-9.\-._~%]+)', os.environ['GO_SERVER_URL']).group(1)
go_server_url = "%s:%s" % (go_server_host, "8153")
configurator = GoCdConfigurator(HostRestClient(go_server_url))
secret_variables = {'GCLOUD_SERVICE_KEY': 'lKD+DoKDGtCsaToW...'}
pipeline = configurator\
	.ensure_pipeline_group("sample")\
	.ensure_replacement_of_pipeline("PetClinic")\
	.set_git_material(GitMaterial("https://github.com/dtsato/devops-in-practice-workshop.git", branch="master", ignore_patterns=set(['pipelines/*'])))
stage = pipeline.ensure_stage("commit")
job = stage\
    .ensure_job("build-and-publish")\
    .ensure_environment_variables({'MAVEN_OPTS': '-Xmx1024m', 'GCLOUD_PROJECT_ID': 'devops-workshop-123'})\
    .ensure_encrypted_environment_variables(secret_variables)
job.set_elastic_profile_id('docker-jdk')
job.add_task(ExecTask(['./mvnw', 'clean', 'package']))
job.add_task(ExecTask(['bash', '-c', 'docker build --tag pet-app:$GO_PIPELINE_LABEL --build-arg JAR_FILE=target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar .']))
job.add_task(ExecTask(['bash', '-c', 'docker login -u _json_key -p"$(echo $GCLOUD_SERVICE_KEY | base64 -d)" https://us.gcr.io']))
job.add_task(ExecTask(['bash', '-c', 'docker tag pet-app:$GO_PIPELINE_LABEL us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL']))
job.add_task(ExecTask(['bash', '-c', 'docker push us.gcr.io/$GCLOUD_PROJECT_ID/pet-app:$GO_PIPELINE_LABEL']))
stage = pipeline.ensure_stage("deploy")
job = stage\
    .ensure_job("deploy")\
    .ensure_environment_variables({'GCLOUD_ZONE': 'us-central1-a', 'GCLOUD_PROJECT_ID': 'devops-workshop-123', 'GCLOUD_CLUSTER': 'devops-workshop-gke'})\
    .ensure_encrypted_environment_variables(secret_variables)
job.set_elastic_profile_id('kubectl')
job.add_task(ExecTask(['bash', '-c', 'echo $GCLOUD_SERVICE_KEY | base64 -d > secret.json && chmod 600 secret.json']))
job.add_task(ExecTask(['bash', '-c', 'gcloud auth activate-service-account --key-file secret.json']))
job.add_task(ExecTask(['bash', '-c', 'gcloud container clusters get-credentials $GCLOUD_CLUSTER --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_ID']))
job.add_task(ExecTask(['bash', '-c', './deploy.sh']))
job.add_task(ExecTask(['bash', '-c', 'rm secret.json']))

configurator.save_updated_config()
```

Please note that we once again added some code to parse the GoCD Server URL, set
the Elastic Profile IDs for both jobs, and removed the arguments from the last
line. We also added an extra line to the `build-and-publish` job to collect the
test report artifacts from surefire. This allows us to test that the pipeline
configuration is getting updated after the Meta pipeline executes.

Once again, when you commit and push these changes, the "Meta" pipeline should
trigger and reconfigure the PetClinic pipeline.
