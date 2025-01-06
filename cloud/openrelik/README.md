# Provision Google Cloud Environment for OpenRelik

## Introduction

This repository hosts the code and configuration for provisioning a Google Cloud environment for OpenRelik deployments.

## 1. Preliminary Setup Instructions

We recommend that you create a new Google Cloud Project to run this demo.
Like this you can get the following benefits:

- enjoy a controled setup that provides the best chances for a successful demo, and
- discard all resources at the end to avoid any further charges.

Your Google Cloud Project will need to have billing enabled.

### 1.1. Initialize ```gcloud```

```console
export PROJECT_ID=[YOUR_PROJECT_ID_HERE]
gcloud config set project $PROJECT_ID
```

### 1.2. Enable the required Google Cloud APIs

As the first step we want to enable the necessary Google Cloud APIs.
The Terraform script will also do the same but enabling them early will give us the best chance to find them enabled when we execute the Terraform code.

```console
gcloud services enable artifactregistry.googleapis.com \
                       certificatemanager.googleapis.com \
                       cloudresourcemanager.googleapis.com \
                       container.googleapis.com \
                       file.googleapis.com \
                       monitoring.googleapis.com \
                       networksecurity.googleapis.com \
                       redis.googleapis.com \
                       secretmanager.googleapis.com \
                       servicenetworking.googleapis.com \
                       serviceusage.googleapis.com \
                       sqladmin.googleapis.com \
                       storage.googleapis.com
```

### 1.3. Remove the default VPC network

We also recommend that you remove the ```default``` VPC network.

```console
gcloud compute firewall-rules delete default-allow-icmp default-allow-internal default-allow-rdp default-allow-ssh
gcloud compute networks delete default
```

## 2. Installation Instructions

We assume that you have already cloned this repository to your machine.
If not then go ahead and issue the `git clone` command below:

```console
git clone https://github.com/google/osdfir-infrastructure.git
cd osdfir-infrastructure
export REPO=$(pwd)

cd cloud/openrelik
```

We are good to go now!

### 2.1. Setup the Platform Infrasturcture

```console
terraform init
terraform plan -var "project_id=$PROJECT_ID"
terraform apply -var "project_id=$PROJECT_ID"
```

### 2.2. Capture Environment Variables for later use

```console
export ARTIFACT_REGISTRY=$(terraform output -json | jq -r .artifact_registry_id.value)
export CERTIFICATE_NAME=$(terraform output -json | jq -r .certname.value)
export DB_SECRET_NAME=$(terraform output -json | jq -r .db_secret_name.value)
export DB_SECRET_VERSION=$(terraform output -json | jq -r .db_secret_version.value)
export GKE_CLUSTER_LOCATION=$(terraform output -json | jq -r .gke_cluster_location.value)
export GKE_CLUSTER_NAME=$(terraform output -json | jq -r .gke_cluster_name.value)
export PROJECT=$(terraform output -json | jq -r .project_id.value)
export OPENRELIK_DB=$(terraform output -json | jq -r .openrelik_db.value)
export OPENRELIK_DB_INSTANCE=$(terraform output -json | jq -r .openrelik_db_instance.value)
export OPENRELIK_DB_USER=$(terraform output -json | jq -r .openrelik_db_user.value)
export OPENRELIK_DB_ADDRESS=$(gcloud sql instances describe ${OPENRELIK_DB_INSTANCE} --project=${PROJECT} --format=json | jq -r .settings.ipConfiguration.pscConfig.pscAutoConnections[0].ipAddress)
export OPENRELIK_HOSTNAME=$(terraform output -json | jq -r .hostname.value)
export REDIS_ADDRESS=$(terraform output -json | jq -r .redis_address.value)
export REGION=$(terraform output -json | jq -r .region.value)
export ZONE=$(terraform output -json | jq -r .zone.value)

export ENABLE_GCP=true
```

## 3. Installing OpenRelik on GKE

You can continue with the instructions for [installing OpenRelik on GKE](../../charts/openrelik/README.md#22-installing-openrelik-on-gke).

## 4. Cleaning up

We recommend that you clean up the installation after you are done with your testing to avoid any future charges.

You can delete the entire Google Cloud Project (and all resources contained in it) by going to the [Resource Manager](https://console.cloud.google.com/cloud-resource-manager), select your Project and delete it (you will need to confirm your action by copying the Project ID).
You can find more info in the [online documentation](https://cloud.google.com/resource-manager/docs/creating-managing-projects#shutting_down_projects).

## License

Copyright &copy; 2025 OSDFIR Infrastructure

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
