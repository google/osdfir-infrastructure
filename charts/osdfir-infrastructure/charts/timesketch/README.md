<!--- app-name: Timesketch -->
# Timesketch Helm Chart

Timesketch is an open-source tool for collaborative forensic timeline analysis.

[Overview of Timesketch](http://www.timesketch.org)

[Chart Source Code](https://github.com/google/osdfir-infrastructure)

## TL;DR

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm install my-release osdfir-charts/timesketch
```

> **Note**: By default, Timesketch is not externally accessible and can be
reached via `kubectl port-forward` within the cluster.

## Introduction

This chart bootstraps a [Timesketch](https://github.com/google/timesketch/blob/master/docker/release/build/Dockerfile-latest)
deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

For a quick start with a local Kubernetes cluster on your desktop, check out the
[getting started with Minikube guide](https://github.com/google/osdfir-infrastructure/blob/main/docs/getting-started.md).

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
- Shared storage for clusters larger then one machine.

## Installing the Chart

The first step is to add and update the repo:

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm repo update
```

Then to install the chart, specify any release name of your choice. For example,
using `my-release` as the release name, run:

```console
helm install my-release osdfir-charts/timesketch
```

The command deploys Timesketch on the Kubernetes cluster in the default configuration.
The [Parameters](#parameters) section lists the parameters that can be configured
during installation.

> **Tip**:  See the [Managing and updating Timesketch configs](#managing-and-updating-timesketch-configs)
section for more details on managing the Timesketch configs.

## Configuration and installation details

### Use a different Timesketch version

The Timesketch Helm chart utilizes the latest container release tags by default.
OSDFIR Infrastructure actively monitors for new versions of the main containers
and releases updated charts accordingly.

To modify the application version used in Timesketch, specify a different version
of the image using the `image.tag` parameter and/or a different repository using
the `image.repository` parameter. For example, to use the most recent development
version instead, set `image.tag` to `latest`.

### Upgrading the Helm chart

Helm chart updates can be retrieved by running `helm repo update`.

To explore available charts and versions, use `helm search repo osdfir-charts/`.
Install a specific chart version with `helm install my-release osdfir-charts/timesketch --version <version>`.

A major Helm chart version change (like v1.0.0 -> v2.0.0) indicates that there
is an incompatible breaking change needing manual actions.

### Managing and updating Timesketch configs

This section outlines how to deploy and manage Timesketch configuration files
within OSDFIR infrastructure.

There are two primary methods:

#### Using Default Configurations

If you don't provide your own Timesketch config files during deployment,
the Timesketch deployment will automatically retrieve the latest default configs
from the Timesketch Github repository. This method requires no further action from you.

> **NOTE:**  When using the default method, you cannot update the Timesketch config files directly.

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

### Upgrading the Timesketch Database Schema

From time to time, a Timesketch release requires a manual database upgrade if
the schema has changed.
The [Timesketch release page](https://github.com/google/timesketch/releases)
will indicate if a database upgrade is required.

Follow these steps to upgrade the database on your Kubernetes deployment:

1. **Upgrade Timesketch (if not already done):**
   - Upgrade your Timesketch deployment to the desired release version:

     ```bash
     helm upgrade my-release osdfir-charts/timesketch --set image.tag=<VERSION> --set image.pullPolicy=Always
     ```

2. **Connect to Timesketch Pod:**
   - Once the upgraded pods are ready, shell into the Timesketch pod:

     ```bash
     kubectl exec -it my-release-timesketch-<RANDOM> -- /bin/bash
     ```

     - Find your pod name using `kubectl get pods`.

3. **Perform Database Upgrade:**
   - Follow the detailed steps in the [Timesketch documentation to upgrade your database](https://timesketch.org/guides/admin/upgrade/#upgrade-the-database-schema).

4. **Restart Timesketch (Recommended):**
   - After a successful database upgrade, it is recommended to restart your
   Timesketch deployment for the changes to take full effect:

      ```bash
      kubectl rollout restart deployment my-release-timesketch-web
      ```

### Metrics and monitoring

The chart starts a metrics exporter for prometheus. The metrics endpoint (port 8080)
is exposed in the service. Metrics can be scraped from within the cluster by either
a Prometheus server running in your cluster or a cloud-based Prometheus service.
Currently, the available metrics is limited to system metrics.

### Resource requests and limits

OSDFIR Infrastructure charts allow setting resource requests and limits for all
containers inside the chart deployment. These are inside the `resources` value
(check parameter table). Setting requests is essential for production workloads
and these should be adapted to your specific use case.

To maximize deployment success across different environments, resources are
minimally defined by default.

### Persistence

By default, the chart mounts a Persistent Volume at the `/mnt/timesketchvolume` path.
The volume is created using dynamic volume provisioning.

Configuration files can be found at the `/etc/timesketch` path of the container
while logs can be found at `/var/log/timesketch`.

For clusters running more than one nodes or machines, the Persistent Volume will
need to have the ability to be mounted by multiple machines, such as NFS, GCP
Filestore, AWS EFS, and other shared file storage equivalents.

## Enabling GKE Ingress and OIDC Authentication

Follow these steps to externally expose Timesketch and enable Google Cloud OIDC
to control user access to Timesketch.

1. Create a global static IP address:

    ```console
    gcloud compute addresses create timesketch-webapps --global
    ```

2. Register a new domain or use an existing one, ensuring a DNS entry
points to the IP created earlier.

3. Create OAuth web client credentials following the [Google Support guide](https://support.google.com/cloud/answer/6158849). If using the CLI client, also create a Desktop/Native
OAuth client.
   - Fill in Authorized JavaScript origins with your domain as `https://<DOMAIN_NAME>.com`
   - Fill in Authorized redirect URIs with `https://<DOMAIN_NAME>.com/google_openid_connect/`

4. Store your new OAuth credentials in a K8s secret:

    ```console
    kubectl create secret generic oauth-secrets \
        --from-literal=client-id=<WEB_CLIENT_ID> \
        --from-literal=client-secret=<WEB_CLIENT_SECRET> \
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
   Timesketch through a loadbalancer, add SSL through GCP managed certificates, and
   enable OIDC for authentication, run:

    ```console
    helm upgrade my-release ../timesketch \
        -f values-production.yaml \
        --set ingress.enabled=true \
        --set ingress.className="gce" \
        --set ingress.host=<DOMAIN_NAME> \
        --set ingress.gcp.staticIPName=<STATIC_IP_NAME> \
        --set ingress.gcp.managedCertificates=true \
        --set config.oidc.enabled=true \
        --set config.oidc.existingSecret=<OAUTH_SECRET_NAME> \
        --set config.oidc.authenticatedEmailsFile.existingSecret=<AUTHENTICATED_EMAILS_SECRET_NAME>
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

> **Note**: Deleting the PVC's will delete Timesketch data as well. Please be cautious before doing it.

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
| `global.existingPVC`            | Existing claim for Timesketch persistent volume (overrides `persistent.name`)                               | `""`    |
| `global.storageClass`           | StorageClass for the Timesketch persistent volume (overrides `persistent.storageClass`)                     | `""`    |

### Timesketch image configuration

| Name                     | Description                                                   | Value                                                     |
| ------------------------ | ------------------------------------------------------------- | --------------------------------------------------------- |
| `image.repository`       | Timesketch image repository                                   | `us-docker.pkg.dev/osdfir-registry/timesketch/timesketch` |
| `image.pullPolicy`       | Timesketch image pull policy                                  | `IfNotPresent`                                            |
| `image.tag`              | Overrides the image tag whose default is the chart appVersion | `20240828`                                                |
| `image.imagePullSecrets` | Specify secrets if pulling from a private repository          | `[]`                                                      |

### Timesketch Configuration Parameters

| Name                                                 | Description                                                                                | Value   |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------- |
| `config.existingConfigMap`                           | Use an existing ConfigMap as the default Timesketch config.                                | `""`    |
| `config.createUser`                                  | Creates a default Timesketch user that can be used to login to Timesketch after deployment | `true`  |
| `config.oidc.enabled`                                | Enables Timesketch OIDC authentication (currently only supports Google OIDC)               | `false` |
| `config.oidc.existingSecret`                         | Existing secret with the client ID, secret and cookie secret                               | `""`    |
| `config.oidc.authenticatedEmailsFile.enabled`        | Enables email authentication                                                               | `true`  |
| `config.oidc.authenticatedEmailsFile.existingSecret` | Existing secret with a list of emails                                                      | `""`    |
| `config.oidc.authenticatedEmailsFile.content`        | Allowed emails list (one email per line)                                                   | `""`    |

### Timesketch Frontend Configuration

| Name                          | Description                                                                 | Value |
| ----------------------------- | --------------------------------------------------------------------------- | ----- |
| `frontend.podSecurityContext` | Holds pod-level security attributes and common frontend container settings  | `{}`  |
| `frontend.securityContext`    | Holds security configuration that will be applied to the frontend container | `{}`  |
| `frontend.resources.limits`   | The resources limits for the frontend container                             | `{}`  |
| `frontend.resources.requests` | The requested resources for the frontend container                          | `{}`  |
| `frontend.nodeSelector`       | Node labels for Timesketch frontend pods assignment                         | `{}`  |
| `frontend.tolerations`        | Tolerations for Timesketch frontend pods assignment                         | `[]`  |
| `frontend.affinity`           | Affinity for Timesketch frontend pods assignment                            | `{}`  |

### Timesketch Worker Configuration

| Name                               | Description                                                               | Value   |
| ---------------------------------- | ------------------------------------------------------------------------- | ------- |
| `worker.podSecurityContext`        | Holds pod-level security attributes and common worker container settings  | `{}`    |
| `worker.securityContext`           | Holds security configuration that will be applied to the worker container | `{}`    |
| `worker.resources.limits`          | The resources limits for the worker container                             | `{}`    |
| `worker.resources.requests.cpu`    | The requested cpu for the worker container                                | `250m`  |
| `worker.resources.requests.memory` | The requested memory for the worker container                             | `256Mi` |
| `worker.nodeSelector`              | Node labels for Timesketch worker pods assignment                         | `{}`    |
| `worker.tolerations`               | Tolerations for Timesketch worker pods assignment                         | `[]`    |
| `worker.affinity`                  | Affinity for Timesketch worker pods assignment                            | `{}`    |

### Timesketch Nginx Configuration

| Name                              | Description                                                              | Value                |
| --------------------------------- | ------------------------------------------------------------------------ | -------------------- |
| `nginx.image.repository`          | Nginx image repository                                                   | `nginx`              |
| `nginx.image.tag`                 | Nginx image tag                                                          | `1.25.5-alpine-slim` |
| `nginx.image.pullPolicy`          | Nginx image pull policy                                                  | `Always`             |
| `nginx.podSecurityContext`        | Holds pod-level security attributes and common nginx container settings  | `{}`                 |
| `nginx.securityContext`           | Holds security configuration that will be applied to the nginx container | `{}`                 |
| `nginx.resources.limits`          | The resources limits for the nginx container                             | `{}`                 |
| `nginx.resources.requests.cpu`    | The requested cpu for the nginx container                                | `250m`               |
| `nginx.resources.requests.memory` | The requested memory for the nginx container                             | `256Mi`              |
| `nginx.nodeSelector`              | Node labels for Timesketch nginx pods assignment                         | `{}`                 |
| `nginx.tolerations`               | Tolerations for Timesketch nginx pods assignment                         | `[]`                 |
| `nginx.affinity`                  | Affinity for Timesketch nginx pods assignment                            | `{}`                 |

### Common Parameters

| Name                              | Description                                                                                                                         | Value               |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `serviceAccount.create`           | Specifies whether a service account should be created                                                                               | `true`              |
| `serviceAccount.annotations`      | Annotations to add to the service account                                                                                           | `{}`                |
| `serviceAccount.name`             | The name of the service account to use                                                                                              | `""`                |
| `service.type`                    | Timesketch service type                                                                                                             | `ClusterIP`         |
| `service.port`                    | Timesketch service port                                                                                                             | `5000`              |
| `metrics.enabled`                 | Enables metrics scraping                                                                                                            | `true`              |
| `metrics.port`                    | Port to scrape metrics from                                                                                                         | `8080`              |
| `persistence.name`                | Timesketch persistent volume name                                                                                                   | `timesketchvolume`  |
| `persistence.size`                | Timesketch persistent volume size                                                                                                   | `2Gi`               |
| `persistence.storageClass`        | PVC Storage Class for Timesketch volume                                                                                             | `""`                |
| `persistence.accessModes`         | PVC Access Mode for Timesketch volume                                                                                               | `["ReadWriteOnce"]` |
| `ingress.enabled`                 | Enable the Timesketch loadbalancer for external access                                                                              | `false`             |
| `ingress.host`                    | Domain name Timesketch will be hosted under                                                                                         | `""`                |
| `ingress.className`               | IngressClass that will be be used to implement the Ingress                                                                          | `""`                |
| `ingress.selfSigned`              | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                                        | `false`             |
| `ingress.certManager`             | Add the corresponding annotations for cert-manager integration                                                                      | `false`             |
| `ingress.gcp.managedCertificates` | Enables GCP managed certificates for your domain                                                                                    | `false`             |
| `ingress.gcp.staticIPName`        | Name of the static IP address you reserved in GCP.                                                                                  | `""`                |
| `ingress.gcp.staticIPV6Name`      | Name of the static IPV6 address you reserved. This can be optionally provided to deploy a loadbalancer with an IPV6 address in GCP. | `""`                |

### Third Party Configuration


### Opensearch Configuration Parameters

| Name                                   | Description                                                                                                                                                    | Value                                                                                    |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `opensearch.enabled`                   | Enables the Opensearch deployment                                                                                                                              | `true`                                                                                   |
| `opensearch.nodeGroup`                 | Specifies the node group for this OpenSearch instance. Avoid using "master" as the node group name, as this will prevent the service from resolving correctly. | `""`                                                                                     |
| `opensearch.config.opensearch.yml`     | Opensearch configuration file. Can be appended for additional configuration options                                                                            | `{"opensearch.yml":"plugins:\n  security:\n    allow_unsafe_democertificates: false\n"}` |
| `opensearch.extraEnvs[0].name`         | Environment variable to disable Opensearch Demo config                                                                                                         | `DISABLE_INSTALL_DEMO_CONFIG`                                                            |
| `opensearch.extraEnvs[0].value`        | Disables Opensearch Demo config                                                                                                                                | `true`                                                                                   |
| `opensearch.extraEnvs[1].name`         | Environment variable to disable Opensearch Security plugin given that                                                                                          | `DISABLE_SECURITY_PLUGIN`                                                                |
| `opensearch.extraEnvs[1].value`        | Disables Opensearch Security plugin                                                                                                                            | `true`                                                                                   |
| `opensearch.replicas`                  | Number of Opensearch instances to deploy                                                                                                                       | `1`                                                                                      |
| `opensearch.sysctlInit.enabled`        | Sets optimal sysctl's through privileged initContainer                                                                                                         | `true`                                                                                   |
| `opensearch.opensearchJavaOpts`        | Sets the size of the Opensearch Java heap                                                                                                                      | `-Xmx512M -Xms512M`                                                                      |
| `opensearch.httpPort`                  | Opensearch service port                                                                                                                                        | `9200`                                                                                   |
| `opensearch.persistence.size`          | Opensearch Persistent Volume size. A persistent volume would be created for each Opensearch replica running                                                    | `2Gi`                                                                                    |
| `opensearch.resources.requests.cpu`    | The requested cpu for the Opensearch container                                                                                                                 | `250m`                                                                                   |
| `opensearch.resources.requests.memory` | The requested memory for the Opensearch container                                                                                                              | `512Mi`                                                                                  |
| `opensearch.nodeSelector`              | Node labels for Opensearch pods assignment                                                                                                                     | `{}`                                                                                     |

### Redis Configuration Parameters

| Name                                | Description                                                                                  | Value        |
| ----------------------------------- | -------------------------------------------------------------------------------------------- | ------------ |
| `redis.enabled`                     | Enables the Redis deployment                                                                 | `true`       |
| `redis.sentinel.enabled`            | Enables Redis Sentinel on Redis pods                                                         | `false`      |
| `redis.architecture`                | Specifies the Redis architecture. Allowed values: `standalone` or `replication`              | `standalone` |
| `redis.master.count`                | Number of Redis master instances to deploy (experimental, requires additional configuration) | `1`          |
| `redis.master.service.type`         | Redis master service type                                                                    | `ClusterIP`  |
| `redis.master.service.ports.redis`  | Redis master service port                                                                    | `6379`       |
| `redis.master.persistence.size`     | Redis master Persistent Volume size                                                          | `2Gi`        |
| `redis.master.resources.limits`     | The resources limits for the Redis master containers                                         | `{}`         |
| `redis.master.resources.requests`   | The requested resources for the Redis master containers                                      | `{}`         |
| `redis.replica.replicaCount`        | Number of Redis replicas to deploy                                                           | `0`          |
| `redis.replica.service.type`        | Redis replicas service type                                                                  | `ClusterIP`  |
| `redis.replica.service.ports.redis` | Redis replicas service port                                                                  | `6379`       |
| `redis.replica.persistence.size`    | Redis replica Persistent Volume size                                                         | `2Gi`        |
| `redis.replica.resources.limits`    | The resources limits for the Redis replica containers                                        | `{}`         |
| `redis.replica.resources.requests`  | The requested resources for the Redis replica containers                                     | `{}`         |

### Postgresql Configuration Parameters

| Name                                               | Description                                                                 | Value        |
| -------------------------------------------------- | --------------------------------------------------------------------------- | ------------ |
| `postgresql.enabled`                               | Enables the Postgresql deployment                                           | `true`       |
| `postgresql.architecture`                          | PostgreSQL architecture (`standalone` or `replication`)                     | `standalone` |
| `postgresql.auth.username`                         | Name for a custom PostgreSQL user to create                                 | `postgres`   |
| `postgresql.auth.database`                         | Name for a custom PostgreSQL database to create (overrides `auth.database`) | `timesketch` |
| `postgresql.primary.service.type`                  | PostgreSQL primary service type                                             | `ClusterIP`  |
| `postgresql.primary.service.ports.postgresql`      | PostgreSQL primary service port                                             | `5432`       |
| `postgresql.primary.persistence.size`              | PostgreSQL Persistent Volume size                                           | `2Gi`        |
| `postgresql.primary.resources.limits`              | The resources limits for the PostgreSQL primary containers                  | `{}`         |
| `postgresql.primary.resources.requests.cpu`        | The requested cpu for the PostgreSQL primary containers                     | `250m`       |
| `postgresql.primary.resources.requests.memory`     | The requested memory for the PostgreSQL primary containers                  | `256Mi`      |
| `postgresql.readReplicas.replicaCount`             | Number of PostgreSQL read only replicas                                     | `0`          |
| `postgresql.readReplicas.service.type`             | PostgreSQL read replicas service type                                       | `ClusterIP`  |
| `postgresql.readReplicas.service.ports.postgresql` | PostgreSQL read replicas service port                                       | `5432`       |
| `postgresql.readReplicas.persistence.size`         | PostgreSQL Persistent Volume size                                           | `2Gi`        |
| `postgresql.readReplicas.resources.limits`         | The resources limits for the PostgreSQL read only containers                | `{}`         |
| `postgresql.readReplicas.resources.requests`       | The requested resources for the PostgreSQL read only containers             | `{}`         |

Specify each parameter using the --set key=value[,key=value] argument to helm
install. For example,

```console
helm install my-release osdfir-charts/timesketch --set opensearch.replicas=3
```

The above command installs Timesketch with 3 Opensearch Replicas.

Alternatively, the `values.yaml` file can be directly updated if the Helm chart
was pulled locally. For example,

```console
helm pull osdfir-charts/timesketch --untar
```

Then make changes to the downloaded `values.yaml` and once done, install the
chart with the updated values.

```console
helm install my-release ../timesketch
```

## Troubleshooting

Find more information about how to deal with common errors in OSDFIR Infrastructure
Helm charts in this [troubleshooting guide](https://github.com/google/osdfir-infrastructure/blob/main/docs/troubleshooting.md).

There is a known issue causing PostgreSQL authentication to fail. This occurs
when you `delete` the deployed Helm chart and then redeploy the Chart without
removing the existing PVCs. When redeploying, please ensure to delete the underlying
PostgreSQL PVC. Refer to [issue 2061](https://github.com/bitnami/charts/issues/2061)
for more details.

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
