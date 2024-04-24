<!--- app-name: HashR -->
# HashR Helm Chart

HashR allows you to build your own hash sets based on your data sources. It's a
tool that extracts files and hashes out of input sources (e.g. raw disk image,
GCE disk image, ISO file, Windows update package, .tar.gz file, etc.).

[Overview of HashR](https://github.com/google/hashr)

[Chart Source Code](https://github.com/google/osdfir-infrastructure)

## TL;DR

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm install my-release osdfir-charts/hashr
```

> **Tip**: To quickly get started with a local cluster, see
[minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

## Introduction

This chart bootstraps a [HashR](https://github.com/google/hashr/tree/main/docker)
deployment on a [Kubernetes](https://kubernetes.io) cluster using the
[Helm](https://helm.sh) package manager.

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

To install the chart, specify any release name of your choice. For example,
using `my-release` as the release name, run:

```console
helm install my-release osdfir-charts/hashr
```

The command deploys a PostgreSQL instance to the Kubernetes cluster and
schedules a Kubernetes CronJob to run the configures HashR job. Results of the
HashR job are exported to the PostgreSQL instance.
The [Parameters](#parameters) section lists the parameters that can be
configured during installation.

## Installing for Production

Pull the chart locally then cd into `/hashr` and review the `values.yaml` file
for a list of values that will be used for production.

```console
helm pull osdfir-charts/hashr --untar
```

### Configure the HashR importers

HashR provides different importers. Each importer has its own CronJob and can be
configured separately. Enable and configure all importers you want to use in the
`hashr.importers` section of the `values.yaml` file.

Ensure that you have setup all requirements for the importers defined in the
HashR project. See [HashR importers](https://github.com/google/hashr?tab=readme-ov-file#setting-up-importers)
for more details.

### Install chart

Install the chart with the values in `values.yaml`, then using a release name
such as `my-release`, run:

```console
helm install my-release ../hashr -f values.yaml
```

## Add data for HashR to process

The HashR CronJob has access to the Persistent Volume (PVC) at `/mnt/hashrvolume`.
See the [Persistence](#persistence) section for more details.

Each importer that needs local files to procress (e.g. deb, zip, iso9660, etc)
will look in a subfolder of `/mnt/hashrvolume/data/<importer>` for files to
process. E.g. `/mnt/hashrvolume/data/deb/`for the deb importer.

To add data for processing use the `kubectl cp` command and the
`hashr-data-manager` pod.

Example:

```console
kubectl cp <local PATH>/deb my-release-hashr-data-manager:/mnt/hashrvolume/data/
```

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

> **Note**: Deleting the PVC's will delete HashR/PostgreSQL data as well.
Please be cautious before doing it.

## Parameters



## Persistence

The HashR deployment stores data at the `/mnt/hashrvolume` path of the
container.

Persistent Volume Claims are used to keep the data across deployments. This is
known to work in GCP and Minikube. See the Parameters section to configure the
PVC or to disable persistence.

## Upgrading

If you need to upgrade an existing release to update a value, such as persistent
volume size or upgrading to a new release, you can run
[helm upgrade](https://helm.sh/docs/helm/helm_upgrade/).
For example, to set a new release and upgrade storage capacity, run:

```console
helm upgrade my-release ../hashr \
    --set image.tag=latest \
    --set persistence.size=10T
```

The above command upgrades an existing release named `my-release` updating the
image tag to `latest` and increasing persistent volume size of an existing
volume to 10 Terabytes. Note that existing data will not be deleted and instead
triggers an expansion of the volume that backs the underlying PersistentVolume.
See [here](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

## Troubleshooting

There is a known issue causing PostgreSQL authentication to fail. This occurs
when you `delete` the deployed Helm chart and then redeploy the Chart without
removing the existing PVCs. When redeploying, please ensure to delete the
underlying PostgreSQL PVC. Refer to [issue 2061](https://github.com/bitnami/charts/issues/2061)
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
