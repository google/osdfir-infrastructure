# GRR Helm Chart

[GRR](https://github.com/google/grr) Rapid Response is an incident response framework focused on remote live forensics.

[Overview of GRR](https://grr-doc.readthedocs.io/)

[Chart Source Code](https://github.com/google/osdfir-infrastructure)

Before we get started make sure you clone the repo onto your machine.

```console
git clone https://github.com/google/osdfir-infrastructure.git
cd osdfir-infrastructure
export REPO=$(pwd)
```

## TL;DR

> **Tip**: To quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

```console
minikube start
minikube tunnel &
./charts/grr/createSigningKeys.sh
helm install grr-on-k8s ./charts/grr -f ./charts/grr/values.yaml
```

> **Note**: For a more real life scenario see [Installing on Cloud](#2-installing-grr-on-cloud) for deploying GRR on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine) (GKE).

## Introduction

This chart bootstraps a [GRR](https://github.com/google/grr) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/) v1.32.0+
- [Docker](https://docs.docker.com/engine/install/) 25.0.3+
- [Kubernetes](https://kubernetes.io/) 1.27.8+
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) v1.29.2+
- [Helm](https://helm.sh/docs/intro/install/) 3.14.1+

## 1. Installing GRR on minikube

Let's start ```minikube``` and set up tunneling for later interactions.
The [minikube tunnel](https://minikube.sigs.k8s.io/docs/commands/tunnel/) feature creates a network route on the host to Kubernetes services using the cluster’s IP address as a gateway.
The tunnel command exposes the IP address to any program running on the host operating system.

```console
minikube start
minikube tunnel &
./charts/grr/createSigningKeys.sh
```

### 1.1. Installing the Chart

To install the chart, specify any release name of your choice. For example, using `grr-on-k8s' as the release name, run:

```console
helm install grr-on-k8s ./charts/grr -f ./charts/grr/values.yaml

# Verify that all the GRR component pods are in 'Running' state (this might take a moment)
kubectl get pods
# The output should look similar to the below:
# NAME                                      READY   STATUS    RESTARTS   AGE
# dpl-fleetspeak-admin-576754755b-hj27p     1/1     Running   0          1m1s
# dpl-fleetspeak-frontend-78bd9889d-jvb5v   1/1     Running   0          1m1s
# dpl-grr-admin-6b84cd996b-d54zn            1/1     Running   0          1m1s
# dpl-grr-frontend-5fc7f8dc5b-7hsbd         1/1     Running   0          1m1s
# dpl-grr-worker-cc96f574c-kxr9l            1/1     Running   0          1m1s
# mysql-5cd45cc59f-bgwlv                    1/1     Running   0          3m59s
```

The command deploys GRR on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

### 1.2. Deploy a GRR client as a Kubernetes DaemonSet

For test and demo purposes we will deploy a GRR client as a [Kubernetes DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/).
To do so we will

- retrieve the values for some configuration parameters,
- then build a Docker container with the GRR client and its dependencies, and
- finally deploy the container as a DaemonSet.

#### 1.2.1. Retrieve the configuration parameter values

```console
cd charts/grr/containers/grr-client/
export FLEETSPEAK_FRONTEND_ADDRESS="fleetspeak-frontend"
export FLEETSPEAK_FRONTEND_IP=$(kubectl get svc svc-fleetspeak-frontend --output jsonpath='{.spec.clusterIP}')
export FLEETSPEAK_FRONTEND_PORT=4443
export FLEETSPEAK_CERT=$(openssl s_client -showcerts -nocommands -connect \
                         $FLEETSPEAK_FRONTEND_IP:$FLEETSPEAK_FRONTEND_PORT< /dev/null | \
                         openssl x509 -outform pem | sed ':a;N;$!ba;s/\n/\\\\n/g')
sed "s'FLEETSPEAK_FRONTEND_ADDRESS'$FLEETSPEAK_FRONTEND_ADDRESS'g" config/config.textproto.tmpl > config/config.textproto
sed -i "s'FLEETSPEAK_FRONTEND_PORT'$FLEETSPEAK_FRONTEND_PORT'" config/config.textproto
sed -i "s'FRONTEND_TRUSTED_CERTIFICATES'\"$FLEETSPEAK_CERT\"'g" config/config.textproto
```

#### 1.2.2. Build the GRR client Docker container

```console
eval $(minikube docker-env)
docker build -t grr-client:v0.1 .
```

#### 1.2.3. Deploy the GRR client DaemonSet

```console
kubectl label nodes minikube grrclient=installed

# Verify that the GRR client DaemonSet got deployed.
kubectl get daemonset
# The output should look similar to the below:
# NAME   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR         AGE
# grr    1         1         1       1            1           grrclient=installed   53s
```

### 1.3. Connect to the GRR Admin Frontend

You can now point your browser to the GRR Admin Frontend to investigate the node with the GRR client.

```console
export GRR_ADMIN_IP=$(kubectl get svc svc-grr-admin --output jsonpath='{.spec.clusterIP}')
echo http://${GRR_ADMIN_IP}:8000
```

The GRR Admin Frontend can now be reached on the following URL (note that you might have to tunnel to your server first):
[http://${GRR_ADMIN_IP}:8000](http://${GRR_ADMIN_IP}:8000)

## 2. Installing GRR on Cloud

After installing GRR on minikube and kicking the tires you likely aim for running GRR in a more real life scenario.
For this you could consider installing GRR on a managed Kubernetes cluster in the cloud like on [Google Cloud's Kubernetes Engine](https://cloud.google.com/kubernetes-engine) (GKE).
We have you covered by documenting two flavours below on how you can quickly get up to speed with a GKE based GRR installation:

- GRR on GKE with layer 4 load balancer (TODO)
- GRR on GKE with layer 7 load balancer

![GRR / Fleetspeak Demo Architecture](../../docs/images/grr-fleetspeak-demo-architecture.png "GRR / Fleetspeak Demo Architecture")`

Your choice of load balancer will determine how your GRR client fleet communicates with GRR's [Fleetspeak](https://github.com/google/fleetspeak) based communication layer.
You can find more details and background on the different modes of exposing GRR's Fleetspeak based communication layer in this [blog post](https://osdfir.blogspot.com/2023/12/running-grr-everywhrr.html).

### 2.1. GKE Installation

Before we can install GRR we need to provision a GKE cluster and its related infrastructure.
The quickest way to provision a ready to run environment on Google Cloud is by following the steps in these [installation instructions](../../cloud/README.md).

We recommend that you start with cloning this repo again to avoid carrying over any configurations from the minikube based instructions above.

```console
git clone https://github.com/google/osdfir-infrastructure.git
cd osdfir-infrastructure
export REPO=$(pwd)
```

Once you have provisioned your infrastructure you can continue with the instructions below.

### 2.2. Installing GRR on GKE

In case you followed the Google Cloud environment installation instructions you should already have the following environment variables configured.
Otherwise, either run the [installation instruction step](../../cloud/README.md#22-capture-environment-variables-for-later-use) again or set the environment variables to values that match your setup.
You can check that they have a value assigned by runnig the commands below.

```console
echo "FLEETSPEAK_FRONTEND: $FLEETSPEAK_FRONTEND"
echo "GKE_CLUSTER_LOCATION: $GKE_CLUSTER_LOCATION"
echo "GKE_CLUSTER_NAME: $GKE_CLUSTER_NAME"
echo "GRR_BLOBSTORE_BUCKET: $GRR_BLOBSTORE_BUCKET"
echo "GRR_CLIENT_IMAGE: $GRR_CLIENT_IMAGE"
echo "GRR_OPERATOR_IMAGE: $GRR_OPERATOR_IMAGE"
echo "LOADBALANCER_CERT: $LOADBALANCER_CERT"
echo "MYSQL_DB_ADDRESS: $MYSQL_DB_ADDRESS"
echo "PROJECT_ID: $PROJECT_ID"
echo "PUBSUB_SUBSCRIPTION: $PUBSUB_SUBSCRIPTION"
echo "PUBSUB_TOPIC: $PUBSUB_TOPIC"
echo "REGION: $REGION"
echo "ZONE: $ZONE"
```

#### 2.2.1. Fetch the GKE cluster credentials

```console
gcloud container clusters get-credentials $GKE_CLUSTER_NAME --zone $GKE_CLUSTER_LOCATION --project $PROJECT_ID
```

#### 2.2.2. Set the default values for the GRR chart

> **Note**: The Google Cloud environment [installation Terraform script](../../cloud/README.md#21-setup-the-platform-infrasturcture) has provisioned a managed [Cloud SQL for MySQL](https://cloud.google.com/sql/mysql) database. In case to choose to self-manage the MySQL database you can enable it by setting ```selfManagedMysql: true``` in the ```values-gcp.yaml``` configuration file. Make sure you adjust the ```MYSQL_DB_ADDRESS=mysql``` in the commands below accordingly.

```console
sed -i "s'FLEETSPEAK_DB_ADDRESS'$MYSQL_DB_ADDRESS'g" charts/grr/values-gcp.yaml
sed -i "s'GRR_BLOBSTORE_BUCKET'$GRR_BLOBSTORE_BUCKET'g" charts/grr/values-gcp.yaml
sed -i "s'GRR_CLIENT_IMAGE'$GRR_CLIENT_IMAGE'g" charts/grr/values-gcp.yaml
sed -i "s'GRR_DB_ADDRESS'$MYSQL_DB_ADDRESS'g" charts/grr/values-gcp.yaml
sed -i "s'PUBSUB_PROJECT_ID'$PROJECT_ID'g" charts/grr/values-gcp.yaml
sed -i "s'PUBSUB_SUBSCRIPTION'$PUBSUB_SUBSCRIPTION'g" charts/grr/values-gcp.yaml
sed -i "s'PUBSUB_TOPIC'$PUBSUB_TOPIC'g" charts/grr/values-gcp.yaml
sed -i "s'PROJECT_ID'$PROJECT_ID'g" charts/grr/values-gcp.yaml
```

#### 2.2.3. Generate the GRR client executable signing keys

```console
# Generate the GRR client executable signing private/public key pair
./charts/grr/createSigningKeys.sh
```

#### 2.2.4. Install the Chart

```console
helm install grr-on-k8s ./charts/grr -f ./charts/grr/values-gcp.yaml
```

#### 2.2.5. Wait for all GRR pods to be in 'Running' status

```console
# Check that all the pods are in the 'Running' status.
kubectl get pods -n grr
# The output should look something like the below:
# NAME                                     READY STATUS  RESTARTS AGE
# dpl-fleetspeak-admin-7f5c6ff877-4x89d    1/1   Running 0        1m34s
# dpl-fleetspeak-frontend-856dd98bf5-ljhds 1/1   Running 0        1m34s
# dpl-grr-admin-78b67cfc76-rjwp2           1/1   Running 0        1m33s
# dpl-grr-frontend-69fd89c495-vlk54        1/1   Running 0        1m34s
# dpl-grr-worker-7d69984fc8-z82k7          1/1   Running 0        1m33s
```

### 2.3. Add the NEG to the Backend Service

This step is very important. We need to add the Standalone Network Endpoint Group (NEG) to the Backend Service of our GLB7.
See the [Google Cloud online docs](https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg#standalone_negs) for more info on Standalone NEGs.

Both GKE and the Terraform scripts have done their half.
It is our job to glue them together.

```console
# Get the NEG
gcloud compute network-endpoint-groups list
# The output should look something like the below:
# NAME: k8s-fleetspeak-frontend-neg
# LOCATION: europe-west1-b
# ENDPOINT_TYPE: GCE_VM_IP_PORT
# SIZE: 1

# Get the Backend Service
# The output should look something like the below:
gcloud compute backend-services list
# NAME: l7-xlb-backend-service
# BACKENDS:
# PROTOCOL: HTTPS

# Add the NEG to the Backend Service
gcloud compute backend-services add-backend l7-xlb-backend-service \
  --global \
  --network-endpoint-group=k8s-fleetspeak-frontend-neg \
  --network-endpoint-group-zone=$ZONE \
  --balancing-mode RATE \
  --max-rate-per-endpoint 5
```

### 2.4. Testing

Let's go and test the setup.
To do so we need three things:

- Build the GRR client container image, and
- Deploy the GRR client, and
- Access to the GRR Admin UI

#### 2.4.1. Build the GRR client container image

```console
cd charts/grr/

# Prepare the GRR client builder Kubernetes Job
sed -i "s'GRR_CLIENT_IMAGE'$GRR_CLIENT_IMAGE'g" job-build-grr-client.yaml
sed -i "s'FRONTEND_ADDRESS'$FLEETSPEAK_FRONTEND'g" job-build-grr-client.yaml 

# Build the GRR client container image
kubectl apply -f job-build-grr-client.yaml

# Wait for the build job to complete
# You can follow the build process progress with the following command:
kubectl logs -f job-grr-client-builder-xxxxx -n grr

cd $REPO
```

Once the Kubernetes Job has completed building the ```grr-client``` container image you can deploy it following the instructions in the next section.

#### 2.4.2. Deploy the GRR client

This will spin up a pod with the GRR client as a daemonset on the selected node.
We can interact with in the next step.

```console
# Find your node names
kubectl get nodes
# The output should look similar to the below:
# NAME                                             STATUS   ROLES    AGE   VERSION
# gke-osdfir-cluster-grr-node-pool-7b71cc80-s84g   Ready    <none>   18m   v1.27.8-gke.1067004
# gke-osdfir-cluster-grr-node-pool-7b71cc80-z8wp   Ready    <none>   18m   v1.27.8-gke.1067004

# Chose one of the node names and replace it in the command below.
# Then run the below command to label the node so it receives a grr daemonset.
kubectl label nodes gke-osdfir-cluster-grr-node-pool-7b71cc80-s84g grrclient=installed

# This will trigger the grr daemonset to be deployed to this node.
# You can check that the daemonset is running by issueing the command below:
kubectl get daemonset -n grr-client
# The output should look something like the below:
# NAME DESIRED CURRENT READY UP-TO-DATE AVAILABLE NODE SELECTOR       AGE
# grr  1       1       1     1          1         grrclient=installed 15m

# You can also check that the pod is in the 'Running' status.
kubectl get pods -n grr-client
# The output should look something like the below:
# NAME      READY STATUS  RESTARTS AGE
# grr-7cc7l 1/1   Running 0        13s
```

#### 2.4.3. Create a tunnel to access the GRR Admin UI

```console
gcloud container clusters get-credentials $GKE_CLUSTER_NAME --zone $GKE_CLUSTER_LOCATION --project $PROJECT_ID \
 && kubectl port-forward -n grr \
    $(kubectl get pod -n grr --selector="app.kubernetes.io/name=grr-admin" --output jsonpath='{.items[0].metadata.name}') 8000:8000
```

You can now point your browser at: [http://127.0.0.1:8000](http:127.0.0.1:8000) to access the GRR Admin UI.

In case you would like to test collecting ```containerd``` forensic artifacts then you can upload the ```ContainerdArtifacts.yaml``` definition file.
This file contains an artifact group with a set of 6 ```containerd``` specific artifacts.
Note: These artifacts are enabled in the container image we use for the ```daemonset``` based GRR client we installed above.
You will not be able to run these artifacts on a 'standard' GRR client.

## 3. Cleaning up

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

Here is the full set of steps to do a sequential build back:

```console
# Remove the GRR client (daemonset)
# Make sure you substitute the node name with your value
kubectl label nodes --overwrite gke-osdfir-cluster-grr-node-pool-7b71cc80-s84g grrclient=

# Rempove the NEG from the Backend Service
gcloud compute backend-services remove-backend l7-xlb-backend-service \
  --global \
  --network-endpoint-group=k8s-fleetspeak-frontend-neg \
  --network-endpoint-group-zone=$ZONE
```

### 3.3. Uninstalling the Chart

To uninstall/delete a Helm deployment with a release name of `grr-on-k8s`:

```console
helm uninstall grr-on-k8s
```

> **Tip**: Please update based on the release name chosen. You can list all releases using `helm list`

## Parameters

### Global parameters

| Name                         | Description                                                    | Value   |
| ---------------------------- | -------------------------------------------------------------- | ------- |
| `global.selfManagedMysql`    | Enables a mySQL DB containter to be deployed into the cluster. | `true`  |
| `global.useResourceRequests` | Allocates resources to the pods.                               | `false` |

### Fleetspeak parameters

| Name                                   | Description                                                                                       | Value                               |
| -------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------- |
| `fleetspeak.generateCert`              | Enables the generation of self-signed Fleetspeak x509 certificate.                                | `true`                              |
| `fleetspeak.httpsHeaderChecksum`       | Defines on whether to add a HTTPS header checksum                                                 | `false`                             |
| `fleetspeak.subjectCommonName`         | Sets the Fleetspeak x509 certificate subject common name.                                         | `fleetspeak-frontend`               |
| `fleetspeak.admin.image`               | Sets the Fleetspeak admin container image to use.                                                 | `ghcr.io/google/fleetspeak:v0.1.17` |
| `fleetspeak.admin.listenPort`          | Sets the Fleetspeak admin listen port to use.                                                     | `4444`                              |
| `fleetspeak.admin.replicas`            | Sets the amount of Fleetspeak admin pods to run.                                                  | `1`                                 |
| `fleetspeak.frontend.healthCheckPort`  | Sets the Fleetspeak frontend health check port to use.                                            | `8080`                              |
| `fleetspeak.frontend.image`            | Sets the Fleetspeak fronend container image to use.                                               | `ghcr.io/google/fleetspeak:v0.1.17` |
| `fleetspeak.frontend.listenPort`       | Sets the Fleetspeak frontend listen port to use.                                                  | `4443`                              |
| `fleetspeak.frontend.neg`              | Enables the creation of a istandalone Network Endpoint Group for the Fleetspeak frontend service. | `false`                             |
| `fleetspeak.frontend.notificationPort` | Sets the Fleetspeak frontend notificaton port to use.                                             | `12000`                             |
| `fleetspeak.frontend.replicas`         | Sets the amount of Fleetspeak frontend pods to run.                                               | `1`                                 |
| `fleetspeak.mysqlDb.address`           | Sets the Fleetspeak DB address to use.                                                            | `mysql`                             |
| `fleetspeak.mysqlDb.name`              | Sets the Fleetspeak DB name to use.                                                               | `fleetspeak`                        |
| `fleetspeak.mysqlDb.port`              | Sets the Fleetspeak DB port to use.                                                               | `3306`                              |
| `fleetspeak.mysqlDb.userName`          | Sets the Fleetspeak DB user name to use.                                                          | `fleetspeak-user`                   |
| `fleetspeak.mysqlDb.userPassword`      | Sets the Fleetspeak DB password to use.                                                           | `fleetspeak-password`               |

### GRR parameters

| Name                         | Description                                             | Value                                 |
| ---------------------------- | ------------------------------------------------------- | ------------------------------------- |
| `grr.admin.image`            | Sets the GRR admin container image to use.              | `ghcr.io/google/grr:v3.4.7.5-release` |
| `grr.admin.listenPort`       | Sets the GRR admin listen port to use.                  | `8000`                                |
| `grr.admin.replicas`         | Sets the amount of GRR admin pods to run.               | `1`                                   |
| `grr.daemon.image`           | Sets the GRR client container image to use.             | `grr-client:v0.1`                     |
| `grr.daemon.imagePullPolicy` | Sets the GRR client container image pull policy to use. | `Never`                               |
| `grr.frontend.image`         | Sets the GRR frontend container image to use.           | `ghcr.io/google/grr:v3.4.7.5-release` |
| `grr.frontend.listenPort`    | Sets the GRR frontend listen port to use.               | `11111`                               |
| `grr.frontend.replicas`      | Sets the amount of GRR frontend pods to run.            | `1`                                   |
| `grr.mysqlDb.address`        | Sets the GRR DB address to use.                         | `mysql`                               |
| `grr.mysqlDb.name`           | Sets the GRR DB name to use                             | `grr`                                 |
| `grr.mysqlDb.port`           | Sets the GRR DB port to use.                            | `3306`                                |
| `grr.mysqlDb.userName`       | Sets the GRR DB user name to use.                       | `grr-user`                            |
| `grr.mysqlDb.userPassword`   | Sets the GRR DB user password to use.                   | `grr-password`                        |
| `grr.worker.image`           | Sets the GRR worker container image to use.             | `ghcr.io/google/grr:v3.4.7.5-release` |

### Prometheus parameters

| Name                     | Description                                 | Value   |
| ------------------------ | ------------------------------------------- | ------- |
| `prometheus.metricsPort` | Sets the port to expose Prometheus metrics. | `19090` |


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
