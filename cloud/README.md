# Provision Google Cloud Environment for OSDFIR Infrastructure

## Introduction
This repository hosts the code and configuration for provisioning a Google Cloud environment for OSDFIR Infrastructure deployments.  
At this stage the [GRR application](../charts/grr/README.md) is using the Google Cloud environment provisioned here.   
In the future other OSDFIR deployments might also be provisioned in such a fashion.


## 1. Preliminary Setup Instructions

We recommend that you create a new Google Cloud Project to run this demo.
Like this you can get the following benefits:
- enjoy a controled setup that provides the best chances for a successful demo, and
- discard all resources at the end to avoid any further charges.  

Your Google Cloud Project will need to have billing enabled.

### 1.1. Initialize ```gcloud```
```
export PROJECT_ID=[YOUR_PROJECT_ID_HERE]
gcloud config set project $PROJECT_ID
```

### 1.2. Enable the required Google Cloud APIs
As the first step we want to enable the necessary Google Cloud APIs.
The Terraform script will also do the same but enabling them early will give us the best chance to find them enabled when we execute the Terraform code. 
```
gcloud services enable artifactregistry.googleapis.com \
                       cloudbuild.googleapis.com \
                       cloudresourcemanager.googleapis.com \
                       container.googleapis.com \
                       monitoring.googleapis.com \
                       networksecurity.googleapis.com \
                       servicenetworking.googleapis.com \
                       serviceusage.googleapis.com \
                       sqladmin.googleapis.com
```

### 1.3. Remove the default VPC network
We also recommend that you remove the ```default``` VPC network.

```
gcloud compute firewall-rules delete default-allow-icmp default-allow-internal default-allow-rdp default-allow-ssh
gcloud compute networks delete default
```

## 2. Installation Instructions
We assume that you have already cloned this repository to your machine.   
If not then go ahead and issue the `git clone` command below:
```
git clone https://github.com/google/osdfir-infrastructure.git
```
We are good to go now!

### 2.1. Setup the Platform Infrasturcture
```
cd cloud
terraform init
terraform plan -var "project_id=$PROJECT_ID"
terraform apply -var "project_id=$PROJECT_ID"
```
### 2.2. Capture Environment Variables for later use
```
ARTIFACT_REGISTRY=$(terraform output -json | jq -r .artifact_registry_id.value)
PROJECT=$(terraform output -json | jq -r .project_id.value)
FLEETSPEAK_FRONTEND=$(terraform output -json | jq -r .fleetspeak_frontend.value)
GKE_CLUSTER_LOCATION=$(terraform output -json | jq -r .gke_cluster_location.value)
GKE_CLUSTER_NAME=$(terraform output -json | jq -r .gke_cluster_name.value)
MYSQL_DB_ADDRESS=$(terraform output -json | jq -r .mysqldb_ip_address.value)
REGION=$(terraform output -json | jq -r .region.value)
LOADBALANCER_CERT=$(terraform output -json | jq .fleetspeak_cert_loadbalancer.value | sed 's/\\n/\\\\n/g')

GRR_DAEMON_IMAGE=${REGION}-docker.pkg.dev/${PROJECT}/${ARTIFACT_REGISTRY}/grr-daemon
GRR_OPERATOR_IMAGE=${REGION}-docker.pkg.dev/${PROJECT}/${ARTIFACT_REGISTRY}/grr-operator
```

The following step is often required to store the loadbalancer certificate in the environment variable used in the next steps.
This is due to the fact that it takes some time to provision the certificate and terraform might not have picked up the certificate before finishing execution in the run above.

To make sure we have the certificate available we re-run terraform apply once more (see below instructions).
This step will not provision any new infrastructure but only pick up the loadbalancer certificate.

```
# Check the whether we already have the loadbalancer certificate stored in our environment variable.
echo $LOADBALANCER_CERT
# Most likely you'll get the empty value as below
# ""

# Run terraform again to pick up the loadbalancer certificate
terraform apply -var "project_id=$PROJECT_ID"
LOADBALANCER_CERT=$(terraform output -json | jq .fleetspeak_cert_loadbalancer.value | sed 's/\\n/\\\\n/g')

# Check the value of the loadbalancer certificate.
# It should now show a certificate.
echo $LOADBALANCER_CERT
```

## 3. Deploy the GRR application on GKE
You can now return to the instructions on how to [install GRR on GKE](../charts/grr/README.md#62-install-grr-on-gke).

## 4. Cleaning up
We recommend that you clean up the installation after you are done with your testing to avoid any future charges.  

You can delete the entire Google Cloud Project (and all resources contained in it) by going to the [Resource Manager](https://console.cloud.google.com/cloud-resource-manager), select your Project and delete it (you will need to confirm your action by copying the Project ID).  
You can find more info in the [online documentation](https://cloud.google.com/resource-manager/docs/creating-managing-projects#shutting_down_projects).

## License

Copyright &copy; 2024 OSDFIR Infrastructure

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
