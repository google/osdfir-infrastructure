<!--- app-name: dfDewey -->
# dfDewey Datastore Helm Chart

dfDewey is an open-source digital forensics tool for string extraction, indexing, and searching.

[dfDewey Source Code](https://github.com/google/dfdewey)

[Chart Source Code](https://github.com/google/osdfir-infrastructure)

## TL;DR

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm install my-release osdfir-charts/dfdewey
```

> **Tip**: To quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

## Introduction

This chart bootstraps a [dfDewey datastore](https://github.com/google/dfdewey) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

* Kubernetes 1.19+
* Helm 3.2.0+
* PV provisioner support in the underlying infrastructure

## Installing the Chart

The first step is to add the repo and then update to pick up any new changes.

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm repo update
```

To install the chart, specify any release name of your choice. For example, using `my-release` as the release name, run:

```console
helm install my-release osdfir-charts/dfdewey
```

The command deploys the dfDewey datastores on the Kubernetes cluster in the default configuration. See [Installating for Production](#installing-for-production)
for a recommended production installation.

## Installing for Production

Pull the chart locally then cd into `/dfdewey` and review the `values-production.yaml` file for a list of values that will be used for production.

```console
helm pull osdfir-charts/dfdewey --untar
```

## Uninstalling the Chart

To uninstall/delete a Helm deployment with a release name of `my-release`:

```console
helm uninstall my-release
```

> **Tip**: Please update based on the release name chosen. You can list all releases using `helm list`

The command removes all the Kubernetes components except for Persistent Volumes (PVC) associated with the chart and deletes the release.

To delete the PVC's associated with a release name of `my-release`:

```console
kubectl delete pvc -l release=my-release
```

> **Note**: Deleting the PVC's will delete any data in the dfDewey datastores as well. Please be cautious before doing it.

## Parameters
