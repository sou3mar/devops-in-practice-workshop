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
	.set_git_material(GitMaterial("https://github.com/dtsato/devops-in-practice-workshop.git", branch="tw-jan-19", ignore_patterns=set(['pipelines/*']), invert_filter="True"))
stage = pipeline.ensure_stage("update-pipelines")
job = stage.ensure_job("update-pipelines").set_elastic_profile_id("docker-jdk")
job.add_task(ExecTask(['pipelines/update.sh']))

configurator.save_updated_config()
