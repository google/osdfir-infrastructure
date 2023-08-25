<!--- app-name: OSDFIR Infrastructure -->
# OSDFIR Infrastructure Helm Chart

OSDFIR Infrastructure helps setup Open Source
Digital Forensics tools to Kubernetes clusters using Helm.

Currently, OSDFIR Infrastructure supports the deployment and integration of the
following tools:

* [Timesketch](https://github.com/google/timesketch)
* [Turbinia](https://github.com/google/turbinia)
* [dfTimewolf](https://github.com/log2timeline/dftimewolf)

## TL;DR

```console
helm install my-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

> **Tip**: To quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

## Introduction

This chart bootstraps a OSDFIR Infrastructure deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

* Kubernetes 1.19+
* Helm 3.2.0+
* PV provisioner support in the underlying infrastructure

> **Note**: Currently Turbinia only supports processing of GCP Persistent Disks and Local Evidence. See [GKE Installations](#gke-installations) for deploying to GKE.

## Installing the Chart

To install the chart, specify any release name of your choice. For example, using `my-release` as the release name, run:

```console
helm install my-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured
during installation or see [Installating for Production](#installing-for-production)
for a recommended production installation.

## Installing for Production

Pull the chart locally then cd into `/osdfir-infrastructure` and review the `values-production.yaml` file for a list of values that will be used for production.

```console
helm pull oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure --untar
```

### GKE Installations

Create a Turbinia GCP account using the helper script in `osdfir-infrastructure/charts/turbinia/tools/create-gcp-sa.sh` prior to installing the chart.

Install the chart with the base values in `values.yaml`, the production values in `values-production.yaml`, and set appropriate values to enable GCP for Turbinia. Using the release name `my-release`, run:

```console
helm install my-release ../osdfir-infrastructure \
    -f values.yaml \ 
    -f values-production.yaml \
    --set turbinia.gcp.project=true \
    --set turbinia.gcp.projectID=<GCP_PROJECT_ID> \
    --set turbinia.gcp.projectRegion=<GKE_CLUSTER_REGION> \
    --set turbinia.gcp.projectZone=<GKE_ClUSTER_ZONE>
```

To upgrade an existing release and externally expose Timesketch through a loadbalancer with SSL through GCP managed certificates, run:

```console
helm upgrade my-release
    --set timesketch.ingress.enabled=true \
    --set timesketch.ingress.host=<DOMAIN_NAME> \
    --set timesketch.ingress.gcp.staticIPName=<STATIC_IP_NAME> \
    --set timesketch.ingress.gcp.managedCertificates=true
```

To upgrade an existing and externally expose Turbinia through a load balancer with SSL through GCP managed certificates, and deploy the Oauth2 Proxy for authentication, run:

```console
helm upgrade my-release \
    -f values.yaml -f values-production.yaml \
    --set turbinia.ingress.enabled=true \
    --set turbinia.ingress.host=<DOMAIN> \
    --set turbinia.ingress.gcp.managedCertificates=true \
    --set turbinia.ingress.gcp.staticIPName=<GCP_STATIC_IP_NAME> \
    --set turbinia.oauth2proxy.enabled=true \
    --set turbinia.oauth2proxy.configuration.clientID=<WEB_OAUTH_CLIENT_ID> \
    --set turbinia.oauth2proxy.configuration.clientSecret=<WEB_OAUTH_CLIENT_SECRET> \
    --set turbinia.oauth2proxy.configuration.nativeClientID=<NATIVE_OAUTH_CLIENT_ID> \
    --set turbinia.oauth2proxy.configuration.cookieSecret=<COOKIE_SECRET> \
    --set turbinia.oauth2proxy.configuration.redirectUrl=https://<DOMAIN>/oauth2/callback \
    --set turbinia.oauth2proxy.configuration.authenticatedEmailsFile.content=\{email1@domain.com, email2@domain.com\} \
    --set turbinia.oauth2proxy.service.annotations."cloud\.google\.com/neg=\{\"ingress\": true\}" \
    --set turbinia.oauth2proxy.service.annotations."cloud\.google\.com/backend-config=\{\"ports\": \{\"4180\": \"\{\{ .Release.Name \}\}-oauth2-backend-config\"\}\}"
```

## Uninstalling the Chart

To uninstall/delete a Helm deployment with a release name of `my-release`:

```console
helm uninstall my-release
```

> **Tip**: Please update based on the release name chosen. You can list all releases using `helm list`

The command removes all the Kubernetes components but Persistent Volumes (PVC) associated with the chart and deletes the release.

To delete the PVC's associated with a release name of `my-release`:

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
| `persistence.size`         | OSDFIR Infrastructure persistent volume size                | `2Gi`               |
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
| `timesketch.opensearch.persistence.size`   | Opensearch Persistent Volume size. A persistent volume would be created for each Opensearch replica running | `2Gi`  |
| `timesketch.opensearch.resources.requests` | Requested resources for the Opensearch containers                                                           | `{}`   |

### Redis configuration

| Name                                          | Description                                                                                  | Value              |
| --------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------ |
| `timesketch.redis.enabled`                    | Enables the Redis deployment                                                                 | `true`             |
| `timesketch.redis.nameOverride`               | Overrides the Redis deployment name                                                          | `timesketch-redis` |
| `timesketch.redis.master.count`               | Number of Redis master instances to deploy (experimental, requires additional configuration) | `1`                |
| `timesketch.redis.master.persistence.size`    | Redis master Persistent Volume size                                                          | `2Gi`              |
| `timesketch.redis.master.resources.limits`    | The resources limits for the Redis master containers                                         | `{}`               |
| `timesketch.redis.master.resources.requests`  | The requested resources for the Redis master containers                                      | `{}`               |
| `timesketch.redis.replica.replicaCount`       | Number of Redis replicas to deploy                                                           | `0`                |
| `timesketch.redis.replica.persistence.size`   | Redis replica Persistent Volume size                                                         | `2Gi`              |
| `timesketch.redis.replica.resources.limits`   | The resources limits for the Redis replica containers                                        | `{}`               |
| `timesketch.redis.replica.resources.requests` | The requested resources for the Redis replica containers                                     | `{}`               |

### PostgreSQL Configuration

| Name                                                    | Description                                                     | Value  |
| ------------------------------------------------------- | --------------------------------------------------------------- | ------ |
| `timesketch.postgresql.enabled`                         | Enables the Postgresql deployment                               | `true` |
| `timesketch.postgresql.primary.persistence.size`        | PostgreSQL Persistent Volume size                               | `2Gi`  |
| `timesketch.postgresql.primary.resources.limits`        | The resources limits for the PostgreSQL primary containers      | `{}`   |
| `timesketch.postgresql.primary.resources.requests`      | The requested resources for the PostgreSQL primary containers   | `{}`   |
| `timesketch.postgresql.readReplicas.replicaCount`       | Number of PostgreSQL read only replicas                         | `0`    |
| `timesketch.postgresql.readReplicas.persistence.size`   | PostgreSQL Persistent Volume size                               | `2Gi`  |
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
| `turbinia.worker.autoscaling.enabled`                        | Enables Turbinia Worker autoscaling                                                                                                                                                                                  | `false`                                                                                      |
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
| `turbinia.gcp.projectID`                                     | GCP Project ID where your cluster is deployed. Required when `.Values.gcp.enabled` is set to `true`                                                                                                                  | `""`                                                                                         |
| `turbinia.gcp.projectRegion`                                 | Region where your cluster is deployed. Required when `.Values.gcp.enabled` is set to `true`                                                                                                                          | `""`                                                                                         |
| `turbinia.gcp.projectZone`                                   | Zone where your cluster is deployed. Required when `.Values.gcp.enabled` is set to `true`                                                                                                                            | `""`                                                                                         |
| `turbinia.gcp.gcpLogging`                                    | Enables GCP Cloud Logging                                                                                                                                                                                            | `false`                                                                                      |
| `turbinia.gcp.gcpErrorReporting`                             | Enables GCP Cloud Error Reporting                                                                                                                                                                                    | `false`                                                                                      |
| `turbinia.serviceAccount.create`                             | Specifies whether a service account should be created                                                                                                                                                                | `true`                                                                                       |
| `turbinia.serviceAccount.annotations`                        | Annotations to add to the service account                                                                                                                                                                            | `{}`                                                                                         |
| `turbinia.serviceAccount.name`                               | The name of the Kubernetes service account to use                                                                                                                                                                    | `turbinia`                                                                                   |
| `turbinia.serviceAccount.gcpName`                            | The name of the GCP service account to annotate. Applied only if `.Values.turbinia.gcp.enabled` is set to `true`                                                                                                     | `turbinia`                                                                                   |
| `turbinia.ingress.enabled`                                   | Enable the Turbinia loadbalancer for external access                                                                                                                                                                 | `false`                                                                                      |
| `turbinia.ingress.host`                                      | The domain name Turbinia will be hosted under                                                                                                                                                                        | `""`                                                                                         |
| `turbinia.ingress.className`                                 | IngressClass that will be be used to implement the Ingress                                                                                                                                                           | `gce`                                                                                        |
| `turbinia.ingress.gcp.managedCertificates`                   | Enabled GCP managed certificates for your domain                                                                                                                                                                     | `false`                                                                                      |
| `turbinia.ingress.gcp.staticIPName`                          | Name of the static IP address you reserved in GCP                                                                                                                                                                    | `""`                                                                                         |
| `turbinia.ingress.gcp.staticIPV6Name`                        | Name of the static IPV6 address you reserved in GCP. This can be optionally provided to deploy a loadbalancer with an IPV6 address                                                                                   | `""`                                                                                         |

### Turbinia Third Party


### Redis Configuration

| Name                                        | Description                                                                                  | Value            |
| ------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------- |
| `turbinia.redis.enabled`                    | Enables the Redis deployment                                                                 | `true`           |
| `turbinia.redis.nameOverride`               | Overrides the Redis deployment name                                                          | `turbinia-redis` |
| `turbinia.redis.master.count`               | Number of Redis master instances to deploy (experimental, requires additional configuration) | `1`              |
| `turbinia.redis.master.persistence.size`    | Redis master Persistent Volume size                                                          | `2Gi`            |
| `turbinia.redis.master.resources.limits`    | The resources limits for the Redis master containers                                         | `{}`             |
| `turbinia.redis.master.resources.requests`  | The requested resources for the Redis master containers                                      | `{}`             |
| `turbinia.redis.replica.replicaCount`       | Number of Redis replicas to deploy                                                           | `0`              |
| `turbinia.redis.replica.persistence.size`   | Redis replica Persistent Volume size                                                         | `2Gi`            |
| `turbinia.redis.replica.resources.limits`   | The resources limits for the Redis replica containers                                        | `{}`             |
| `turbinia.redis.replica.resources.requests` | The requested resources for the Redis replica containers                                     | `{}`             |

### Oauth2 Proxy configuration parameters

| Name                                                                        | Description                                                                                                                                                           | Value                         |
| --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `turbinia.oauth2proxy.enabled`                                              | Enables the Oauth2 Proxy deployment                                                                                                                                   | `false`                       |
| `turbinia.oauth2proxy.containerPort`                                        | Oauth2 Proxy container port                                                                                                                                           | `4180`                        |
| `turbinia.oauth2proxy.service.type`                                         | OAuth2 Proxy service type                                                                                                                                             | `ClusterIP`                   |
| `turbinia.oauth2proxy.service.port`                                         | OAuth2 Proxy service HTTP port                                                                                                                                        | `8080`                        |
| `turbinia.oauth2proxy.service.annotations`                                  | Additional custom annotations for OAuth2 Proxy service                                                                                                                | `{}`                          |
| `turbinia.oauth2proxy.configuration.turbiniaSvcPort`                        | Turbinia service port referenced from `.Values.service.port` to be used in Oauth setup                                                                                | `8000`                        |
| `turbinia.oauth2proxy.configuration.clientID`                               | OAuth client ID for Turbinia Web UI.                                                                                                                                  | `""`                          |
| `turbinia.oauth2proxy.configuration.clientSecret`                           | OAuth client secret for Turbinia Web UI.                                                                                                                              | `""`                          |
| `turbinia.oauth2proxy.configuration.nativeClientID`                         | Native Oauth client ID for Turbinia CLI.                                                                                                                              | `""`                          |
| `turbinia.oauth2proxy.configuration.cookieSecret`                           | OAuth cookie secret (e.g. openssl rand -base64 32 )                                                                                                                   | `""`                          |
| `turbinia.oauth2proxy.configuration.content`                                | Oauth2 proxy configuration. Please see the [official docs](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview) for a list of configurable values | `""`                          |
| `turbinia.oauth2proxy.configuration.authenticatedEmailsFile.enabled`        | Enable authenticated emails file                                                                                                                                      | `true`                        |
| `turbinia.oauth2proxy.configuration.authenticatedEmailsFile.content`        | Restricted access list (one email per line). At least one email address is required for the Oauth2 Proxy to properly work                                             | `""`                          |
| `turbinia.oauth2proxy.configuration.authenticatedEmailsFile.existingSecret` | Secret with the authenticated emails file                                                                                                                             | `""`                          |
| `turbinia.oauth2proxy.configuration.oidcIssuerUrl`                          | OpenID Connect issuer URL                                                                                                                                             | `https://accounts.google.com` |
| `turbinia.oauth2proxy.configuration.redirectUrl`                            | OAuth Redirect URL                                                                                                                                                    | `""`                          |
| `turbinia.oauth2proxy.redis.enabled`                                        | Enable Redis for OAuth Session Storage                                                                                                                                | `false`                       |

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example,

```console
helm install my-release \
    --set turbinia.enabled=false
    oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

The above command installs OSDFIR Infrastructure without Turbinia deployed.

Alternatively, the `values.yaml` and `values-production.yaml` file can be
directly updated if the Helm chart was pulled locally. For example,

```console
helm pull oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure --untar
```

Then make changes to the downloaded `values.yaml` and once done, install the
chart with the updated values.

```console
helm install my-release ../osdfir-infrastructure
```

## Persistence

The OSDFIR Infrastructure deployment stores data at the `/mnt/osdfir` path of the container.

Persistent Volume Claims are used to keep the data across deployments. This is
known to work in GCP and Minikube. See the [Parameters](#parameters) section to
configure the PVC or to disable persistence.

## Upgrading

If you need to upgrade an existing release to update a value, such as
persistent volume size or upgrading to a new release, you can run
[helm upgrade](https://helm.sh/docs/helm/helm_upgrade/). For example, to set a
new release and upgrade storage capacity, run:

```console
helm upgrade my-release \
    --set turbinia.server.image.tag=latest \
    --set timesketch.image.tag=latest \
    --set persistence.size=10T
```

The above command upgrades an existing release named `my-release` updating the Turbinia server and Timesketch
image tag to `latest` and increasing persistent volume size of the existing volume to 10 Terabytes. Note that existing data will not be deleted and instead triggers an expansion
of the volume that backs the underlying PersistentVolume. See [here](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

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
