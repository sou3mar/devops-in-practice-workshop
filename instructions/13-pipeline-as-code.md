# Exercise 13 - Pipeline as Code

## Goals

* Learn about Pipeline as Code
* Learn about GoCD YAML Config Plugin
* Learn about GoCD Environments
* Move PetClinic pipeline definition to YAML

## Acceptance Criteria

* Pipeline configuration should be placed under a new `PetClinic.gocd.yaml` file
at the root of the project
* Exclude the `PetClinic.gocd.yaml` file as a trigger to the "PetClinic" pipeline
* Setup a new Configuration Repo using the YAML Config Plugin
* Export the current pipeline configuration to YAML and move to the repository
* Extract the common environment variables and secret variables to a new `gcp`
GoCD environment
* Display test results and artifacts on job "Tests" tab

## Step by Step Instructions

### Extracting and configuring the PetClinic Pipeline as Code

First, let's export the current configuration to the YAML configuration format.
Click on the "ADMIN" menu and select "Pipelines". Click on "Export using" for
"PetClinc" pipeline and select the "YAML Configuration Plugin" option.
tab. This will download a file called `PetClinic.gocd.yaml`, that you can move
to the root of the project.

Fix some of the formatting on the file to make sure all the tasks are defined in
a single line. Also update the `format_version` to version `4`.

In order to use this file, we need to create a new Configuration Repository,
that will poll for changes and update the pipeline definitions when the YAML
file changes. Click on the "ADMIN" menu and select "Config Repositories". Click
the "Add" button and create the new configuration repository:

* Plugin ID: `YAML Configuration Plugin`
* Material type: `Git`
* Config repository ID: `sample`
* URL: Same as before, use the Git URL for your repository
* Branch: `master`

Once again, you can test by clicking on "Test Connection" before proceeding
with clicking "Save".

Now we can commit and push our changes to introduce the `PetClinic.gocd.yaml`
pipeline configuration file and it should be picked up by the YAML configuration
plugin.

When it first executes, you will see an error because the `PetClinic` pipeline
already exists. In order for GoCD to use the YAML definition, we need to delete
the existing pipeline. Don't worry, once the YAML plugin re-scans the repo, it
will recreate our pipeline. Click on the "ADMIN" menu and select "Pipelines".
Click the "Delete" link and on the "Proceed" button to confirm the pipeline
deletion.

Now wait for the YAML Config Plugin to re-scan the repository and recreate our
pipeline.

### Improving the PetClinic pipeline

Now, to test that the pipeline configuration is really defined in code, on the
`PetClinic.gocd.yaml` file, let's make a few changes to improve it. First, let's
configure our `build-and-publish` job, to collect and publish the test report
artifacts from surefire, by adding the `artifacts` section:

```yaml
...
jobs:
  build-and-publish:
    timeout: 0
    environment_variables:
      MAVEN_OPTS: -Xmx1024m
      GCLOUD_PROJECT_ID: devops-workshop-123
    secure_variables:
      GCLOUD_SERVICE_KEY: AES:kb7KQ/gJ1VTtYGU6SLUJjA==...
    elastic_profile_id: docker-jdk
    artifacts:
      - test:
          source: target/surefire-reports
    tasks:
...
```

Also, let's extract the common environment variables and secret variables
configuration to a new [GoCD Environment](https://docs.gocd.org/current/navigation/environments_page.html)
by adding the following section to the beginning of the `PetClinic.gocd.yaml`
file, copying the values of the variables from one of the stages/jobs
(make sure the `GCLOUD_PROJECT_ID` and `GCLOUD_SERVICE_KEY` are yours):

```yaml
format_version: 4
environments:
  gcp:
    environment_variables:
      GCLOUD_CLUSTER: devops-workshop-gke
      GCLOUD_ZONE: us-central1-a
      GCLOUD_PROJECT_ID: devops-workshop-123
    secure_variables:
      GCLOUD_SERVICE_KEY: AES:kb7KQ/gJ1VTtYGU6SLUJjA==...
    pipelines:
      - PetClinic
...
```

Also, make sure to remove those common environment variables and secret
variables from the stages and jobs to avoid the duplication.

Once again, when you commit and push these changes, the YAML configuration
plugin should pick up the changes and trigger a new pipeline execution, where
you can check that the test results are now available after a successful
pipeline run.
