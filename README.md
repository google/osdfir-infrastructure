# OSDFIR Infrastructure
OSDFIR Infrastructure helps setup Open Source
Digital Forensics tools to Kubernetes clusters using Helm. 

Currently, OSDFIR Infrastructure
supports the deployment of the following tools:
  * Timesketch; ref https://github.com/google/timesketch
  * Turbinia; ref https://github.com/google/turbinia

## TL;DR

```console
helm install my-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```
> **Tip**: To quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

## Introduction

This chart bootstraps a OSDFIR Infrastructure deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure

> **Note**: Currently Turbinia only supports processing of GCP Persistent Disks and Local Evidence. See [GKE Installations](#gke-installations) for deploying to GKE.

## Installing the Charts

For more information on how to install and configure OSDFIR Infrastructure or individual tools, please refer to the links below.
- [OSDFIR Infrastructure Install Guide](charts/osdfir-infrastructure/README.md)
- [Timesketch Install Guide](charts/timesketch/README.md)
- [Turbinia Install Guide](charts/turbinia/README.md)