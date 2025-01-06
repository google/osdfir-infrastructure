# OpenRelik Helm Chart

[OpenRelik](https://openrelik.org) OpenRelik is an open-source (Apache-2.0) platform designed to streamline collaborative digital forensic investigations.

[Overview of OpenRelik](https://openrelik.org/docs/)

[Chart Source Code](https://github.com/openrelik)

Before we get started make sure you clone the repo onto your machine.

```console
git clone https://github.com/google/osdfir-infrastructure.git
cd osdfir-infrastructure
export REPO=$(pwd)
```

## TL;DR

> **Tip**: To quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

```console
# Start minikube
minikube start
minikube tunnel &

# Create the configuration files
cd charts/openrelik
./config.sh local

# Change back to the REPO directory
cd $REPO

# Install the OpenRelik Helm chart
helm install openrelik-on-k8s ./charts/openrelik -f ./charts/openrelik/values.yaml
```

> **Note**: For a more real life scenario see [Installing on Cloud](#2-installing-openrelik-on-cloud) for deploying OpenRelik on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine) (GKE).

## Introduction

This chart bootstraps a [OpenRelik](https://github.com/openrelik) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/) v1.32.0+
- [Docker](https://docs.docker.com/engine/install/) 25.0.3+
- [Kubernetes](https://kubernetes.io/) 1.27.8+
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) v1.29.2+
- [Helm](https://helm.sh/docs/intro/install/) 3.14.1+

## 1. Installing OpenRelik on minikube

Let's start ```minikube``` and set up tunneling for later interactions.
The [minikube tunnel](https://minikube.sigs.k8s.io/docs/commands/tunnel/) feature creates a network route on the host to Kubernetes services using the cluster’s IP address as a gateway.
The tunnel command exposes the IP address to any program running on the host operating system.

```console
minikube start
minikube tunnel &
```

### 1.1. Creating the configuration

```console
# Create the configuration files
cd charts/openrelik
./config.sh local

# Change back to the REPO directory
cd $REPO
```

### 1.2. Installing the Chart

To install the chart, specify any release name of your choice. For example, using `openrelik-on-k8s' as the release name, run:

```
# Install the OpenRelik Helm chart
helm install openrelik-on-k8s ./charts/openrelik -f ./charts/openrelik/values.yaml

# Verify that all the OpenRelik component pods are in 'Running' state (this might take a moment)
kubectl get pods
# The output should look similar to the below:
# NAME                                               READY  STATUS   RESTARTS  AGE
# openrelik-mediator-7c58c4d667-j8l9t                1/1    Running  0         8s
# openrelik-postgres-589c44cd5f-ggk6p                1/1    Running  0         8s
# openrelik-redis-66d8946695-4jv6j                   1/1    Running  0         8s
# openrelik-server-5864d95fc7-cdw7x                  1/1    Running  0         8s
# openrelik-ui-d5c646bc7-xnwgx                       1/1    Running  0         8s
# openrelik-worker-analyzer-config-58b4ddd59f-4pfjd  1/1    Running  0         8s
# openrelik-worker-extraction-68f94856f6-kpksl       1/1    Running  0         8s
# openrelik-worker-hayabusa-676bb647dc-6wck5         1/1    Running  0         8s
# openrelik-worker-plaso-55f97c9555-j9skb            1/1    Running  0         8s
# openrelik-worker-strings-7db674c997-z4n66          1/1    Running  0         8s
```

The command deploys OpenRelik on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

### 1.3. Initialise the Openrelik DB

```
kubectl exec -it openrelik-server-5864d95fc7-cdw7x -n openrelik -c openrelik-server -- \
        bash -c "cd /app/openrelik/datastores/sql && \
                 export SQLALCHEMY_DATABASE_URL=$(grep database_url /var/config/settings.toml | sed "s/database_url = //" | sed 's/"//g') && \
                 alembic upgrade head"
```

### 1.4. Create the ```admin``` user

```
export USER_PWD="<YOUR_USER_PWD HERE>"
kubectl exec -it openrelik-server-5864d95fc7-cdw7x -n openrelik -c openrelik-server -- \
        bash -c "python admin.py create-user admin --password ${USER_PWD} --admin"
```

### 1.5. Connect to the OpenRelik Frontend

You can now point your browser to the OpenRelik Frontend.

```console
export UI_IP=$(kubectl get svc svc-ui -n openrelik --output jsonpath='{.spec.clusterIP}')
export SERVER_IP=$(kubectl get svc svc-server -n openrelik --output jsonpath='{.spec.clusterIP}')

ssh -L 8711:$UI_IP:8711 -L 8710:$SERVER_IP:8710 minikube

http://localhost:8710
```

## 2. Installing OpenRelik on Cloud

After installing OpenRelik on minikube and kicking the tires you likely aim for running OpenRelik in a more real life scenario.
For this you could consider installing OpenRelik on a managed Kubernetes cluster in the cloud like on [Google Cloud's Kubernetes Engine](https://cloud.google.com/kubernetes-engine) (GKE).

### 2.1. GKE Installation

Before we can install OpenRelik we need to provision a GKE cluster and its related infrastructure.
The quickest way to provision a ready to run environment on Google Cloud is by following the steps in these [installation instructions](../../cloud/openrelik/README.md).

We recommend that you start with cloning this repo again to avoid carrying over any configurations from the minikube based instructions above.

```console
git clone https://github.com/google/osdfir-infrastructure.git
cd osdfir-infrastructure
export REPO=$(pwd)
```

Once you have provisioned your infrastructure you can continue with the instructions below.

### 2.2. Installing OpenRelik on GKE

In case you followed the Google Cloud environment installation instructions you should already have the following environment variables configured.
Otherwise, either run the [installation instruction step](../../cloud/openrelik/README.md#22-capture-environment-variables-for-later-use) again or set the environment variables to values that match your setup.
You can check that they have a value assigned by runnig the commands below.

```console
echo "ARTIFACT_REGISTRY: $ARTIFACT_REGISTRY"
echo "CERTIFICATE_NAME: $CERTIFICATE_NAME"
echo "DB_SECRET_NAME: $DB_SECRET_NAME"
echo "DB_SECRET_VERSION: $DB_SECRET_VERSION"
echo "ENABLE_GCP: $ENABLE_GCP"
echo "GKE_CLUSTER_LOCATION: $GKE_CLUSTER_LOCATION"
echo "GKE_CLUSTER_NAME: $GKE_CLUSTER_NAME"
echo "PROJECT: $PROJECT"
echo "OPENRELIK_DB: $OPENRELIK_DB"
echo "OPENRELIK_DB_INSTANCE: $OPENRELIK_DB_INSTANCE"
echo "OPENRELIK_DB_USER: $OPENRELIK_DB_USER"
echo "OPENRELIK_DB_ADDRESS: $OPENRELIK_DB_ADDRESS"
echo "OPENRELIK_HOSTNAME: $OPENRELIK_HOSTNAME"
echo "REDIS_ADDRESS: $REDIS_ADDRESS"
echo "REGION: $REGION"
echo "ZONE: $ZONE"
```

#### 2.2.1. Fetch the GKE cluster credentials

```console
gcloud container clusters get-credentials $GKE_CLUSTER_NAME --zone $GKE_CLUSTER_LOCATION --project $PROJECT_ID
```

#### 2.2.2. Set the default values for the OpenRelik Helm chart

```console
cd $REPO/charts/openrelik
./config.sh cloud

# Change back to the REPO directory
cd $REPO
```

#### 2.2.3. Create the Filestore share

> **Tip**: For more details see [Filestore Multishares](https://cloud.google.com/filestore/docs/optimize-multishares)

```
kubectl apply -f charts/openrelik/templates/namespace/ns-openrelik.yaml

kubectl apply -f charts/openrelik/filestore/sc-ms-512.yaml

kubectl apply -f charts/openrelik/filestore/pvc-filestore.yaml

# Make sure you let the Filestore creation process finish before continuing.
watch -n 1 kubectl get pvc -n openrelik

# You should see a message like the one below once the Filestore has been created:
# NAME          STATUS VOLUME                        CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE
# pvc-filestore Bound  pvc-2404aa93-...-f18e560b9534 512Gi    RWX          sc-ms-512    <unset>               1m 
```

#### 2.2.4. Install the Helm chart

```console
helm install openrelik-on-k8s ./charts/openrelik -f ./charts/openrelik/values-gcp.yaml
```

#### 2.2.5. Wait for all OpenRelik pods to be in 'Running' status

```console
# Check that all the pods are in the 'Running' status.
kubectl get pods -n openrelik
# The output should look something like the below:
# NAME                                               READY STATUS   RESTARTS  AGE
# openrelik-mediator-75b4659b97-znvhb                1/1   Running  0         34s
# openrelik-server-5957548585-zzhpj                  1/1   Running  0         34s
# openrelik-ui-6597bc774d-nnjln                      1/1   Running  0         34s
# openrelik-worker-analyzer-config-78f84979ff-9v5fp  1/1   Running  0         34s
# openrelik-worker-extraction-6dc457bc6-6kjjl        1/1   Running  0         34s
# openrelik-worker-hayabusa-74d9c78bb5-ttkv4         1/1   Running  0         34s
# openrelik-worker-plaso-78ffb5b75-dmnnc             1/1   Running  0         34s
# openrelik-worker-strings-9648dfbf-b5s55            1/1   Running  0         33s
```

#### 2.2.6. Initialise the Openrelik DB

```
kubectl exec -it openrelik-server-5957548585-zzhpj -n openrelik -c openrelik-server -- \
        bash -c "cd /app/openrelik/datastores/sql && \
                 export SQLALCHEMY_DATABASE_URL=$(grep database_url /var/config/settings.toml | sed "s/database_url = //" | sed 's/"//g') && \
                 alembic upgrade head"
```

#### 2.2.7. Create the ```admin``` user

```
export USER_PWD="<YOUR_USER_PWD HERE>"
kubectl exec -it openrelik-server-5957548585-zzhpj -n openrelik -c openrelik-server -- \
        bash -c "python admin.py create-user admin --password ${USER_PWD} --admin"
```

## 3. Connect to the UI

Run the command below and then point your browser to the displayed URL:

```
echo "https://$OPENRELIK_HOSTNAME"
```

## 4. Cleaning up

We recommend that you clean up the installation after you are done with your testing to avoid any future charges.
To do so you have two options to clean up the installation.

1. Delete the Google Cloud Project and with it all the resources contained in it.
2. Build back sequentially what we installed (this can be useful in case you want to make some adjustments and re-install bits an pieces).

### 3.1. Delete the Google Cloud Project

You can delete the entire Google Cloud Project (and all resources contained in it) by going to the [Resource Manager](https://console.cloud.google.com/cloud-resource-manager), select your Project and delete it (you will need to confirm your action by copying the Project ID).
You can find more info in the [online documentation](https://cloud.google.com/resource-manager/docs/creating-managing-projects#shutting_down_projects).

### 3.2. Build back sequentially

Sequentially building back the installation can be useful for cases where you would like to make some adjustments to your current installtion.
For such cases just build back as far as needed to make your adjustments and then roll forward the installation again following the original instructions.

To uninstall/delete a Helm deployment with a release name of `openrelik-on-k8s`:

```console
helm uninstall openrelik-on-k8s
```

> **Tip**: Please update based on the release name chosen. You can list all releases using `helm list`

## Parameters

### Global parameters

| Name                         | Description                                                    | Value   |
| ---------------------------- | -------------------------------------------------------------- | ------- |

### OpenRelik parameters

| Name                         | Description                                             | Value                                 |
| ---------------------------- | ------------------------------------------------------- | ------------------------------------- |

### Postgres parameters

| Name                         | Description                                             | Value                                 |
| ---------------------------- | ------------------------------------------------------- | ------------------------------------- |

### Redis parameters

| Name                         | Description                                             | Value                                 |
| ---------------------------- | ------------------------------------------------------- | ------------------------------------- |

### Gateway API parameters

| Name                         | Description                                             | Value                                 |
| ---------------------------- | ------------------------------------------------------- | ------------------------------------- |

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
