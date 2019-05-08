variable "gcp_project_id" {
  default = "devops-workshop-123"
}

variable "kubernetes_version" {
  default = "1.12.7-gke.10"
}

provider "google" {
  project      = "${var.gcp_project_id}"
  region       = "us-central1"
}

resource "google_container_cluster" "cluster" {
  name = "devops-workshop-gke"
  zone = "us-central1-a"
  additional_zones = ["us-central1-b"]
  initial_node_count = 1

  min_master_version = "${var.kubernetes_version}"
  master_auth {
    username = "admin"
    password = "choose-a-long-password"
  }

  node_version = "${var.kubernetes_version}"
  node_config {
	  machine_type = "n1-standard-2"
	  disk_size_gb = "50"

    oauth_scopes = [
  	  "https://www.googleapis.com/auth/compute",
  	  "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }

  logging_service = "logging.googleapis.com"
  monitoring_service = "monitoring.googleapis.com"
}

resource "google_service_account" "gocd_agent_svc_account" {
  account_id = "gocd-agent"
}

resource "google_service_account_key" "gocd_agent_svc_account_key" {
  service_account_id = "${google_service_account.gocd_agent_svc_account.name}"
}

resource "google_storage_bucket_iam_binding" "gocd_agent_account_registry_iam" {
  bucket = "us.artifacts.${var.gcp_project_id}.appspot.com"
  role   = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.gocd_agent_svc_account.account_id}@${var.gcp_project_id}.iam.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "gocd_agent_account_container_iam" {
  project = "${var.gcp_project_id}"
  role   = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.gocd_agent_svc_account.account_id}@${var.gcp_project_id}.iam.gserviceaccount.com"
  ]
}

output "service_account_key" {
  value = "${google_service_account_key.gocd_agent_svc_account_key.private_key}"
}
