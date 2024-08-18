/**
 * Copyright 2024 Google LLC
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
  subdomains = ["fleetspeak.${local.hostname}"]
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

  disable_dependent_services = false
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "networksecurity" {
  project = var.project_id
  service = "networksecurity.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "serviceusage" {
  project = var.project_id
  service = "serviceusage.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_dependent_services = false
}

##########################################################################
# Set up the GCS GRR Blobstore
##########################################################################
resource "google_storage_bucket" "grr_blobstore" {
  name                        = "blobstore-${var.project_id}"
  project                     = var.project_id
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

resource "google_storage_bucket_iam_member" "grr_blobstore_admin" {
  bucket = google_storage_bucket.grr_blobstore.name
  role   = "roles/storage.admin"
  member = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/grr/sa/grr-sa"
  depends_on = [
    google_container_cluster.osdfir_cluster
  ]
}

##########################################################################
# Set up the external L7 load balancer
##########################################################################
resource "google_compute_global_address" "external_address" {
  name         = var.address_name
  project      = var.project_id
  address_type = "EXTERNAL"
}

resource "google_compute_managed_ssl_certificate" "fleetspeak_cert" {
  project = var.project_id
  name    = local.certname
  managed {
    domains = local.domains
  }
}

data "google_compute_ssl_certificate" "fleetspeak_cert_loadbalancer" {
  name = google_compute_managed_ssl_certificate.fleetspeak_cert.name
}

resource "google_network_security_server_tls_policy" "mtls_server_policy" {
  provider               = google-beta
  name                   = "mtls-server-policy"
  description            = "TLS policy enforcing mTLS"
  location               = "global"
  allow_open             = "false"
  mtls_policy {
    client_validation_mode = "ALLOW_INVALID_OR_MISSING_CLIENT_CERT"
  }
}

resource "google_compute_global_forwarding_rule" "l7_xlb_forwarding_rule" {
  name                  = "l7-xlb-forwarding-rule"
  provider              = google-beta
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.l7_xlb_https_proxy.id
  ip_address            = google_compute_global_address.external_address.id
}

resource "google_compute_target_https_proxy" "l7_xlb_https_proxy" {
  name              = "l7-xlb-target-proxy"
  provider          = google-beta
  url_map           = google_compute_url_map.l7_xlb_url_map.id
  ssl_certificates  = [google_compute_managed_ssl_certificate.fleetspeak_cert.id]
  server_tls_policy = google_network_security_server_tls_policy.mtls_server_policy.id
}

resource "google_compute_url_map" "l7_xlb_url_map" {
  name            = "l7-xlb-url-map"
  provider        = google-beta
  default_service = google_compute_backend_service.l7_xlb_backend_service.id
}

resource "google_compute_backend_service" "l7_xlb_backend_service" {
  name                    = "l7-xlb-backend-service"
  provider                = google-beta
  protocol                = "HTTPS"
  port_name               = "fleetspeak-port"
  load_balancing_scheme   = "EXTERNAL"
  timeout_sec             = 800 # avoid timeouts interupting long running connection
  custom_request_headers  = ["X-Client-Cert-Hash:{client_cert_sha256_fingerprint}"]
  health_checks           = [google_compute_health_check.l7_xlb_hc.id]

  # Ignore changes to the instance backend
  lifecycle {
    ignore_changes = [backend]
  }
}

resource "google_compute_health_check" "l7_xlb_hc" {
  name     = "l7-xlb-hc"
  provider = google-beta
  http_health_check {
    request_path = "/"
    port         = "8080"
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

resource "google_artifact_registry_repository_iam_member" "grr_artifact_writer" {
  location = google_artifact_registry_repository.artifact_registry.location
  repository = google_artifact_registry_repository.artifact_registry.name
  role = "roles/artifactregistry.writer"
  member      = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/grr/sa/grr-sa"
  depends_on = [
    google_container_cluster.osdfir_cluster
  ]
}

##########################################################################
# Set up the GKE cluster
##########################################################################
data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.28."
}

resource "google_container_cluster" "osdfir_cluster" {
  name     = "osdfir-cluster"
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

  monitoring_config {
    managed_prometheus {
      enabled = true
    }

    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = true
    }
  } 
}

# Node Pool for GRR / Fleetspeak server nodes
resource "google_container_node_pool" "grr-node-pool" {
  name       = "grr-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.osdfir_cluster.name
  
  version = data.google_container_engine_versions.gke_version.release_channel_default_version["REGULAR"]
  node_count = var.grr_pool_num_nodes

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
    tags         = ["grr-pool-node", "allow-health-check"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

##########################################################################
# Set up the PubSub Topic and Subscriber for GRR Fleetspeak Service 
##########################################################################
resource "google_pubsub_topic" "grr_fleetspeak_service_topic" {
  name = "grr-fleetspeak-service-topic"

  message_storage_policy {
    allowed_persistence_regions = [
      var.region,
    ]
  }
}

resource "google_pubsub_subscription" "grr_fleetspeak_service_subscription" {
  name  = "grr-fleetspeak-service-subscription"
  topic = google_pubsub_topic.grr_fleetspeak_service_topic.id
}

resource "google_pubsub_topic_iam_member" "grr_fleetspeak_topic" {
  topic  = google_pubsub_topic.grr_fleetspeak_service_topic.name
  role   = "roles/pubsub.publisher"
  member = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/grr/sa/grr-sa"
  depends_on = [
    google_container_cluster.osdfir_cluster
  ]
}

resource "google_pubsub_subscription_iam_member" "grr_fleetspeak_subscriber" {
  subscription = google_pubsub_subscription.grr_fleetspeak_service_subscription.name
  role         = "roles/pubsub.subscriber"
  member      = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/grr/sa/grr-sa"
  depends_on = [
    google_container_cluster.osdfir_cluster
  ]
}

##########################################################################
# Set up the Cloud SQL database 
##########################################################################
resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta

  name             = "grr-fleetspeak-db"
  region           = var.region
  database_version = "MYSQL_8_0"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }
    database_flags {
      name  = "max_allowed_packet"
      value = "41943040"
    }
  }
}

resource "google_sql_database" "grr_database" {
  name     = "grr"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database" "fleetspeak_database" {
  name     = "fleetspeak"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "grr_user" {
  name     = "grr-user"
  instance = google_sql_database_instance.instance.name
  host     = "%"
  password = "grr-password"
}

resource "google_sql_user" "fleetspeak_user" {
  name     = "fleetspeak-user"
  instance = google_sql_database_instance.instance.name
  host     = "%"
  password = "fleetspeak-password"
}
