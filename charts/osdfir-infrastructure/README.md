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

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example,

```console
helm install my-release \
    --set metrics.port=9300
    oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

The above command updates the OSDFIR Infrastructure metrics port to `9300`.


Alternatively, the `values.yaml` file can be directly updated if the Helm chart 
was pulled locally. For example,

```console
helm pull oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure --untar
```

Then make changes to the downloaded `values.yaml`. Once done, install the local 
chart with the updated values.
```console
helm install my-release ../osdfir-infrastructure
```

Lastly, a YAML file that specifies the values for the parameters can also be 
provided while installing the chart. For example,

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
    --set image.tag=latest
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