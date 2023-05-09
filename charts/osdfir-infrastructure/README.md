<!--- app-name: OSDFIR Infrastructure -->
# OSDFIR Infrastructure Helm Chart

A Helm chart for OSDFIR Infrastructure. OSDFIR Infrastructure helps setup Open Source
Digital Forensics tools to Kubernetes clusters using Helm. 

Currently, OSDFIR Infrastructure
supports the deployment of the following tools:
  * Timesketch; ref https://github.com/google/timesketch
  * Turbinia; ref https://github.com/google/turbinia

## TL;DR

```console
helm install my-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```
> **Tip**: To quickly get started with your own local Kubernetes cluster, see 
install docs for [minikube](https://minikube.sigs.k8s.io/docs/start/).

## Introduction

This chart bootstraps a OSDFIR Infrastructure deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure

> **Note**: Due to Turbinia requiring additional permissions for attaching 
persistent disks, currently only Google Kubernetes Engine (GKE) and Local 
Kubernetes installations are supported at this time. See 
[GKE Installations](#gke-installations) for deploying to GKE.

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

To pull the chart locally:
```console
helm pull oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

To install the chart from a local repo with the release name `my-release`:
```console
helm install my-release ../osdfir-infrastructure
```

The install command deploys OSDFIR Infrastructure on the Kubernetes cluster in the default 
configuration without any resources defined. This is so we can increase the 
chances our chart runs on environments with little resources, such as Minikube. 
The [Parameters](#parameters) section lists the parameters that can be configured 
during installation or see [Installating for Production](#installing-for-production) 
for a recommended production installation.

## Installing for Production

Pull the chart locally and review the `values.production.yaml` file for a list 
of values that will be overridden as part of this installation. 
```console
helm pull oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

### GKE Installations
Please ensure that a Turbinia GCP service account has been created prior to 
installing the chart. You can use the helper script from the locally pulled 
chart in `tools/create-gcp-sa.sh` to automatically do this for you.

Install the chart providing both the original values and the production values,
and required GCP values with a release name `my-release`:
```console
helm install my-release ../osdfir-infrastructure \
    -f values.yaml \ 
    -f values-production.yaml \
    --set gcp.project=true \
    --set gcp.projectID=<GCP_PROJECT_ID> \
    --set gcp.projectRegion=<GKE_CLUSTER_REGION> \
    --set gcp.projectZone=<GKE_ClUSTER_ZONE>
```

For non GCP production deployments, install the chart providing both the 
original values and the production values with a release name `my-release`:
```console
helm install my-release ../osdfir-infrastructure -f values.yaml -f values-production.yaml
```

To upgrade an existing release name `my-release` using production values, run:
```console
helm upgrade my-release -f values-production.yaml
```

Installing or upgrading a OSDFIR Infrastructure deployment with `values-production.yaml` 
file will override a subset of values in the `values.yaml` file with a recommended
set of resources and replica pods needed for a production OSDFIR Infrastructure installation
and deploys a GCP Filestore persistent volume for shared storage. For non GCP 
installations, please update the `persistence.storageClass` value with a 
storageClass supported by your provider.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```
> **Tip**: List all releases using `helm list`

The command removes all the Kubernetes components but PVC's associated with the chart and deletes the release.

To delete the PVC's associated with `my-release`:

```console
kubectl delete pvc -l release=my-release
```

> **Note**: Deleting the PVC's will delete OSDFIR Infrastructure data as well. Please be cautious before doing it.

## Parameters

### Global parameters

| Name                  | Description                                                                                                                                          | Value          |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `global.existingPVC`  | Existing claim for the OSDFIR Infrastructure persistent volume (overrides `timesketch.persistent.name` and `turbinia.persistent.name`)               | `osdfirvolume` |
| `global.storageClass` | StorageClass for the OSDFIR Infrastructure persistent volume (overrides `timesketch.persistent.storageClass` and `turbinia.persistent.storageClass`) | `""`           |

### OSDFIR Infrastructure persistence storage parameters

| Name                       | Description                                                 | Value               |
| -------------------------- | ----------------------------------------------------------- | ------------------- |
| `persistence.enabled`      | Enables persistent volume storage for OSDFIR Infrastructure | `true`              |
| `persistence.name`         | OSDFIR Infrastructure persistent volume name                | `osdfirvolume`      |
| `persistence.size`         | OSDFIR Infrastructure persistent volume size                | `8Gi`               |
| `persistence.storageClass` | PVC Storage Class for OSDFIR Infrastructure volume          | `""`                |
| `persistence.accessModes`  | PVC Access Mode for the OSDFIR Infrastructure volume        | `["ReadWriteOnce"]` |

### Timesketch Configuration

| Name                                          | Description                                                                                                                           | Value                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| `timesketch.enabled`                          | Enables the Timesketch deployment                                                                                                     | `true`                                                    |
| `timesketch.image.repository`                 | Timesketch image repository                                                                                                           | `us-docker.pkg.dev/osdfir-registry/timesketch/timesketch` |
| `timesketch.image.tag`                        | Overrides the image tag whose default is the chart appVersion                                                                         | `latest`                                                  |
| `timesketch.config.override`                  | Overrides the default Timesketch configs to instead use a user specified directory if present on the root directory of the Helm chart | `configs/*`                                               |
| `timesketch.config.createUser`                | Creates a default Timesketch user that can be used to login to Timesketch after deployment                                            | `true`                                                    |
| `timesketch.frontend.resources.limits`        | The resources limits for the frontend container                                                                                       | `{}`                                                      |
| `timesketch.frontend.resources.requests`      | The requested resources for the frontend container                                                                                    | `{}`                                                      |
| `timesketch.worker.resources.limits`          | The resources limits for the worker container                                                                                         | `{}`                                                      |
| `timesketch.worker.resources.requests.cpu`    | The requested cpu for the worker container                                                                                            | `250m`                                                    |
| `timesketch.worker.resources.requests.memory` | The requested memory for the worker container                                                                                         | `256Mi`                                                   |

### Timesketch Third Party


### Opensearch Configuration

| Name                                       | Description                                                                                                 | Value  |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------- | ------ |
| `timesketch.opensearch.enabled`            | Enables the Opensearch deployment                                                                           | `true` |
| `timesketch.opensearch.replicas`           | Number of Opensearch instances to deploy                                                                    | `1`    |
| `timesketch.opensearch.persistence.size`   | Opensearch Persistent Volume size. A persistent volume would be created for each Opensearch replica running | `8Gi`  |
| `timesketch.opensearch.resources.requests` | Requested resources for the Opensearch containers                                                           | `{}`   |

### Redis Configuration

| Name                                          | Description                                                                                  | Value              |
| --------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------ |
| `timesketch.redis.enabled`                    | Enables the Redis deployment                                                                 | `true`             |
| `timesketch.redis.nameOverride`               | Overrides the Redis deployment name                                                          | `timesketch-redis` |
| `timesketch.redis.master.count`               | Number of Redis master instances to deploy (experimental, requires additional configuration) | `1`                |
| `timesketch.redis.master.persistence.size`    | Redis master Persistent Volume size                                                          | `8Gi`              |
| `timesketch.redis.master.resources.limits`    | The resources limits for the Redis master containers                                         | `{}`               |
| `timesketch.redis.master.resources.requests`  | The requested resources for the Redis master containers                                      | `{}`               |
| `timesketch.redis.replica.replicaCount`       | Number of Redis replicas to deploy                                                           | `0`                |
| `timesketch.redis.replica.persistence.size`   | Redis replica Persistent Volume size                                                         | `8Gi`              |
| `timesketch.redis.replica.resources.limits`   | The resources limits for the Redis replica containers                                        | `{}`               |
| `timesketch.redis.replica.resources.requests` | The requested resources for the Redis replica containers                                     | `{}`               |

### PostgreSQL Configuration

| Name                                                    | Description                                                     | Value  |
| ------------------------------------------------------- | --------------------------------------------------------------- | ------ |
| `timesketch.postgresql.enabled`                         | Enables the Postgresql deployment                               | `true` |
| `timesketch.postgresql.primary.persistence.size`        | PostgreSQL Persistent Volume size                               | `8Gi`  |
| `timesketch.postgresql.primary.resources.limits`        | The resources limits for the PostgreSQL primary containers      | `{}`   |
| `timesketch.postgresql.primary.resources.requests`      | The requested resources for the PostgreSQL primary containers   | `{}`   |
| `timesketch.postgresql.readReplicas.replicaCount`       | Number of PostgreSQL read only replicas                         | `0`    |
| `timesketch.postgresql.readReplicas.persistence.size`   | PostgreSQL Persistent Volume size                               | `8Gi`  |
| `timesketch.postgresql.readReplicas.resources.limits`   | The resources limits for the PostgreSQL read only containers    | `{}`   |
| `timesketch.postgresql.readReplicas.resources.requests` | The requested resources for the PostgreSQL read only containers | `{}`   |

### Turbinia Configuration

| Name                                                         | Description                                                                                                                                                                                                          | Value                                                                                        |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `turbinia.enabled`                                           | Enables the Turbinia deployment                                                                                                                                                                                      | `true`                                                                                       |
| `turbinia.server.image.repository`                           | Turbinia image repository                                                                                                                                                                                            | `us-docker.pkg.dev/osdfir-registry/turbinia/release/turbinia-server`                         |
| `turbinia.server.image.tag`                                  | Overrides the image tag whose default is the chart appVersion                                                                                                                                                        | `latest`                                                                                     |
| `turbinia.server.resources.limits`                           | Resource limits for the server container                                                                                                                                                                             | `{}`                                                                                         |
| `turbinia.server.resources.requests`                         | Requested resources for the server container                                                                                                                                                                         | `{}`                                                                                         |
| `turbinia.worker.image.repository`                           | Turbinia image repository                                                                                                                                                                                            | `us-docker.pkg.dev/osdfir-registry/turbinia/release/turbinia-worker`                         |
| `turbinia.worker.image.tag`                                  | Overrides the image tag whose default is the chart appVersion                                                                                                                                                        | `latest`                                                                                     |
| `turbinia.worker.autoscaling.enabled`                        | Enables Turbinia Worker autoscaling                                                                                                                                                                                  | `true`                                                                                       |
| `turbinia.worker.autoscaling.minReplicas`                    | Minimum amount of worker pods to run at once                                                                                                                                                                         | `5`                                                                                          |
| `turbinia.worker.autoscaling.maxReplicas`                    | Maximum amount of worker pods to run at once                                                                                                                                                                         | `500`                                                                                        |
| `turbinia.worker.autoscaling.targetCPUUtilizationPercentage` | CPU scaling metric workers will scale based on                                                                                                                                                                       | `80`                                                                                         |
| `turbinia.worker.resources.limits`                           | Resources limits for the worker container                                                                                                                                                                            | `{}`                                                                                         |
| `turbinia.worker.resources.requests.cpu`                     | Requested cpu for the worker container                                                                                                                                                                               | `250m`                                                                                       |
| `turbinia.worker.resources.requests.memory`                  | Requested memory for the worker container                                                                                                                                                                            | `256Mi`                                                                                      |
| `turbinia.api.image.repository`                              | Turbinia image repository for API / Web server                                                                                                                                                                       | `us-docker.pkg.dev/osdfir-registry/turbinia/release/turbinia-api-server`                     |
| `turbinia.api.image.tag`                                     | Overrides the image tag whose default is the chart appVersion                                                                                                                                                        | `latest`                                                                                     |
| `turbinia.api.resources.limits`                              | Resource limits for the api container                                                                                                                                                                                | `{}`                                                                                         |
| `turbinia.api.resources.requests`                            | Requested resources for the api container                                                                                                                                                                            | `{}`                                                                                         |
| `turbinia.controller.enabled`                                | If enabled, deploys the Turbinia controller                                                                                                                                                                          | `false`                                                                                      |
| `turbinia.config.override`                                   | Overrides the default Turbinia config to instead use a user specified config. Please ensure                                                                                                                          | `turbinia.conf`                                                                              |
| `turbinia.config.disabledJobs`                               | List of Turbinia Jobs to disable. Overrides DISABLED_JOBS in the Turbinia config.                                                                                                                                    | `['BinaryExtractorJob', 'BulkExtractorJob', 'HindsightJob', 'PhotorecJob', 'VolatilityJob']` |
| `turbinia.gcp.enabled`                                       | Enables Turbinia to run within a GCP project. When enabling, please ensure you have run the supplemental script `create-gcp-sa.sh` to create a Turbinia GCP service account required for attaching persistent disks. | `false`                                                                                      |
| `turbinia.gcp.projectID`                                     | GCP Project ID where your cluster is deployed. Required when `gcp.enabled` is set to true.                                                                                                                           | `""`                                                                                         |
| `turbinia.gcp.projectRegion`                                 | Region where your cluster is deployed. Required when `gcp.enabled`` is set to true.                                                                                                                                  | `""`                                                                                         |
| `turbinia.gcp.projectZone`                                   | Zone where your cluster is deployed. Required when `gcp.enabled` is set to true.                                                                                                                                     | `""`                                                                                         |
| `turbinia.gcp.gcpLogging`                                    | Enables GCP Cloud Logging                                                                                                                                                                                            | `false`                                                                                      |
| `turbinia.gcp.gcpErrorReporting`                             | Enables GCP Cloud Error Reporting                                                                                                                                                                                    | `false`                                                                                      |

### Turbinia Third Party


### Redis Configuration

| Name                                        | Description                                                                                  | Value            |
| ------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------- |
| `turbinia.redis.enabled`                    | Enables the Redis deployment                                                                 | `true`           |
| `turbinia.redis.nameOverride`               | Overrides the Redis deployment name                                                          | `turbinia-redis` |
| `turbinia.redis.master.count`               | Number of Redis master instances to deploy (experimental, requires additional configuration) | `1`              |
| `turbinia.redis.master.persistence.size`    | Redis master Persistent Volume size                                                          | `8Gi`            |
| `turbinia.redis.master.resources.limits`    | The resources limits for the Redis master containers                                         | `{}`             |
| `turbinia.redis.master.resources.requests`  | The requested resources for the Redis master containers                                      | `{}`             |
| `turbinia.redis.replica.replicaCount`       | Number of Redis replicas to deploy                                                           | `0`              |
| `turbinia.redis.replica.persistence.size`   | Redis replica Persistent Volume size                                                         | `8Gi`            |
| `turbinia.redis.replica.resources.limits`   | The resources limits for the Redis replica containers                                        | `{}`             |
| `turbinia.redis.replica.resources.requests` | The requested resources for the Redis replica containers                                     | `{}`             |

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example,

```console
helm install my-release \
    --set timesketch.config.createUser=false
    oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

The above command updates the Timesketch deployment to not create a default user at deployment.

Alternatively, the `values.yaml` file can be directly updated if the Helm chart 
was pulled locally. For example,

```console
helm pull oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure --untar
```

Then make changes to the downloaded `values.yaml`. A `configs/` directory containing user-provided Timesketch configs can also be placed at this point to override the default ones. Additionally, a `turbinia.conf` config file can be placed at the root of the Helm chart. Once done, install the local chart with the updated values.

```console
helm install my-release ../osdfir-infrastructure
```

Lastly, a YAML file that specifies the values for the parameters can also be provided while installing the chart. For example,

```console
helm install my-release -f newvalues.yaml oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```
## Persistence

The OSDFIR Infrastructure deployment stores data at the `/mnt/osdfir` path of the container.

Persistent Volume Claims are used to keep the data across deployments. By default the OSDFIR Infrastucture deployment attempts to use dynamic persistent volume provisioning to automatically configure storage, but the `persistent.storageClass` value can be updated to a storageClass supported by your provider. See the [Parameters](#parameters) section to configure the PVC or to disable persistence.

To install the OSDFIR Infrastructure chart with more storage capacity, run:
```console
helm install my-release \
    --set persistence.size=10T
    oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

The above command installs the OSDFIR Infrastructure chart with a persistent volume size of 10 Terabytes.

## Upgrading

If you need to upgrade an existing release to update a value in, such as
persistent volume size or upgrading to a new release, you can run 
[helm upgrade](https://helm.sh/docs/helm/helm_upgrade/). For example, to set a 
new release and upgrade storage capacity, run:
```console
helm upgrade my-release \
    --set turbinia.server.image.tag=latest
    --set persistence.size=10T
```

The above command upgrades an existing release named `my-release` updating the
image tag to `latest` and increasing persistent volume size of an existing volume
to 10 Terabytes

## License

Copyright &copy; 2023 OSDFIR Infrastructure

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.