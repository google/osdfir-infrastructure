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

output "artifact_registry_id" {
  description = "The Artifact Registry ID"
  value       = google_artifact_registry_repository.artifact_registry.repository_id
}

output "gke_cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.openrelik_cluster.location
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.openrelik_cluster.name
}

output "openrelik_db" {
  description = "The name of the OpenRelik Postgres DB."
  value       = google_sql_database.openrelik.name
}

output "openrelik_db_instance" {
  description = "The name of the OpenRelik Postgres instance."
  value       = google_sql_database_instance.openrelik_postgres.name
}

output "openrelik_db_user" {
  description = "The user name of the OpenRelik Postgres DB."
  value       = google_sql_user.openrelik.name
}

output "project_id" {
  description = "The Project ID"
  value       = var.project_id
}

output "redis_address" {
  description = "The IP address of the Redis memory store."
  value       = google_redis_instance.redis.host
}

output "region" {
  description = "The Region"
  value       = var.region
}

output "zone" {
  description = "The Zone"
  value       = var.zone
}

output "hostname" {
  description = "The Openrelik frontend external hostname"
  value       = local.hostname
}

output "db_secret_name" {
  description = "The Openrelik DB secret name"
  value       = google_secret_manager_secret.openrelik.secret_id
}

output "db_secret_version" {
  description = "The Openrelik DB secret version"
  value       = google_secret_manager_secret_version.openrelik.version
}

output "certname" {
  description = "The Openrelik frontend certficate name"
  value       = local.certname
}
