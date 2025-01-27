<!--- app-name: OSDFIR Infrastructure -->
# OSDFIR Infrastructure Helm Chart

OSDFIR Infrastructure helps setup Open Source
Digital Forensics tools to Kubernetes clusters using Helm.

Currently, OSDFIR Infrastructure supports the deployment and integration of the
following tools:

* [dfTimewolf](https://github.com/log2timeline/dftimewolf)
* [Timesketch](https://github.com/google/timesketch)
* [Turbinia](https://github.com/google/turbinia)
* [Yeti](https://github.com/yeti-platform/yeti)

## TL;DR

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm install my-release osdfir-charts/osdfir-infrastructure
```

> **Tip**: To quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

## Introduction

This chart bootstraps a OSDFIR Infrastructure deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

* Kubernetes 1.19+
* Helm 3.2.0+
* PV provisioner support in the underlying infrastructure

> **Note**: For cloud deployments, Turbinia currently only supports attaching disks from GCP environments. Manual disk attachment or utilizing other evidence types is necessary
for other cloud providers.

## Installing the Chart

The first step is to add the repo and then update to pick up any new changes.

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm repo update
```

To install the chart, specify any release name of your choice. For example, using `my-release` as the release name, run:

```console
helm install my-release osdfir-charts/osdfir-infrastructure
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured
during installation or see [Installating for Production](#installing-for-production)
for a recommended production installation.

## Installing for Production

Pull the chart locally then cd into `/osdfir-infrastructure` and review the `values-production.yaml` file for a list of values that will be used for production.

```console
helm pull osdfir-charts/osdfir-infrastructure --untar
```

### Enabling GCP Disk processing for Turbinia

Follow this section for enabling GCP disk processing for Turbinia.

Create a Turbinia GCP account using the helper script in `osdfir-infrastructure/charts/turbinia/tools/create-gcp-sa.sh` prior to installing the chart.

Install the chart with the base values in `values.yaml`, the production values in `values-production.yaml`, and set appropriate values to enable GCP for Turbinia. Using the release name `my-release`, run:

```console
helm install my-release ../osdfir-infrastructure \
    -f values.yaml \ 
    -f values-production.yaml \
    --set turbinia.gcp.enabled=true \
    --set turbinia.gcp.projectID=<GCP_PROJECT_ID> \
    --set turbinia.gcp.projectRegion=<GKE_CLUSTER_REGION> \
    --set turbinia.gcp.projectZone=<GKE_ClUSTER_ZONE>
```

### Enabling GKE Ingress and OIDC Authentication

This section guides you in exposing Turbinia, Timesketch, and Yeti externally.
Additionally, you will enable OpenID Connect for Turbinia and Timesketch user
access. Yeti, currently unsupported by OpenID Connect, will be deployed with
local authentication.

1. Create a global static IP address:

    ```console
    gcloud compute addresses create timesketch-webapps --global
    ```

2. Register a new domain or use an existing one, ensuring a DNS entry
points to the IP created earlier.

3. Create OAuth web client credentials following the [Google Support guide](https://support.google.com/cloud/answer/6158849). If using the CLI client, also create a Desktop/Native
OAuth client.
   * Fill in Authorized JavaScript origins with your domain as `https://<turbinia.DOMAIN_NAME>.com` and `https://<timesketch.DOMAIN_NAME>.com`
   * Fill in Authorized redirect URIs with `https://<timesketch.DOMAIN_NAME>.com/google_openid_connect/` and `https://<turbinia.DOMAIN_NAME>.com/oauth2/callback`

4. Store your new OAuth credentials in a K8s secret:

    ```console
    kubectl create secret generic oauth-secrets \
        --from-literal=client-id=<WEB_CLIENT_ID> \
        --from-literal=client-secret=<WEB_CLIENT_SECRET> \
        --from-literal=cookie-secret=<COOKIE_SECRET> \
        --from-literal=client-id-native=<NATIVE_CLIENT_ID>
    ```

5. Make a list of allowed emails in a text file, one per line:

    ```console
    touch authenticated-emails.txt
    ```

6. Apply the authenticated email list as a K8s secret:

    ```console
    kubectl create secret generic authenticated-emails --from-file=authenticated-emails-list=authenticated-emails.txt
    ```

7. Then to upgrade an existing release with production values, externally expose
   Timesketch, Turbinia, and Yeti through a loadbalancer, add SSL through
   GCP managed certificates, and enable Turbinia and Timesketch
   OIDC for authentication, run:

    ```console
    helm upgrade my-release ../osdfir-infrastructure \
        -f values-production.yaml \
        --set global.ingress.enabled=true \
        --set global.ingress.gcp.staticIPName=<STATIC_IP_NAME> \
        --set global.ingress.gcp.managedCertificates=true \
        --set timesketch.ingress.host=<timesketch.DOMAIN_NAME.com> \
        --set turbinia.ingress.host=<turbinia.<DOMAIN_NAME.com> \
        --set yeti.ingress.host=<yeti.<DOMAIN_NAME.com> \
        --set timesketch.config.oidc.enabled=true \
        --set timesketch.config.oidc.existingSecret=<OAUTH_SECRET_NAME> \
        --set timesketch.config.oidc.authenticatedEmailsFile.existingSecret=<AUTHENTICATED_EMAILS_SECRET_NAME>
        --set turbinia.oauth2proxy.enabled=true \
        --set turbinia.oauth2proxy.configuration.existingSecret=<OAUTH_SECRET_NAME> \
        --set turbinia.oauth2proxy.configuration.authenticatedEmailsFile.existingSecret=<AUTHENTICATED_EMAILS_SECRET_NAME>
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

| Name                                     | Description                                                                                                                        | Value   |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `global.timesketch.enabled`              | Enables the Timesketch deployment (only used in the main OSDFIR Infrastructure Helm chart)                                         | `true`  |
| `global.yeti.enabled`                    | Enables the Yeti deployment (only used in the main OSDFIR Infrastructure Helm chart)                                               | `true`  |
| `global.ingress.enabled`                 | Enable the global loadbalancer for external access (only used in the main OSDFIR Infrastructure Helm chart)                        | `false` |
| `global.ingress.timesketchHost`          | Domain name Timesketch will be hosted under                                                                                        | `""`    |
| `global.ingress.yetiHost`                | Domain name Yeti will be hosted under                                                                                              | `""`    |
| `global.ingress.className`               | IngressClass that will be be used to implement the Ingress                                                                         | `""`    |
| `global.ingress.selfSigned`              | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                                       | `false` |
| `global.ingress.certManager`             | Add the corresponding annotations for cert-manager integration                                                                     | `false` |
| `global.ingress.gcp.managedCertificates` | Enabled GCP managed certificates for your domain                                                                                   | `false` |
| `global.ingress.gcp.staticIPName`        | Name of the static IP address you reserved in GCP                                                                                  | `""`    |
| `global.ingress.gcp.staticIPV6Name`      | Name of the static IPV6 address you reserved in GCP. This can be optionally provided to deploy a loadbalancer with an IPV6 address | `""`    |

### Timesketch configuration


### Timesketch Configuration Parameters

| Name                                                            | Description                                                                                | Value   |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------- |
| `timesketch.config.existingConfigMap`                           | Use an existing ConfigMap as the default Timesketch config.                                | `""`    |
| `timesketch.config.createUser`                                  | Creates a default Timesketch user that can be used to login to Timesketch after deployment | `true`  |
| `timesketch.config.oidc.enabled`                                | Enables Timesketch OIDC authentication (currently only supports Google OIDC)               | `false` |
| `timesketch.config.oidc.existingSecret`                         | Existing secret with the client ID, secret and cookie secret                               | `""`    |
| `timesketch.config.oidc.authenticatedEmailsFile.enabled`        | Enables email authentication                                                               | `true`  |
| `timesketch.config.oidc.authenticatedEmailsFile.existingSecret` | Existing secret with a list of emails                                                      | `""`    |
| `timesketch.config.oidc.authenticatedEmailsFile.content`        | Allowed emails list (one email per line)                                                   | `""`    |
| `timesketch.frontend.resources.limits`                          | The resources limits for the frontend container                                            | `{}`    |
| `timesketch.frontend.resources.requests`                        | The requested resources for the frontend container                                         | `{}`    |
| `timesketch.frontend.nodeSelector`                              | Node labels for Timesketch frontend pods assignment                                        | `{}`    |

### Timesketch Worker Configuration

| Name                                              | Description                                                                                                 | Value               |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------- |
| `timesketch.worker.resources.limits`              | The resources limits for the worker container                                                               | `{}`                |
| `timesketch.worker.resources.requests.cpu`        | The requested cpu for the worker container                                                                  | `250m`              |
| `timesketch.worker.resources.requests.memory`     | The requested memory for the worker container                                                               | `256Mi`             |
| `timesketch.worker.nodeSelector`                  | Node labels for Timesketch worker pods assignment                                                           | `{}`                |
| `timesketch.nginx.resources.limits`               | The resources limits for the nginx container                                                                | `{}`                |
| `timesketch.nginx.resources.requests.cpu`         | The requested cpu for the nginx container                                                                   | `250m`              |
| `timesketch.nginx.resources.requests.memory`      | The requested memory for the nginx container                                                                | `256Mi`             |
| `timesketch.nginx.nodeSelector`                   | Node labels for Timesketch nginx pods assignment                                                            | `{}`                |
| `timesketch.persistence.size`                     | Timesketch persistent volume size                                                                           | `2Gi`               |
| `timesketch.persistence.storageClass`             | PVC Storage Class for Timesketch volume                                                                     | `""`                |
| `timesketch.persistence.accessModes`              | PVC Access Mode for Timesketch volume                                                                       | `["ReadWriteOnce"]` |
| `timesketch.securityContext.enabled`              | Enable SecurityContext for Timesketch pods                                                                  | `true`              |
| `timesketch.opensearch.replicas`                  | Number of Opensearch instances to deploy                                                                    | `1`                 |
| `timesketch.opensearch.sysctlInit.enabled`        | Sets optimal sysctl's through privileged initContainer                                                      | `true`              |
| `timesketch.opensearch.opensearchJavaOpts`        | Sets the size of the Opensearch Java heap                                                                   | `-Xmx512M -Xms512M` |
| `timesketch.opensearch.persistence.size`          | Opensearch Persistent Volume size. A persistent volume would be created for each Opensearch replica running | `2Gi`               |
| `timesketch.opensearch.resources.requests.cpu`    | The requested cpu for the Opensearch container                                                              | `250m`              |
| `timesketch.opensearch.resources.requests.memory` | The requested memory for the Opensearch container                                                           | `512Mi`             |
| `timesketch.opensearch.nodeSelector`              | Node labels for Opensearch pods assignment                                                                  | `{}`                |
| `timesketch.redis.persistence.size`               | Redis Persistent Volume size                                                                                | `2Gi`               |
| `timesketch.redis.resources.limits`               | The resources limits for the Redis containers                                                               | `{}`                |
| `timesketch.redis.resources.requests`             | The requested resources for the Redis containers                                                            | `{}`                |
| `timesketch.redis.nodeSelector`                   | Node labels for Timesketch Redis pods assignment                                                            | `{}`                |

### Postgresql Configuration Parameters

| Name                                              | Description                                                | Value   |
| ------------------------------------------------- | ---------------------------------------------------------- | ------- |
| `timesketch.postgresql.persistence.size`          | PostgreSQL Persistent Volume size                          | `2Gi`   |
| `timesketch.postgresql.resources.limits`          | The resources limits for the PostgreSQL primary containers | `{}`    |
| `timesketch.postgresql.resources.requests.cpu`    | The requested cpu for the PostgreSQL primary containers    | `250m`  |
| `timesketch.postgresql.resources.requests.memory` | The requested memory for the PostgreSQL primary containers | `256Mi` |
| `timesketch.postgresql.nodeSelector`              | Node labels for Timesketch postgresql pods assignment      | `{}`    |
| `yeti.frontend.resources.limits`                  | Resource limits for the frontend container                 | `{}`    |
| `yeti.frontend.resources.requests`                | Requested resources for the frontend container             | `{}`    |
| `yeti.frontend.nodeSelector`                      | Node labels for Yeti frontend pods assignment              | `{}`    |

### Yeti api configuration

| Name                               | Description                                                            | Value   |
| ---------------------------------- | ---------------------------------------------------------------------- | ------- |
| `yeti.api.resources.limits`        | Resource limits for the API container                                  | `{}`    |
| `yeti.api.resources.requests`      | Requested resources for the API container                              | `{}`    |
| `yeti.api.nodeSelector`            | Node labels for Yeti API pods assignment                               | `{}`    |
| `yeti.tasks.resources.limits`      | Resource limits for the tasks container                                | `{}`    |
| `yeti.tasks.resources.requests`    | Requested resources for the tasks container                            | `{}`    |
| `yeti.tasks.nodeSelector`          | Node labels for Yeti tasks pods assignment                             | `{}`    |
| `yeti.config.oidc.enabled`         | Enables Yeti OIDC authentication (currently only supports Google OIDC) | `false` |
| `yeti.config.oidc.existingSecret`  | Existing secret with the client ID, secret and cookie secret           | `""`    |
| `yeti.redis.persistence.size`      | Redis Persistent Volume size                                           | `2Gi`   |
| `yeti.redis.resources.limits`      | The resources limits for the Redis containers                          | `{}`    |
| `yeti.redis.resources.requests`    | The requested resources for the Redis containers                       | `{}`    |
| `yeti.redis.nodeSelector`          | Node labels for Yeti redis pods assignment                             | `{}`    |
| `yeti.arangodb.persistence.size`   | Yeti ArangoDB persistent volume size                                   | `2Gi`   |
| `yeti.arangodb.resources.limits`   | Resource limits for the arangodb container                             | `{}`    |
| `yeti.arangodb.resources.requests` | Requested resources for the arangodb container                         | `{}`    |
| `yeti.arangodb.nodeSelector`       | Node labels for Yeti arangodb pods assignment                          | `{}`    |

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example,

```console
helm install my-release osdfir-charts/osdfir-infrastructure --set turbinia.enabled=false
```

The above command installs OSDFIR Infrastructure without Turbinia deployed.

Alternatively, the `values.yaml` and `values-production.yaml` file can be
directly updated if the Helm chart was pulled locally. For example,

```console
helm pull osdfir-charts/osdfir-infrastructure --untar
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
helm upgrade my-release osdfir-charts/osdfir-infrastructure \
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
