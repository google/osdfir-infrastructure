# GRR Helm Chart

GRR Rapid Response is an incident response framework focused on remote live forensics.

[Overview of GRR](https://grr-doc.readthedocs.io/)

[Chart Source Code](https://github.com/google/osdfir-infrastructure)

## TL;DR

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm install grr-on-k8s osdfir-charts/grr
```

> **Tip**: To quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

## Introduction

This chart bootstraps a [GRR](https://github.com/google/grr) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Docker 25.0.3+
- Kubernetes 1.27.8+
- kubectl v1.29.2+
- Helm 3.14.1+

## Setup the mysql database
```
kubectl apply -f charts/grr/mysql.yaml
```

## Setup minikube tunneling
```
minikube tunnel &
```

## Installing the Chart

The first step is to add the repo and then update to pick up any new changes.

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm repo update
```

To install the chart, specify any release name of your choice. For example, using `grr-on-k8s' as the release name, run:

```console
helm install grr-on-k8s osdfir-charts/grr
```

The command deploys GRR on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Deploy a GRR client as a daemonset
For test and demo purposes we will deploy a GRR client as a Kubernetes daemonset.  
To do so we will
- first retrieve the values for some configuration parameters,
- then build a Docker container with the GRR client and its dependencies, and
- finally deploy the container as a daemonset.

### Retrieve the configuration parameter values
```
cd charts/grr/containers/grr/daemon/
export FLEETSPEAK_FRONTEND_IP=$(kubectl get svc svc-fleetspeak-frontend --output jsonpath='{.spec.clusterIP}')
export FLEETSPEAK_CERT=$(openssl s_client -showcerts -nocommands -connect $FLEETSPEAK_FRONTEND_IP:4443 < /dev/null | \
              openssl x509 -outform pem | sed ':a;N;$!ba;s/\n/\\\\n/g')
sed -i "s'FRONTEND_TRUSTED_CERTIFICATES'\"$FLEETSPEAK_CERT\"'g" config/config.textproto
```

### Build the GRR client Docker container
```
eval $(minikube docker-env)
docker build -t grr-daemon:v0.1 .
```

### Deploy the GRR client daemonset
```
kubectl label nodes minikube grrclient=installed
```

## Uninstalling the Chart

To uninstall/delete a Helm deployment with a release name of `grr-on-k8s`:

```console
helm uninstall grr-on-k8s
```

> **Tip**: Please update based on the release name chosen. You can list all releases using `helm list`

## Parameters

### Global parameters

| Name                            | Description                                                                                  | Value   |
| ------------------------------- | -------------------------------------------------------------------------------------------- | ------- |
| ``                              |                                                                                              | ``      |

### GRR configuration

| Name                                | Description                                                                                  | Value       |
| ----------------------------------- | -------------------------------------------------------------------------------------------- | ----------- |
| ``                                  |                                                                                              | ``          |

### Common Parameters

| Name                                | Description                                                                                  | Value       |
| ----------------------------------- | -------------------------------------------------------------------------------------------- | ----------- |
| ``                                  |                                                                                              | ``          |

### Third Party Configuration

| Name                                | Description                                                                                  | Value       |
| ----------------------------------- | -------------------------------------------------------------------------------------------- | ----------- |
| ``                                  |                                                                                              | ``          |

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
