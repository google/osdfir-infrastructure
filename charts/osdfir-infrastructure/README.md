<!--- app-name: OSDFIR Infrastructure -->
# OSDFIR Infrastructure Helm Chart

OSDFIR Infrastructure helps setup Open Source Digital Forensics tools to
Kubernetes clusters using Helm.

Currently, OSDFIR Infrastructure supports the deployment and integration of the
following tools:

* [dfTimewolf](https://github.com/log2timeline/dftimewolf)
* [Timesketch](https://github.com/google/timesketch)
* [Yeti](https://github.com/yeti-platform/yeti)

## TL;DR

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm install my-release osdfir-charts/osdfir-infrastructure
```

> **Note**: By default, OSDFIR Infrastructure is not externally accessible and
applications can be reached via `kubectl port-forward` within the cluster.

## Introduction

This chart bootstraps a OSDFIR Infrastructure deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

* Kubernetes 1.23+
* Helm 3.2.0+
* PV provisioner support in the underlying infrastructure

> **Tip**: To quickly get started with a local cluster, see
[minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

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

The command deploys OSDFIR Infrastructure on the Kubernetes cluster in the
default configuration. The [Parameters](#parameters) section lists the parameters
that can be configured during installation.

## Configuration and installation details

OSDFIR Infrastructure actively monitors for new versions of the main containers
and releases updated charts accordingly. However, if you'd like to introduce a
custom image or tag, please refer to the steps below.

### Managing Timesketch images

The Timesketch container images are managed using the following values,
`timesketch.image.tag` and `timesketch.image.repository`.

To view all configurable values of the Yeti subchart, including the default
image tags and repositories, run the following command:

```console
helm show values osdfir-infrastructure/charts/timesketch
```

Specify the desired image tags and repositories when deploying or upgrading the
OSDFIR Infrastructure chart.

> **Note**: The `helm show values osdfir-infrastructure/charts/timesketch`
command displays parameters as `image.tag` and `image.repository`. However,
because Timesketch is a subchart of OSDFIR Infrastructure, you must prefix these
parameters with `timesketch` when setting them in your `values.yaml` file or using
`--set`. This convention applies to all subcharts within the OSDFIR Infrastructure chart.

### Managing Yeti images

The Yeti container images are managed using the following values,
`yeti.<component>.image.repository` and `yeti.<component>.image.tag`, where
`<component>` is replaced with `frontend`, `api`, or `tasks`.

To view all configurable values of the Yeti subchart, including the default
image tags and repositories, run the following command:

```console
helm show values osdfir-infrastructure/charts/yeti
```

Specify the desired image tags and repositories when deploying or upgrading the
OSDFIR Infrastructure chart.

### Upgrading the Helm chart

Helm chart updates can be retrieved by running `helm repo update`.

To explore available versions, use `helm search repo osdfir-charts/osdfir-infrastructure`.
Install a specific chart version with `helm install my-release osdfir-charts/osdfir-infrastructure --version <version>`.

A major Helm chart version change (like v1.0.0 -> v2.0.0) indicates that there
is an incompatible breaking change needing manual actions.

### Managing the Yeti config

Yeti's configuration is managed through environment variables. To customize
Yeti's configuration, you can:

1. **Modify the `_env.tpl` template:** For advanced customization, you can
directly edit the `_env.tpl` template file: [link to _env.tpl](https://github.com/google/osdfir-infrastructure/blob/main/charts/yeti/templates/_env.tpl). Be aware that changes to this file will be overwritten when
upgrading the chart to a new version unless you manage the template separately.

2. **Request a new environment variable:** If you need to configure a setting
that isn't currently exposed as an environment variable, please submit a
PR to the repository. This is the preferred method for most configuration changes,
as it ensures the changes are maintained across chart upgrades.

### Managing the Timesketch config

If you don't provide your own config files during deployment,
the Timesketch deployment will automatically retrieve the latest default configs
from the Timesketch Github repository. This method requires no further action
from you.

> **NOTE:**  When using the default method, you cannot update the Timesketch
config files directly.

#### Managing Timesketch configs externally

For more advanced configuration management, you can manage Timesketch config
files independently of the Helm chart:

1. Prepare your Config Files:

    Organize all the Timesketch configuration files in a directory with your
    desired customizations.

2. Create a ConfigMap:

    ```console
    kubectl create configmap timesketch-configs --from-file=./timesketch-configs/
    ```

    Replace `./timesketch-configs/` with the actual path to your configuration files.

3. Install or Upgrade the Helm Chart:

    ```console
    helm install my-release osdfir-charts/timesketch --set config.existingConfigMap="timesketch-configs"
    ```

    This command instructs the Helm chart to use the `timesketch-configs` ConfigMap for
    Timesketch's config files.

To update the config changes using this method:

1. Update the ConfigMap:

    ```console
    kubectl create configmap timesketch-configs --from-file=./my-configs/ --dry-run -o yaml | kubectl replace -f -
    ```

2. Restart the Timesketch deployment to apply the new configs

    ```console
    kubectl rollout restart deployment -l app.kubernetes.io/name=timesketch
    ```

#### Upgrading the Timesketch Database Schema

From time to time, a Timesketch release requires a manual database upgrade if
the schema has changed.
The [Timesketch release page](https://github.com/google/timesketch/releases)
will indicate if a database upgrade is required.

Follow these steps to upgrade the database on your Kubernetes deployment:

1. **Upgrade Timesketch (if not already done):**
   * Upgrade your Timesketch deployment to the desired release version:

     ```bash
     helm upgrade my-release osdfir-charts/timesketch --set image.tag=<VERSION> --set image.pullPolicy=Always
     ```

2. **Connect to Timesketch Pod:**
   * Once the upgraded pods are ready, shell into the Timesketch pod:

     ```bash
     kubectl exec -it my-release-timesketch-<RANDOM> -- /bin/bash
     ```

     * Find your pod name using `kubectl get pods`.

3. **Perform Database Upgrade:**
   * Follow the detailed steps in the [Timesketch documentation to upgrade your database](https://timesketch.org/guides/admin/upgrade/#upgrade-the-database-schema).

4. **Restart Timesketch (Recommended):**
   * After a successful database upgrade, it is recommended to restart your
   Timesketch deployment for the changes to take full effect:

      ```bash
      kubectl rollout restart deployment my-release-timesketch-web
      ```

### Resource requests and limits

OSDFIR Infrastructure charts allow setting resource requests and limits for all
containers inside the chart deployment. These are inside the `resources` value
(check parameter table). Setting requests is essential for production workloads
and these should be adapted to your specific use case.

To maximize deployment success across different environments, resources are
minimally defined by default.

### Persistence

The following sections cover how persistent volumes are provisioned for each of
the applications in OSDFIR Infrastructure.

#### Persistence in Timesketch

By default, the chart mounts a Persistent Volume at the
`/mnt/timesketchvolume` path to store uploaded timelines for Timesketch to process.
The volume is created using dynamic volume provisioning.

Configuration files can be found at the `/etc/timesketch` path of the container.

For clusters running more than one nodes or machines, the Timesketch volume will
need to have the ability to be mounted by multiple machines, such as NFS, GCP
Filestore, AWS EFS, and other shared file storage equivalents.

Additionally, persistent volumes are created for Opensearch, Postgres, and Redis
which Timesketch utilizes to store timeline and other configuration data.

#### Persistence in Yeti

Yeti's data persistence relies on two services: ArangoDB and Redis.

* **ArangoDB:** All Yeti Indicators of Compromise (IoCs) and other persistent
data are stored in ArangoDB. The volume automatically gets created during deployment
through dynamic provisioning.
* **Redis:** Redis is used for Yeti's task scheduling.

The volumes for ArangoDB and Redis automatically get created during deployment
through dynamic provisioning.

### Enabling GKE Ingress and OIDC Authentication

For Google Kubernetes Engine (GKE) on Google Cloud Platform (GCP), follow these
steps to expose Timesketch and Yeti externally and enable Google Cloud OpenID
Connect (OIDC) authentication to control user access.

1. Reserve a global static IP address:

    ```console
    gcloud compute addresses create timesketch-webapps --global
    ```

2. Register DNS Records

    Register a new domain or use an existing one.  Create DNS "A" records that point
    your desired subdomains (e.g., timesketch.example.com, yeti.example.com) to the
    static IP address you reserved in the previous step.

3. Create OAuth web client credentials

    Follow the [Google Support guide](https://support.google.com/cloud/answer/6158849)
    to create OAuth 2.0 Web Client credentials. You will also need a Desktop/Native OAuth client if you intend to use the client.
    * Add the following authorized JavaScript origins:
      * `https://<timesketch.DOMAIN_NAME>.com`
      * `https://<yeti.DOMAIN_NAME>.com`
    * Add the following authorized redirect URIs:
      * `https://<timesketch.DOMAIN_NAME>.com/google_openid_connect/`
      * `https://<yeti.DOMAIN_NAME>.com//login/google_openid_connect/`

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

7. To externally expose Yeti and Timesketch, enable OIDC and provision GCP managed certificates, set the following values during a `helm install` or `helm upgrade`:

    ```console
    --set global.ingress.enabled=true \
    --set global.ingress.gcp.staticIPName=<STATIC_IP_NAME> \
    --set global.ingress.gcp.managedCertificates=true \
    --set global.ingress.timesketchHost=<timesketch.DOMAIN_NAME.com> \
    --set global.ingress.yetiHost=<yeti.<DOMAIN_NAME.com> \
    --set timesketch.config.oidc.enabled=true \
    --set timesketch.config.oidc.existingSecret=<OAUTH_SECRET_NAME> \
    --set timesketch.config.oidc.authenticatedEmailsFile.existingSecret=<AUTHENTICATED_EMAILS_SECRET_NAME>
    --set yeti.config.oidc=true \
    --set yeti.config.oidc.existingSecret=<OAUTH_SECRET_NAME>
    ```

> **Note**: Yeti user access is managed separately by creating and removing users
through the `yeticli` command-line tool.

## Uninstalling the Chart

To uninstall/delete a Helm deployment with a release name of `my-release`:

```console
helm uninstall my-release
```

> **Tip**: Please update based on the release name chosen. You can list all
releases using `helm list`

The command removes all the Kubernetes components but Persistent Volumes (PVC)
associated with the chart and deletes the release.

To delete the PVC's associated with a release name of `my-release`:

```console
kubectl delete pvc -l release=my-release
```

> **Note**: Deleting the PVC's will delete OSDFIR Infrastructure data as well.
Please be cautious before doing it.

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

Specify each parameter using the --set key=value[,key=value] argument to `helm install`. For example,

```console
helm install my-release osdfir-charts/osdfir-infrastructure --set global.yeti.enabled=false
```

The above command installs OSDFIR Infrastructure without Yeti deployed.

Alternatively, the `values.yaml` file can be
directly updated if the Helm chart was pulled locally. For example,

```console
helm pull osdfir-charts/osdfir-infrastructure --untar
```

Then make changes to the downloaded `values.yaml` and once done, install the
chart with the updated values.

```console
helm install my-release ../osdfir-infrastructure
```

It is recommended to use this approach when you
need to track changes in version control (recommended for production environments).

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
