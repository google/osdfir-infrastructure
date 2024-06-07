# Yeti Helm Chart

Yeti is a open-source platform meant to organize observables, indicators of compromise, TTPs, and knowledge on threats
in a single, unified repository

[Overview of Yeti](https://yeti-platform.github.io/)

[Chart Source Code](https://github.com/google/osdfir-infrastructure)

## TL;DR

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm install my-release osdfir-charts/yeti
```

> **Note**: By default, Yeti is not externally accessible and can be
reached via `kubectl port-forward` within the cluster.

For a quick start with a local Kubernetes cluster on your desktop, check out the
[getting started with Minikube guide](https://github.com/google/osdfir-infrastructure/blob/main/docs/getting-started.md).

## Introduction

This chart bootstraps a [Yeti](https://github.com/yeti-platform/yeti-docker/tree/main/prod)
deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

The first step is to add the repo and then update to pick up any new changes.

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm repo update
```

To install the chart, specify any release name of your choice. For example, using `my-release` as the release name, run:

```console
helm install my-release osdfir-charts/yeti
```

The command deploys Yeti on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

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

> **Note**: Deleting the PVC's will delete Yeti data as well. Please be cautious before doing it.

## Parameters

### Global parameters

| Name                            | Description                                                                                                 | Value   |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------- |
| `global.timesketch.enabled`     | Enables the Timesketch deployment (only used in the main OSDFIR Infrastructure Helm chart)                  | `false` |
| `global.timesketch.servicePort` | Timesketch service port (overrides `timesketch.service.port`)                                               | `nil`   |
| `global.turbinia.enabled`       | Enables the Turbinia deployment (only used within the main OSDFIR Infrastructure Helm chart)                | `false` |
| `global.turbinia.servicePort`   | Turbinia API service port (overrides `turbinia.service.port`)                                               | `nil`   |
| `global.yeti.enabled`           | Enables the Yeti deployment (only used in the main OSDFIR Infrastructure Helm chart)                        | `false` |
| `global.yeti.servicePort`       | Yeti API service port (overrides `yeti.api.service.port`)                                                   | `nil`   |
| `global.ingress.enabled`        | Enable the global loadbalancer for external access (only used in the main OSDFIR Infrastructure Helm chart) | `false` |
| `global.existingPVC`            | Existing claim for Yeti persistent volume (overrides `persistent.name`)                                     | `""`    |
| `global.storageClass`           | StorageClass for the Yeti persistent volume (overrides `persistent.storageClass`)                           | `""`    |

### Yeti configuration


### Yeti frontend configuration

| Name                              | Description                                                               | Value                        |
| --------------------------------- | ------------------------------------------------------------------------- | ---------------------------- |
| `frontend.image.repository`       | Yeti frontend image repository                                            | `yetiplatform/yeti-frontend` |
| `frontend.image.pullPolicy`       | Yeti image pull policy                                                    | `Always`                     |
| `frontend.image.tag`              | Overrides the image tag whose default is the chart appVersion             | `latest`                     |
| `frontend.image.imagePullSecrets` | Specify secrets if pulling from a private repository                      | `[]`                         |
| `frontend.podSecurityContext`     | Holds pod-level security attributes and common server container settings  | `{}`                         |
| `frontend.securityContext`        | Holds security configuration that will be applied to the server container | `{}`                         |
| `frontend.resources.limits`       | Resource limits for the frontend container                                | `{}`                         |
| `frontend.resources.requests`     | Requested resources for the frontend container                            | `{}`                         |
| `frontend.nodeSelector`           | Node labels for Yeti frontend pods assignment                             | `{}`                         |
| `frontend.tolerations`            | Tolerations for Yeti frontend pods assignment                             | `[]`                         |
| `frontend.affinity`               | Affinity for Yeti frontend pods assignment                                | `{}`                         |

### Yeti api configuration

| Name                         | Description                                                            | Value               |
| ---------------------------- | ---------------------------------------------------------------------- | ------------------- |
| `api.image.repository`       | Yeti API image repository                                              | `yetiplatform/yeti` |
| `api.image.pullPolicy`       | Yeti image pull policy                                                 | `Always`            |
| `api.image.tag`              | Overrides the image tag whose default is the chart appVersion          | `latest`            |
| `api.image.imagePullSecrets` | Specify secrets if pulling from a private repository                   | `[]`                |
| `api.podSecurityContext`     | Holds pod-level security attributes and common API container settings  | `{}`                |
| `api.securityContext`        | Holds security configuration that will be applied to the API container | `{}`                |
| `api.resources.limits`       | Resource limits for the API container                                  | `{}`                |
| `api.resources.requests`     | Requested resources for the API container                              | `{}`                |
| `api.nodeSelector`           | Node labels for Yeti API pods assignment                               | `{}`                |
| `api.tolerations`            | Tolerations for Yeti API pods assignment                               | `[]`                |
| `api.affinity`               | Affinity for Yeti API pods assignment                                  | `{}`                |

### Yeti Tasks configuration

| Name                           | Description                                                              | Value               |
| ------------------------------ | ------------------------------------------------------------------------ | ------------------- |
| `tasks.image.repository`       | Yeti tasks image repository                                              | `yetiplatform/yeti` |
| `tasks.image.pullPolicy`       | Yeti image pull policy                                                   | `Always`            |
| `tasks.image.tag`              | Overrides the image tag whose default is the chart appVersion            | `latest`            |
| `tasks.image.imagePullSecrets` | Specify secrets if pulling from a private repository                     | `[]`                |
| `tasks.podSecurityContext`     | Holds pod-level security attributes and common tasks container settings  | `{}`                |
| `tasks.securityContext`        | Holds security configuration that will be applied to the tasks container | `{}`                |
| `tasks.resources.limits`       | Resource limits for the tasks container                                  | `{}`                |
| `tasks.resources.requests`     | Requested resources for the tasks container                              | `{}`                |
| `tasks.nodeSelector`           | Node labels for Yeti tasks pods assignment                               | `{}`                |
| `tasks.tolerations`            | Tolerations for Yeti tasks pods assignment                               | `[]`                |
| `tasks.affinity`               | Affinity for Yeti tasks pods assignment                                  | `{}`                |

### Common Parameters

| Name                              | Description                                                                                                                        | Value               |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `serviceAccount.create`           | Specifies whether a service account should be created                                                                              | `true`              |
| `serviceAccount.annotations`      | Annotations to add to the service account                                                                                          | `{}`                |
| `serviceAccount.name`             | The name of the service account to use                                                                                             | `yeti`              |
| `service.type`                    | Yeti service type                                                                                                                  | `ClusterIP`         |
| `service.port`                    | Yeti service port                                                                                                                  | `9000`              |
| `metrics.enabled`                 | Enables metrics scraping                                                                                                           | `true`              |
| `metrics.port`                    | Port to scrape metrics from                                                                                                        | `9200`              |
| `persistence.name`                | Yeti persistent volume name                                                                                                        | `yetivolume`        |
| `persistence.size`                | Yeti persistent volume size                                                                                                        | `2Gi`               |
| `persistence.storageClass`        | PVC Storage Class for Yeti volume                                                                                                  | `""`                |
| `persistence.accessModes`         | PVC Access Mode for Yeti volume                                                                                                    | `["ReadWriteOnce"]` |
| `ingress.enabled`                 | Enable the Yeti loadbalancer for external access                                                                                   | `false`             |
| `ingress.host`                    | Domain name Yeti will be hosted under                                                                                              | `""`                |
| `ingress.className`               | IngressClass that will be be used to implement the Ingress                                                                         | `gce`               |
| `ingress.selfSigned`              | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                                       | `false`             |
| `ingress.certManager`             | Add the corresponding annotations for cert-manager integration                                                                     | `false`             |
| `ingress.gcp.managedCertificates` | Enables GCP managed certificates for your domain                                                                                   | `false`             |
| `ingress.gcp.staticIPName`        | Name of the static IP address you reserved in GCP. Required when using "gce" in ingress.className                                  | `""`                |
| `ingress.gcp.staticIPV6Name`      | Name of the static IPV6 address you reserved in GCP. This can be optionally provided to deploy a loadbalancer with an IPV6 address | `""`                |

### Third Party Configuration


### Redis Configuration Parameters

| Name                                | Description                                                                                  | Value       |
| ----------------------------------- | -------------------------------------------------------------------------------------------- | ----------- |
| `redis.enabled`                     | Enables the Redis deployment                                                                 | `true`      |
| `redis.auth.enabled`                | Enables Redis Authentication. Disabled due to incompatibility with Yeti                      | `false`     |
| `redis.sentinel.enabled`            | Enables Redis Sentinel on Redis pods                                                         | `false`     |
| `redis.master.count`                | Number of Redis master instances to deploy (experimental, requires additional configuration) | `1`         |
| `redis.master.service.type`         | Redis master service type                                                                    | `ClusterIP` |
| `redis.master.service.ports.redis`  | Redis master service port                                                                    | `6379`      |
| `redis.master.persistence.size`     | Redis master Persistent Volume size                                                          | `2Gi`       |
| `redis.master.resources.limits`     | The resources limits for the Redis master containers                                         | `{}`        |
| `redis.master.resources.requests`   | The requested resources for the Redis master containers                                      | `{}`        |
| `redis.replica.replicaCount`        | Number of Redis replicas to deploy                                                           | `0`         |
| `redis.replica.service.type`        | Redis replicas service type                                                                  | `ClusterIP` |
| `redis.replica.service.ports.redis` | Redis replicas service port                                                                  | `6379`      |
| `redis.replica.persistence.size`    | Redis replica Persistent Volume size                                                         | `2Gi`       |
| `redis.replica.resources.limits`    | The resources limits for the Redis replica containers                                        | `{}`        |
| `redis.replica.resources.requests`  | The requested resources for the Redis replica containers                                     | `{}`        |

### Yeti Arangodb configuration

| Name                              | Description                                                                 | Value       |
| --------------------------------- | --------------------------------------------------------------------------- | ----------- |
| `arangodb.image.repository`       | Yeti arangodb image repository                                              | `arangodb`  |
| `arangodb.image.pullPolicy`       | Yeti image pull policy                                                      | `Always`    |
| `arangodb.image.tag`              | Overrides the image tag whose default is the chart appVersion               | `3.11.8`    |
| `arangodb.image.imagePullSecrets` | Specify secrets if pulling from a private repository                        | `[]`        |
| `arangodb.service.type`           | Yeti service type                                                           | `ClusterIP` |
| `arangodb.service.port`           | Yeti service port                                                           | `8529`      |
| `arangodb.podSecurityContext`     | Holds pod-level security attributes and common server container settings    | `{}`        |
| `arangodb.securityContext`        | Holds security configuration that will be applied to the arangodb container | `{}`        |
| `arangodb.resources.limits`       | Resource limits for the arangodb container                                  | `{}`        |
| `arangodb.resources.requests`     | Requested resources for the arangodb container                              | `{}`        |
| `arangodb.nodeSelector`           | Node labels for Yeti arangodb pods assignment                               | `{}`        |
| `arangodb.tolerations`            | Tolerations for Yeti arangodb pods assignment                               | `[]`        |
| `arangodb.affinity`               | Affinity for Yeti arangodb pods assignment                                  | `{}`        |

Specify each parameter using the --set key=value[,key=value] argument to helm
install. For example,

```console
helm install my-release \
    --set frontend.service.port=443
    oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/yeti
```

The above command installs Yeti with the Frontend service port exposed to 443.

Alternatively, the `values.yaml` file can be directly updated if the Helm chart
was pulled locally. For example,

```console
helm pull osdfir-charts/yeti --untar
```

Then make changes to the downloaded `values.yaml` and once done, install the
chart with the updated values.

```console
helm install my-release ../yeti
```

## Persistence

Persistent Volume Claims are used to keep the data across deployments. This is
known to work in GCP and Minikube. See the Parameters section to configure the
PVC or to disable persistence.

## Upgrading

If you need to upgrade an existing release to update a value, such as persistent
volume size or upgrading to a new release, you can run [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/).
For example, to set a new release and upgrade storage capacity, run:

```console
helm upgrade my-release \
    --set frontend.image.tag=latest
    --set persistence.size=10T
```

The above command upgrades an existing release named `my-release` updating the
Frontend image tag to `latest` and increasing persistent volume size of an existing volume
to 10 Terabytes. Note that existing data will not be deleted and instead triggers an expansion
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
