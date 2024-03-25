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

output "mysqldb_ip_address" {
  description = "The IP address of the grr/fleetspeak MySQL DB."
  value       = google_sql_database_instance.instance.private_ip_address
}

output "fleetspeak_frontend" {
  description = "The Fleetspeak Frontend"
  value       = local.hostname
}

output "project_id" {
  description = "The Project ID"
  value       = var.project_id
}

output "region" {
  description = "The Region"
  value       = var.region
}

output "artifact_registry_id" {
  description = "The Artifact Registry ID"
  value       = google_artifact_registry_repository.artifact_registry.repository_id
}

output "gke_cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.osdfir_cluster.location
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.osdfir_cluster.name
}

output "fleetspeak_cert_loadbalancer" {
  description = "The cert"
  value       = data.google_compute_ssl_certificate.fleetspeak_cert_loadbalancer.certificate
}
