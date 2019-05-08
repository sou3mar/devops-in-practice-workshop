# Exercise 15 - Cleanup

## Goals

* Ensure all cloud resources are disposed

## Acceptance Criteria

* Use terraform to teardown the GKE infrastructure

## Step by Step Instructions

Since all our infrastructure was deployed to GKE, we can use the `terraform
destroy` command to cleanup everything and ensure we're not paying for unused
cloud resources:

```shell
$ terraform destroy terraform/

Warning: google_container_cluster.cluster: "additional_zones": [DEPRECATED] Use node_locations instead

Warning: google_container_cluster.cluster: "zone": [DEPRECATED] Use location instead

google_service_account.gocd_agent_svc_account: Refreshing state... (ID: projects/devops-workshop-123/serviceAcc...s-workshop-123.iam.gserviceaccount.com)
google_container_cluster.cluster: Refreshing state... (ID: devops-workshop-gke)
google_service_account_key.gocd_agent_svc_account_key: Refreshing state... (ID: projects/devops-workshop-123/serviceAcc...d821c6999a88bb14f898a78c5a2992fb675add)
google_storage_bucket_iam_binding.gocd_agent_account_registry_iam: Refreshing state... (ID: us.artifacts.devops-workshop-123.appspot.com/roles/storage.admin)
google_project_iam_binding.gocd_agent_account_container_iam: Refreshing state... (ID: devops-workshop-123/roles/container.admin)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  - google_container_cluster.cluster

  - google_project_iam_binding.gocd_agent_account_container_iam

  - google_service_account.gocd_agent_svc_account

  - google_service_account_key.gocd_agent_svc_account_key

  - google_storage_bucket_iam_binding.gocd_agent_account_registry_iam


Plan: 0 to add, 0 to change, 5 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

google_storage_bucket_iam_binding.gocd_agent_account_registry_iam: Destroying... (ID: us.artifacts.devops-workshop-123.appspot.com/roles/storage.admin)
google_container_cluster.cluster: Destroying... (ID: devops-workshop-gke)
google_service_account_key.gocd_agent_svc_account_key: Destroying... (ID: projects/devops-workshop-123/serviceAcc...d821c6999a88bb14f898a78c5a2992fb675add)
google_project_iam_binding.gocd_agent_account_container_iam: Destroying... (ID: devops-workshop-123/roles/container.admin)
google_service_account_key.gocd_agent_svc_account_key: Destruction complete after 2s
google_storage_bucket_iam_binding.gocd_agent_account_registry_iam: Destruction complete after 7s
google_project_iam_binding.gocd_agent_account_container_iam: Destruction complete after 7s
google_service_account.gocd_agent_svc_account: Destroying... (ID: projects/devops-workshop-123/serviceAcc...s-workshop-123.iam.gserviceaccount.com)
google_service_account.gocd_agent_svc_account: Destruction complete after 1s
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 10s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 20s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 30s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 41s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 51s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 1m1s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 1m11s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 1m21s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 1m31s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 1m41s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 1m51s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 2m1s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 2m11s elapsed)
google_container_cluster.cluster: Still destroying... (ID: devops-workshop-gke, 2m21s elapsed)
google_container_cluster.cluster: Destruction complete after 2m21s

Destroy complete! Resources: 5 destroyed.
```

Then, we can run the following script to cleanup all the unused Google Cloud
resources, replacing your Project ID in two occurrences:

```shell
$ GCLOUD_PROJECT_ID=devops-workshop-123 ./gcloud-cleanup.sh
+ set +e
+ PROJECT_ID=devops-workshop-123
+ deleteContainerImages pet-app
+ APP=pet-app

...
```

These steps will destroy all resources we created during the workshop, but if
you want to also shut down your entire GCP "Devops Workshop" project, you can do
so through the Management Console by going to the "IAM & admin" service,
choosing the "Settings" menu and clicking on "SHUT DOWN" button.
