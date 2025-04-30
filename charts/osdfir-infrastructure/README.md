<!--- app-name: OSDFIR Infrastructure -->
# OSDFIR Infrastructure Helm Chart

OSDFIR Infrastructure helps setup Open Source Digital Forensics tools to
Kubernetes clusters using Helm.

Currently, OSDFIR Infrastructure supports the deployment and integration of the
following tools:

* [dfTimewolf](https://github.com/log2timeline/dftimewolf)
* [Timesketch](https://github.com/google/timesketch)
* [Yeti](https://github.com/yeti-platform/yeti)
* [OpenRelik](https://openrelik.org)
* [GRR](https://github.com/google/grr)

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

To install the chart, specify any release name of your choice. For example,
using `my-release` as the release name, run:

```console
helm install my-release osdfir-charts/osdfir-infrastructure
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster in the
default configuration.

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

### Managing OpenRelik images

The OpenRelik container images are managed using the following values,
`openrelik.<component>.image.repository` and `openrelik.<component>.image.tag`, where
`<component>` is replaced with `frontend`, `api`, `mediator`, or `metrics`.

OpenRelik worker container images are managed through the `openrelik.workers` value.
Each worker definition requires a full image name (including repository and tag)
and a command.  Resource allocation for individual workers can be optionally
configured using the resources setting.

To view all configurable values of the OpenRelik subchart, including the default
image tags and repositories, run the following command:

```console
helm show values osdfir-infrastructure/charts/openrelik
```

Specify the desired image tags and repositories when deploying or upgrading the
OSDFIR Infrastructure chart.

### Managing GRR and Fleetspeak images

The GRR and Fleetspeak container images are managed using the following values,
`grr:<tag>` and `fleetspeak:<tag>`, where `<tag>` is replaced with the version.

To view all configurable values of the GRR subchart, including the default
image tags and repositories, run the following command:

```console
helm show values osdfir-infrastructure/charts/grr
```

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

### Managing the OpenRelik config

OpenRelik's configuration is managed using environment variables and the `settings.toml`
configuration file.  These environment variables are generally expected to remain
consistent for proper Helm chart operation and will not change often.

For settings not currently exposed as environment variables, the recommended approach
is to submit a Pull Request (PR) to the repository. This practice ensures that
configuration changes are preserved across chart upgrades and maintained within
the project.

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

    To download the default configuration folder and apply your changes locally
    you can use the [download-timesketch-configs.sh script](./charts/timesketch/tools/download-timesketch-configs.sh).

    ```console
    bash download-timesketch-configs.sh --release 20250408
    ```

2. Create a ConfigMap:

    ```console
    kubectl create configmap timesketch-configs \
      --from-file=ts-configs.tgz.b64=<(tar czf - -C ./timesketch-configs/ . | base64)
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
    kubectl create configmap timesketch-configs \
      --from-file=ts-configs.tgz.b64=<(tar czf - -C ./timesketch-configs/ . | base64) \
      --dry-run -o yaml | kubectl replace -f -
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

### Managing the GRR and Fleetspeak config

The default way that the Fleetspeak frontend for GRR is exposed is through a ```NodePort``` (port 30443)
on the ```node IP```.

For example, in case you run on minikube you could retrieve the ```node IP``` by running ```minikube ip```.
The Fleetspeak/GRR clients (a.k.a. agents) will then use that IP address and the port 30443 to connect to the server.

For learning about other ways to expose Fleetspeak/GRR on layer 4 loadbalancers within GCP, see the [installing-on-gke.md](..docs/installing-on-gke.md) guide.

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

#### Persistence in OpenRelik

By default, OpenRelik mounts a Persistent Volume at the
`/mnt/openrelikvolume` path to store uploaded output for OpenRelik to process.
The volume is created using dynamic volume provisioning.

OpenRelik also depends on Redis for task scheduling, PostgreSQL for storing output
metadata, and Prometheus for collecting task processing metrics.  Persistent Volumes
for these services are also dynamically provisioned during deployment.

#### Persistence in GRR and Fleetspeak

By default, GRR and Fleetspeak will write into their datastores created on a MySQL
```pod``` running in the cluster.

For a production grade installation we recommend to operate the GRR and Fleetspeak
 datastores on either managed CloudSQL or Spanner instances.

### Enabling GKE Ingress and OIDC Authentication

For Google Kubernetes Engine (GKE) on Google Cloud Platform (GCP), follow these
steps to expose Timesketch, Yeti, and OpenRelik externally and enable Google Cloud
OpenID Connect (OIDC) authentication to control user access.

1. Reserve a global static IP address:

    ```console
    gcloud compute addresses create osdfir-webapps --global
    ```

2. Register DNS Records

    Register a new domain or use an existing one.  Create DNS "A" records that point
    your desired subdomains (e.g., timesketch.example.com, yeti.example.com, openrelik.example.com)
    to the static IP address you reserved in the previous step.

3. Create OAuth web client credentials

    Follow the [Google Support guide](https://support.google.com/cloud/answer/6158849)
    to create OAuth 2.0 Web Client credentials. You will also need a Desktop/Native OAuth client if you intend to use the client.
    * Add the following authorized JavaScript origins:
      * `https://<timesketch.DOMAIN_NAME>.com`
      * `https://<yeti.DOMAIN_NAME>.com`
      * `https://<openrelik.DOMAIN_NAME>.com`
    * Add the following authorized redirect URIs:
      * `https://<timesketch.DOMAIN_NAME>.com/google_openid_connect/`
      * `https://<yeti.DOMAIN_NAME>.com/login/google_openid_connect/`
      * `https://<openrelik.DOMAIN_NAME>.com/auth/google`

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
    --set yeti.config.oidc.existingSecret=<OAUTH_SECRET_NAME> \
    --set openrelik.config.oidc=true \
    --set openrelik.config.oidc.existingSecret=<OAUTH_SECRET_NAME>
    --set openrelik.config.oidc.authenticatedEmailsFile.existingSecret=<AUTHENTICATED_EMAILS_SECRET_NAME>
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

# Interacting with Helm charts

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

We recommend using this approach when version control change tracking is
necessary, particularly in production environments. It's also important to know
that values from sub-chart `values.yaml` files can be overridden directly in
the main OSDFIR Infrastructure `values.yaml` chart.

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
