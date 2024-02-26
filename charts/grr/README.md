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

# Verify that the mysql pod is in the the 'Running' status
kubectl get pods
# The output should look similar to the below:
# NAME                     READY   STATUS    RESTARTS   AGE
# mysql-5cd45cc59f-bgwlv   1/1     Running   0          15s
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

# Verify that all the GRR component pods are in 'Running' state (this might take a moment)
kubectl get pods
# The output should look similar to the below:
# NAME                                      READY   STATUS    RESTARTS   AGE
# dpl-fleetspeak-admin-576754755b-hj27p     1/1     Running   0          1m1s
# dpl-fleetspeak-frontend-78bd9889d-jvb5v   1/1     Running   0          1m1s
# dpl-grr-admin-6b84cd996b-d54zn            1/1     Running   0          1m1s
# dpl-grr-frontend-5fc7f8dc5b-7hsbd         1/1     Running   0          1m1s
# dpl-grr-worker-cc96f574c-kxr9l            1/1     Running   0          1m1s
# mysql-5cd45cc59f-bgwlv                    1/1     Running   0          3m59s
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

# Verify that the GRR client daemonset got deployed.
kubectl get daemonset -n grr
# The output should look similar to the below:
NAME   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR         AGE
grr    1         1         1       1            1           grrclient=installed   53s
```

## Connect to the GRR Admin Frontend
You can now point your browser to the GRR Admin Frontend to investigate the node with the GRR client.
```
export GRR_ADMIN_IP=$(kubectl get svc svc-grr-admin --output jsonpath='{.spec.clusterIP}')
```
The GRR Admin Frontend can now be reached on the following URL (note that you might have to tunnel to your server first):   
[http://${GRR_ADMIN_IP}:8000](http://${GRR_ADMIN_IP}:8000)


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
