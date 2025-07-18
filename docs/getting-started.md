## Get Started with OSDFIR Infrastructure Using Minikube

### Introduction

This guide will walk you, step by step, through the process of deploying [OSDFIR Infrastructure](https://github.com/google/osdfir-infrastructure/tree/main/charts/osdfir-infrastructure) on Kubernetes using Minikube.

### Important Terms

[Kubernetes](https://kubernetes.io/), also known as K8s, is an open source system for automating deployment, scaling, and management of containerized applications. It groups containers that make up an application into logical units for easy management and discovery.

Apps can be installed in Kubernetes using [Helm charts](https://helm.sh/). Helm charts are packages that contain all the information that Kubernetes needs to know for managing a specific application within the cluster.

[Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) allows you to run Kubernetes locally. It is a tool that runs a single-node Kubernetes cluster inside a container on your computer. It is an easy way to try out Kubernetes and is also useful for testing and development scenarios.

### Overview

Here are the steps you'll follow in this tutorial:

* [Install Minikube](#step-1-install-minikube)
* [Create a Kubernetes cluster](#step-2-create-a-kubernetes-cluster)
* [Install the *kubectl* command-line tool](#step-3-install-the-kubectl-command-line-tool)
* [Install and configure Helm](#step-4-install-and-configure-helm)
* [Install OSDFIR Infrastructure with Helm](#step-5-install-osdfir-infrastructure-with-helm)
* [Access the Kubernetes Dashboard](#step-6-access-the-kubernetes-dashboard)
* [Uninstall an application using Helm](#step-7-uninstall-an-application-using-helm)

The next sections will walk you through these steps in detail.

### Assumptions and prerequisites

This guide focuses on deploying OSDFIR Infrastructure in a Kubernetes cluster running on Minikube.

This guide assumes that you have a virtualization software such as [Docker](https://www.docker.com/), [Docker Desktop](https://docs.docker.com/desktop/), [Podman](https://podman.io/), or [VirtualBox](https://www.virtualbox.org/wiki/Downloads) installed and running on your computer. For more examples, see the official [Minikube docs](https://minikube.sigs.k8s.io/docs/start/).

### Step 1: Install Minikube

The first step for working with local Kubernetes clusters is to have Minikube installed.

To install Minikube, please see the official [Minikube installation guide](https://minikube.sigs.k8s.io/docs/start/).

### Step 2: Create a Kubernetes cluster

By starting Minikube, a single-node cluster is created. Run the following command in your terminal to complete the creation of the cluster:

```shell
minikube start
```

### Step 3: Install the *kubectl* command-line tool

To run your commands against Kubernetes clusters, the *kubectl* CLI is needed.

To install kubectl, please see the official [kubectl installation guide](https://kubernetes.io/docs/tasks/tools/).

> TIP: On Debian/Ubuntu-based Linux systems, you can also install *kubectl* by using the *sudo apt-get install kubectl* command.

* Check that *kubectl* is correctly installed and configured by running the *kubectl cluster-info* command:

    ```shell
    kubectl cluster-info
    ```

    ![cluster-info](images/cluster-info.png)

    > NOTE: The *kubectl cluster-info* command shows the IP addresses of the Kubernetes node master and its services.

* You can also verify the cluster by checking the nodes. Use the following command to list the connected nodes:

    ```shell
    kubectl get nodes
    ```

* To get complete information on each node, run the following:

    ```shell
    kubectl describe node
    ```

[Learn more about the *kubectl* CLI](https://kubernetes.io/docs/user-guide/kubectl-overview/).

### Step 4: Install and configure Helm

In order to deploy and manage applications within the OSDFIR Infrastrucutre Helm chart, you need to install Helm.

To install Helm, please see the official [Helm installation guide](https://helm.sh/docs/intro/install/).

### Step 5: Install OSDFIR Infrastructure with Helm

A Helm chart describes a specific version of an application or set of applications, also known as a "release". The "release" includes files with Kubernetes-needed resources and files that describe the installation, configuration, and usage of a chart.

By executing the *helm install* command the Helm chart will be deployed on the Kubernetes cluster. For OSDFIR Infrastructure, this includes the deployment of [Timesketch](https://timesketch.org/), [OpenRelik](https://openrelik.org/), [Yeti](https://yeti-platform.io/), and [GRR](https://www.grr-response.com/).

To get started, add the OSDFIR Infrastructure repo and then update to pick up any new changes that were made to the Helm charts.

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure/
helm repo update
```

To install the OSDFIR Infrastructure chart, specify any release name of your choice. For example, using a release name of `my-release`, run:

```shell
helm install my-release osdfir-charts/osdfir-infrastructure
```

Once you have the chart installed a "Notes" section will be shown at the bottom of the installation information. It contains important instructions about how to access the tools. Please check it carefully:

![notes-txt](images/notes-txt.png)

> IMPORTANT: When installing the Helm chart then running *kubectl get pods* immediately after, you may see errors such as *CrashLoopBackOff* and your application may fail to start. This is typically because the Persistent Volumes are still provisioning or the docker images are still being pulled and may need to wait a few minutes for the error to resolve.

### Step 6: Access the Kubernetes Dashboard

The [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) is a Web user interface from which you can manage your clusters in a more simple and digestible way.

To get a URL for the Kubernetes Dashboard, run the following command:

```shell
minikube dashboard --url
```

With this command, you will be redirected automatically to the Kubernetes Dashboard where you will get an overview of all the deployed components in your cluster.

![dashboard-overview](images/dashboard-overview.png)

From this home screen, you can perform some basic actions such as:

* Monitoring the status of your deployments and pods.
* Checking pod and container(s) logs to identify possible errors during the creation of the containers.
* Finding application credentials.

#### Monitor the status of Deployments and Pods

##### Monitor Deployments

* To check detailed information about the status of your deployments, navigate to the "Workloads -> Deployments" section located on the left menu. It shows a screen with a graphical representation of the CPU and memory usage, as well as a list of all deployments you have in your cluster.

![dashboard-deployments](images/dashboard-deployments.png)

* Click each deployment to obtain detailed information of the selected deployment:

![dashboard-deployment-detail](images/dashboard-deployment-detail.png)

Alternatively, you can grab the equivalent deployment information using kubectl:

```shell
kubectl get deployments
```

For detailed information around a given deployment, replacing DEPLOYMENT_NAME
with the deployment you want to inspect:

```shell
kubectl describe deployment DEPLOYMENT_NAME
```

##### Monitoring pods

Pods are the smallest units in Kubernetes deployments. They can contain one or multiple containers (that need to share resources in order to work together). [Learn more about pods](https://kubernetes.io/docs/concepts/workloads/pods/).

When you click on a pod in the "Workloads -> Pods", you access the pod list. By selecting a pod, you will see the "Details" section that contains information related to the pod,and a "Containers" section that includes the information related to this pod's container(s).

Follow these instructions to access pod and container information:

* To check the status of your deployments in detail, navigate to the "Workloads -> Pods" section located on the left menu. It shows the pod list:

![dashboard-pods](images/dashboard-pods.png)

* Click the pod you'd like to access further details for.

![dashboard-pod-detail](images/dashboard-pod-detail.png)

* As indicated in the image above, you will find a "View logs" link and a "Exec into pod" link at the top right corner. Click either option to review logs for possible errors that might have occurred or to directly access the pod itself.

Alternatively, you can grab the equivalent Pod information using kubectl:

```shell
kubectl get pods
```

For detailed information around a given pod, replacing POD_NAME
with the pod you want to inspect:

```shell
kubectl describe pod POD_NAME
```

For logs around a given pod, replacing POD_NAME
with the pod you want to grab logs from:

```shell
kubectl logs POD_NAME
```

For a shell directly into the pod, replacing POD_NAME with the pod you want to exec into:

```shell
kubectl exec --stdin --tty POD_NAME -- /bin/bash
```

#### Find application credentials

The Timesketch login  credentials are shown in the "Notes" section after installing the application chart:

![notes-txt-secret](images/notes-txt-secret.png)

Alternatively, to get it from the Kubernetes Dashboard, follow these instructions:

* Navigate to the "Config and Storage -> Secrets" section located on the left menu.

* Click the application for which you wish to obtain the credentials.

* In the "Data" section, click the eye icon to see the password:

![dashboard-secrets](images/dashboard-secrets.png)

### Step 7: Uninstall an application using Helm

To uninstall an application, you need to run the *helm uninstall* command. Every Kubernetes resource that is tied to that release will be removed except for Persistent Volumes.

> TIP: To get the release name, you can run the *helm list* command.

```shell
helm uninstall my-release
```

> NOTE: Remember that `my-release` is a placeholder, replace it with the name you have used during the chart installation process.

To delete all Persistent Volumes in the cluster, run:

```shell
kubectl delete pvc --all
kubectl delete pv --all
```

To delete a specific Persistent Volume instead, first run the following commands to get the name of the Persistent Volume Claim and Persistent Volume you want to delete:

```shell
kubectl get pvc
kubectl get pv
```

Then, replace the `PVC-NAME` and `PV-NAME` placeholder with the names you got from the previous command and run the following commands to delete the Persistent Volume Claim and Persistent Volume:

```shell
kubectl delete pvc PVC-NAME
kubectl delete pv PV-NAME
```

To delete the Minikube cluster and associated resources, run:

```shell
minikube delete --all
```

### Useful links

To learn more about the topics discussed in this guide, use the links below:

* [Minikube](https://github.com/kubernetes/minikube)
* [Google Kubernetes Engine](https://cloud.google.com/container-engine/)
* [Kubernetes](https://kubernetes.io/)
* [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
* [Kubectl for Docker users](https://kubernetes.io/docs/reference/kubectl/docker-cli-to-kubectl/)
* [Helm](https://helm.sh/)
