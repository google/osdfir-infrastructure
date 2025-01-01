/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
locals {
  hostname   = "${replace(google_compute_global_address.external_address.address, ".", "-")}.nip.io"
  subdomains = ["openrelik.${local.hostname}"]
  certname   = "cert-${replace(google_compute_global_address.external_address.address, ".", "")}"
  domains    = concat([local.hostname], local.subdomains)
}

data "google_project" "project" {
}

##########################################################################
# Enable the required Cloud APIs
##########################################################################
resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "certificatemanager" {
  project = var.project_id
  service = "certificatemanager.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "networksecurity" {
  project = var.project_id
  service = "networksecurity.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "redis" {
  project = var.project_id
  service = "redis.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "serviceusage" {
  project = var.project_id
  service = "serviceusage.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_dependent_services = true
}

##########################################################################
# Create the external L7 load balancer IP address
##########################################################################
resource "google_compute_global_address" "external_address" {
  name         = var.address_name
  project      = var.project_id
  address_type = "EXTERNAL"
}

##########################################################################
# Create the L7 load balancer certificate
##########################################################################
resource "google_compute_managed_ssl_certificate" "openrelik_cert" {
  project = var.project_id
  name    = local.certname
  managed {
    domains = local.domains
  }
}

##########################################################################
# Set up the VPC and subnet
##########################################################################
resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# allow access from health check ranges
resource "google_compute_firewall" "allow_l7_xlb_fw_hc" {
  name          = "allow-l7-xlb-fw-hc"
  direction     = "INGRESS"
  network       = google_compute_network.vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}

# allow ssh ingress from iap
resource "google_compute_firewall" "allow_ssh_ingress_from_iap" {
  name          = "allow-ssh-ingress-from-iap"
  direction     = "INGRESS"
  network       = google_compute_network.vpc.id
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

##########################################################################
# Set up the Artifact Registry 
##########################################################################
resource "google_artifact_registry_repository" "artifact_registry" {
  location      = var.region
  repository_id = "artifact-registry"
  description   = "docker repository"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "openrelik_artifact_writer" {
  location = google_artifact_registry_repository.artifact_registry.location
  repository = google_artifact_registry_repository.artifact_registry.name
  role = "roles/artifactregistry.writer"
  member      = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/openrelik/sa/openrelik-sa"
  depends_on = [
    google_container_cluster.openrelik_cluster
  ]
}

##########################################################################
# Set up the GKE cluster
##########################################################################
data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.30."
}

resource "google_container_cluster" "openrelik_cluster" {
  name     = "openrelik-cluster"
  location = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range.0.range_name
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  datapath_provider = "ADVANCED_DATAPATH"

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  monitoring_config {
    managed_prometheus {
      enabled = true
    }

    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = true
    }
  }
  addons_config { 
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }
  secret_manager_config {
    enabled = true
  }
}

# Node Pool for OpenRelik nodes
resource "google_container_node_pool" "openrelik_node_pool" {
  name       = "openrelik-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.openrelik_cluster.name
  
  version = data.google_container_engine_versions.gke_version.release_channel_default_version["REGULAR"]
  node_count = var.openrelik_pool_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env      = var.project_id
      nodepool = var.nodepool
    }

    # preemptible  = true
    machine_type = var.nodepool_machine_type
    tags         = ["openrelik-pool-node", "allow-health-check"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

##########################################################################
# Set up the Cloud SQL Postres instance
##########################################################################
resource "google_network_connectivity_service_connection_policy" "postgres" {
  name          = "postgress"
  location      = var.region
  service_class = "google-cloud-sql"
  network       = google_compute_network.vpc.id
  psc_config {
    subnetworks = [google_compute_subnetwork.subnet.id]
    limit       = 2
  }
}

resource "google_sql_database_instance" "openrelik_postgres" {
  name             = "openrelik-postgres"
  region           = var.region
  database_version = "POSTGRES_17"
  
  settings {
    edition = "ENTERPRISE"
    tier    = var.db_tier
    ip_configuration {
      ipv4_enabled = false
      psc_config {
        psc_enabled = true
        allowed_consumer_projects = [var.project_id]
        psc_auto_connections {
          consumer_network = google_compute_network.vpc.id
          consumer_service_project_id = var.project_id
        }
      }
    }
  }
  deletion_protection  = false
  depends_on = [google_network_connectivity_service_connection_policy.postgres]
}

resource "google_sql_database" "openrelik" {
  name     = "openrelik"
  instance = google_sql_database_instance.openrelik_postgres.name
  deletion_policy = "DELETE"
}

resource "random_password" "openrelik" {
  length           = 16
  special          = false
}

resource "google_sql_user" "openrelik" {
  name     = "openrelik"
  instance = google_sql_database_instance.openrelik_postgres.name
  password = random_password.openrelik.result
}

resource "google_secret_manager_secret" "openrelik" {
  secret_id = "openrelik"
  labels = {
    label = "openrelik-db"
  }
  replication {
    user_managed {
      replicas {
        location = "europe-west1"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "openrelik" {
  secret = google_secret_manager_secret.openrelik.id
  secret_data = random_password.openrelik.result
}

resource "google_secret_manager_secret_iam_member" "openrelik_secret_accessor" {
  secret_id  = google_secret_manager_secret.openrelik.secret_id
  role       = "roles/secretmanager.secretAccessor"
  member     = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/openrelik/sa/openrelik-sa"
  depends_on = [
    google_container_cluster.openrelik_cluster
  ]
}

##########################################################################
# Set up the Redis instance
##########################################################################
resource "google_redis_instance" "redis" {
  name           = "redis"
  tier           = "BASIC"
  region         = var.region
  memory_size_gb = 1

  authorized_network = google_compute_network.vpc.id
  connect_mode       = "DIRECT_PEERING"

  display_name      = "OpenRelik Redis Instance"

  lifecycle {
    prevent_destroy = false
  }
}
