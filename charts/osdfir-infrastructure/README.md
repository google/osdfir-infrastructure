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

| Name                                     | Description                                                                                                                                          | Value          |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `global.timesketch.enabled`              | Enables the Timesketch deployment (only used in the main OSDFIR Infrastructure Helm chart)                                                           | `true`         |
| `global.timesketch.servicePort`          | Timesketch service port (overrides `timesketch.service.port`)                                                                                        | `5000`         |
| `global.turbinia.enabled`                | Enables the Turbinia deployment (only used within the main OSDFIR Infrastructure Helm chart)                                                         | `true`         |
| `global.turbinia.servicePort`            | Turbinia API service port (overrides `turbinia.service.port`)                                                                                        | `8000`         |
| `global.dfdewey.enabled`                 | Enables the dfDewey deployment along with Turbinia                                                                                                   | `false`        |
| `global.yeti.enabled`                    | Enables the Yeti deployment (only used in the main OSDFIR Infrastructure Helm chart)                                                                 | `true`         |
| `global.yeti.servicePort`                | Yeti API service port (overrides `yeti.api.service.port`)                                                                                            | `9000`         |
| `global.ingress.enabled`                 | Enable the global loadbalancer for external access (only used in the main OSDFIR Infrastructure Helm chart)                                          | `false`        |
| `global.ingress.className`               | IngressClass that will be be used to implement the Ingress                                                                                           | `gce`          |
| `global.ingress.selfSigned`              | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                                                         | `false`        |
| `global.ingress.certManager`             | Add the corresponding annotations for cert-manager integration                                                                                       | `false`        |
| `global.ingress.gcp.managedCertificates` | Enabled GCP managed certificates for your domain                                                                                                     | `false`        |
| `global.ingress.gcp.staticIPName`        | Name of the static IP address you reserved in GCP                                                                                                    | `""`           |
| `global.ingress.gcp.staticIPV6Name`      | Name of the static IPV6 address you reserved in GCP. This can be optionally provided to deploy a loadbalancer with an IPV6 address                   | `""`           |
| `global.existingPVC`                     | Existing claim for the OSDFIR Infrastructure persistent volume (overrides `timesketch.persistent.name` and `turbinia.persistent.name`)               | `osdfirvolume` |
| `global.storageClass`                    | StorageClass for the OSDFIR Infrastructure persistent volume (overrides `timesketch.persistent.storageClass` and `turbinia.persistent.storageClass`) | `""`           |

### OSDFIR Infrastructure persistence storage parameters

| Name                       | Description                                                 | Value               |
| -------------------------- | ----------------------------------------------------------- | ------------------- |
| `persistence.enabled`      | Enables persistent volume storage for OSDFIR Infrastructure | `true`              |
| `persistence.name`         | OSDFIR Infrastructure persistent volume name                | `osdfirvolume`      |
| `persistence.size`         | OSDFIR Infrastructure persistent volume size                | `2Gi`               |
| `persistence.storageClass` | PVC Storage Class for OSDFIR Infrastructure volume          | `""`                |
| `persistence.accessModes`  | PVC Access Mode for the OSDFIR Infrastructure volume        | `["ReadWriteOnce"]` |

### Timesketch Configuration

| Name                                                            | Description                                                                                                                           | Value                                                     |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| `timesketch.image.repository`                                   | Timesketch image repository                                                                                                           | `us-docker.pkg.dev/osdfir-registry/timesketch/timesketch` |
| `timesketch.image.tag`                                          | Overrides the image tag whose default is the chart appVersion                                                                         | `latest`                                                  |
| `timesketch.frontend.resources.limits`                          | The resources limits for the frontend container                                                                                       | `{}`                                                      |
| `timesketch.frontend.resources.requests`                        | The requested resources for the frontend container                                                                                    | `{}`                                                      |
| `timesketch.worker.resources.limits`                            | The resources limits for the worker container                                                                                         | `{}`                                                      |
| `timesketch.worker.resources.requests.cpu`                      | The requested cpu for the worker container                                                                                            | `250m`                                                    |
| `timesketch.worker.resources.requests.memory`                   | The requested memory for the worker container                                                                                         | `256Mi`                                                   |
| `timesketch.config.override`                                    | Overrides the default Timesketch configs to instead use a user specified directory if present on the root directory of the Helm chart | `configs/*`                                               |
| `timesketch.config.createUser`                                  | Creates a default Timesketch user that can be used to login to Timesketch after deployment                                            | `true`                                                    |
| `timesketch.config.oidc.enabled`                                | Enables Timesketch OIDC authentication (currently only supports Google OIDC)                                                          | `false`                                                   |
| `timesketch.config.oidc.existingSecret`                         | Existing secret with the client ID, secret and cookie secret                                                                          | `""`                                                      |
| `timesketch.config.oidc.authenticatedEmailsFile.enabled`        | Enables email authentication                                                                                                          | `true`                                                    |
| `timesketch.config.oidc.authenticatedEmailsFile.existingSecret` | Existing secret with a list of emails                                                                                                 | `""`                                                      |
| `timesketch.config.oidc.authenticatedEmailsFile.content`        | Allowed emails list (one email per line)                                                                                              | `""`                                                      |
| `timesketch.ingress.host`                                       | Domain name Timesketch will be hosted under                                                                                           | `""`                                                      |

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
| `turbinia.config.existingVertexSecret`                       | Name of existing secret containing Vertex API Key in order to enable the Turbinia LLM Artifacts Analyzer. The secret must contain the key `turbinia-vertexapi`                                                       | `""`                                                                                         |
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
| `turbinia.ingress.host`                                      | The domain name Turbinia will be hosted under                                                                                                                                                                        | `""`                                                                                         |

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
| `turbinia.oauth2proxy.configuration.turbiniaSvcPort`                        | Turbinia service port referenced from `.Values.service.port` to be used in Oauth setup                                                                                | `8000`                        |
| `turbinia.oauth2proxy.configuration.existingSecret`                         | Secret with the client ID, client secret, client native id (optional) and cookie secret                                                                               | `""`                          |
| `turbinia.oauth2proxy.configuration.content`                                | Oauth2 proxy configuration. Please see the [official docs](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview) for a list of configurable values | `""`                          |
| `turbinia.oauth2proxy.configuration.authenticatedEmailsFile.enabled`        | Enable authenticated emails file                                                                                                                                      | `true`                        |
| `turbinia.oauth2proxy.configuration.authenticatedEmailsFile.content`        | Restricted access list (one email per line). At least one email address is required for the Oauth2 Proxy to properly work                                             | `""`                          |
| `turbinia.oauth2proxy.configuration.authenticatedEmailsFile.existingSecret` | Secret with the authenticated emails file                                                                                                                             | `""`                          |
| `turbinia.oauth2proxy.configuration.oidcIssuerUrl`                          | OpenID Connect issuer URL                                                                                                                                             | `https://accounts.google.com` |

### Yeti Configuration

| Name                               | Description                                                   | Value                        |
| ---------------------------------- | ------------------------------------------------------------- | ---------------------------- |
| `yeti.frontend.image.repository`   | Yeti frontend image repository                                | `yetiplatform/yeti-frontend` |
| `yeti.frontend.image.pullPolicy`   | Yeti image pull policy                                        | `Always`                     |
| `yeti.frontend.image.tag`          | Overrides the image tag whose default is the chart appVersion | `latest`                     |
| `yeti.frontend.resources.limits`   | Resource limits for the frontend container                    | `{}`                         |
| `yeti.frontend.resources.requests` | Requested resources for the frontend container                | `{}`                         |
| `yeti.api.image.repository`        | Yeti API image repository                                     | `yetiplatform/yeti`          |
| `yeti.api.image.pullPolicy`        | Yeti image pull policy                                        | `Always`                     |
| `yeti.api.image.tag`               | Overrides the image tag whose default is the chart appVersion | `latest`                     |
| `yeti.api.service.type`            | Yeti service type                                             | `ClusterIP`                  |
| `yeti.api.service.port`            | Yeti service port                                             | `8000`                       |
| `yeti.api.resources.limits`        | Resource limits for the API container                         | `{}`                         |
| `yeti.api.resources.requests`      | Requested resources for the API container                     | `{}`                         |
| `yeti.tasks.image.repository`      | Yeti tasks image repository                                   | `yetiplatform/yeti`          |
| `yeti.tasks.image.pullPolicy`      | Yeti image pull policy                                        | `Always`                     |
| `yeti.tasks.image.tag`             | Overrides the image tag whose default is the chart appVersion | `latest`                     |
| `yeti.tasks.resources.limits`      | Resource limits for the tasks container                       | `{}`                         |
| `yeti.tasks.resources.requests`    | Requested resources for the tasks container                   | `{}`                         |
| `yeti.ingress.host`                | Domain name Yeti will be hosted under                         | `""`                         |

### Yeti Third Party

| Name                                    | Description                                                                                  | Value       |
| --------------------------------------- | -------------------------------------------------------------------------------------------- | ----------- |
| `yeti.redis.enabled`                    | Enables the Redis deployment                                                                 | `true`      |
| `yeti.redis.master.count`               | Number of Redis master instances to deploy (experimental, requires additional configuration) | `1`         |
| `yeti.redis.master.service.type`        | Redis master service type                                                                    | `ClusterIP` |
| `yeti.redis.master.service.ports.redis` | Redis master service port                                                                    | `6379`      |
| `yeti.redis.master.persistence.size`    | Redis master Persistent Volume size                                                          | `2Gi`       |
| `yeti.redis.master.resources.limits`    | The resources limits for the Redis master containers                                         | `{}`        |
| `yeti.redis.master.resources.requests`  | The requested resources for the Redis master containers                                      | `{}`        |
| `yeti.arangodb.image.repository`        | Yeti arangodb image repository                                                               | `arangodb`  |
| `yeti.arangodb.image.pullPolicy`        | Yeti image pull policy                                                                       | `Always`    |
| `yeti.arangodb.image.tag`               | Overrides the image tag whose default is the chart appVersion                                | `3.11`      |
| `yeti.arangodb.resources.limits`        | Resource limits for the arangodb container                                                   | `{}`        |
| `yeti.arangodb.resources.requests`      | Requested resources for the arangodb container                                               | `{}`        |

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
