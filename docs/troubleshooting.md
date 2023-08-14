## Troubleshoot OSDFIR Infrastructure Issues

OSDFIR Infrastructure Helm charts provide an easy way to install and manage open source Digital Forensics & Incident Response (DFIR) tools on Kubernetes.

This guide explains how to troubleshoot common issues related to OSDFIR Infrastructure's Helm chart.

### Common issues

The following are the most common issues that users face when dealing with deployments:

* Pods failing to start up
* Unable to access services
* Persistence Volumes (PVs) failing to provision
* An issue with the underlying Helm chart

### Troubleshoot Pods

To check if the status of your pods is healthy, the easiest way is to run the *kubectl get pods* command. After that, you can use *kubectl describe* and *kubectl logs* to obtain more detailed information.

Once you run *kubectl get pods*, you may find your pods showing any of the following statuses:

* *Pending* or *CrashLoopBackOff*
* *ImagePullBackOff* or *ErrImagePull*
* *Init:CrashLoopBackOff* or *Init:Error*

If you see any of the statuses above, this means that the pod could not be scheduled on a node. Usually, this is because
of insufficient CPU or memory resources. It may also come up due to a network related issue or provisioning a volume.

> IMPORTANT: Please wait a few minutes for errors to resolve when installing a Helm chart for the first time as it is likely still provisioning the necessary resources.

To confirm the cause, note the pod you want to investigate from *kubectl get pods*, replacing `POD-NAME` with the name of the pod, then run:

```shell
$ kubectl describe pod POD-NAME
```

You should see an output message providing some information about why the pod is failing.  Additionally, you can review logs of the pod by running:

```shell
$ kubectl logs POD-NAME
```

Another option can be to review logs stored within the pod. To gain shell access to a pod, run:

```shell
$ kubectl exec -it POD-NAME -- /bin/bash
```

> TIP: Turbinia logs can be found in `/mnt/turbiniavolume/logs` and Timesketch logs can be found in `/var/log/timesketch`.

When your pod status is *ImagePullBackOff* or *ErrImagePull*, this means that the pod could not run because it could not pull the image. This typically occurs when there is either an invalid Image or the Kubernetes cluster does not have Internet connectivity. Try pulling the image manually on the host using *docker pull*. For example, to manually pull an image from Docker Hub, use the command below by replacing IMAGE with the image ID:

```shell
$ docker pull IMAGE
```

> TIP: When using a private GKE cluster in GCP, please ensure you have a [Cloud NAT](https://cloud.google.com/nat/docs/gke-example#gcloud_3) configured with the network router of your cluster so that third party dependencies can be retrieved.

When your pod status is *Init:CrashLoopBackOff* or *Init:Error*, this means that the pod's init container could not run. To investigate, review the logs of the init container, replacing `POD-NAME` with the pod name and `INIT-POD` with the name of the init pod, then run:

```shell
$ kubectl logs POD-NAME -c INIT-POD
```

> TIP: The respective init container names for Turbinia is `init-turbinia` and for Timesketch is `init-timesketch`.

For more troubleshooting tips, see the official k8s docs for [troubleshooting pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/).

### Troubleshoot Services

Sometimes, when you start a new installation in Kubernetes you may find that a service doesn’t respond when you try to access it, although it was created by a pod in a deployment.

First you can check that the service you are trying to access actually exists, by running the following (replace SVC-NAME with the name of the service you want to access):

```shell
$ kubectl get SVC-NAME
```

To get detailed information around the service if it exists, run:

```shell
$ kubectl describe SVC-NAME
```

You should see an output message providing some information including any service issues.

If the service is registered and no issues were detected from the step above, it could also be a DNS problem. DNS problems
typically occurs when a service is in a different namespace then the pod or if the cluster does not have DNS enabled.

To troubleshoot, run the *kubectl get pods* command to get the name of your pod. Then run the command below, this will give you an indication if the DNS resolution is working or not. (remember to replace the `POD-NAME` placeholder with the pod name and `SVC-NAME` placeholder with the name of the service).

```shell
$ kubectl exec -it POD-NAME nslookup SVC-NAME
```

If the error persists, then [confirm that DNS is enabled for your Kubernetes cluster](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/). Check out the Kubernetes official documentation to learn how to [debug DNS resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/).

Lastly, if the service was attached to an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) (Load Balancer), you can check for issues related to the Ingress deployment. To troubleshoot, run the *kubectl get ingress* command to get the name of your ingress. Then, replacing `INGRESS-NAME` placeholder with the Ingress name, run:

```shell
$ kubectl describe ingress INGRESS-NAME
```

You should see an output message providing some information including any Ingress issues.

For more troubleshooting tips, see the official k8s docs for [troubleshooting services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/).

### Troubleshoot Persistence Volumes

The next common problem to occur is Persistent Volumes failing to provision. To check the status of your persistent volumes, run *kubectl get pvc*. If the output message shows that your PVC status is pending, this may be because your cluster does not support dynamic provisioning (such as a bare metal cluster). In this case, the pod is unable to start because the cluster is unable to fulfil the request to attach the persistent volume to your pod.

To get detailed information around the PVC, replacing `PVC-NAME` with the PVC you want to investigate, run:

```shell
$ kubectl describe PVC-NAME
```

To fix this, you must manually configure some persistent volumes or set up a *StorageClass* resource and provisioner for dynamic volume provisioning, such as the [NFS provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs). [Learn more about dynamic provisioning and storage classes](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/).

You can also check out the official K8s documentation for a list of supported [volumes](https://kubernetes.io/docs/concepts/storage/volumes/).

### Troubleshoot Helm Charts

The following are the most common issues users face when installing Helm charts:

* Connection time out when installing a chart
* Credential errors due to upgrades and existing Persistence Volumes (PVs) from previous releases

When a timeout occurs installing a chart, the error will look similar to this:

```shell
Error: INSTALLATION FAILED: Kubernetes cluster unreachable: Get "https://IP-ADDRESS/version": dial tcp IP-ADDRESS connect: connection timed out
```

To fix, wait a few minutes then try again. If the problem persists, ensure you are connected to the cluster by running a  command such as *kubectl get pods* or increase the `--timeout` field when installing the chart.

Another common issue is credential related errors, caused by a [known issue](https://github.com/bitnami/charts/issues/2061) with PostgreSQL authentication failing after re-deployment. This occurs when you delete the deployed Helm chart while keeping the existing persistent volumes as they are not removed by default. When re-deploying the chart using the same release name, this causes the secret generating the credentials to go out-of-sync with the password being persisted.

To prevent, ensure the underlying PVC has also been removed when uninstalling the chart or use a different release name. For example, to delete PVCs related to the PostgreSQL deployment, run:

```shell
$ helm delete pvc -l "app.kubernetes.io/name=postgresql"
```

If persisting the existing data is important, you can also choose to rollback the previous deployment. Use the following [guide](https://docs.bitnami.com/general/how-to/troubleshoot-helm-chart-issues/) for more instructions on rolling back your deployment.

Some other common troubleshooting methods when working with Helm charts is to use the `--dry-run` flag and compare the intended state vs the actual state. To do so, replacing `RELEASE-NAME` with a name of your release, run:

```shell
$ helm install RELEASE-NAME --dry-run --debug ../mychart
```

Visit the [official docs](https://helm.sh/docs/) to learn more about Helm and the various commands that can be run.

### Common K8s Commands

The following table lists common kubectl commands used when troubleshooting deployment issues. For an extensive list, please refer to the official [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/).

```shell
# Get Cluster events
kubectl events                                # List all cluster events
kubectl events --types=Warning                # List all warning events
kubectl events | grep "error"                 # List all events and grep for errors

# Get commands with basic output
kubectl get pods -A -o wide                   # List all pods in all namespaces and associated nodes
kubectl get pods                              # List all pods in the namespace
kubectl get deployment                        # List all deployments in the namespace
kubectl get services                          # List all services in the namespace
kubectl get ingress                           # List all ingress in the namespace
kubectl get configmap                         # List all configmaps in the namespace
kubectl get secrets                           # List all secrets in the namespace
kubectl get hpa                               # List horizontal autoscaler
kubectl get pvc                               # List all persistent volumes in the namespace
kubectl get sc                                # List all storage classes
kubectl get nodes                             # List all nodes in the cluster

# Describe commands with basic output
kubectl describe pod POD-NAME                 # Detailed information of a given pod
kubectl describe deployment DEPLOYMENT-NAME   # Detailed information of a given deployment
kubectl describe service SVC-NAME             # Detailed information of a given service
kubectl describe ingress INGRESS-NAME         # Detailed information of a given ingress
kubectl describe configmap CONFIG-NAME        # Detailed information of a given configmap
kubectl describe secret SECRET-NAME           # Detailed information of a given secret
kubectl describe hpa HPA-NAME                 # Detailed information of a given horizontal autoscaler
kubectl describe pvc PVC-NAME                 # Detailed information of a given persistent volume
kubectl describe sc SC-NAME                   # Detailed information of a given storage class
kubectl describe node NODE-NAME               # Detailed information of a given node

# Interacting with running pods
kubectl logs POD-NAME                         # Show pod logs (stdout)
kubectl logs POD-NAME --previous              # Show pod logs (stdout) for a previous instantiation of a container
kubectl logs POD-NAME -c my-container         # Show pod container logs of an init container (stdout)
kubectl exec -it POD-NAME -- /bin/bash        # Interactive shell access to a running pod
kubectl port-forward POD-NAME 5000:6000       # Listen on port 5000 on the local machine and forward to port 6000 on POD-NAME
kubectl cp /tmp/foo_dir POD-NAME:/tmp/bar_dir # Copy /tmp/foo_dir local directory to /tmp/bar_dir in a remote pod in the current namespace
kubectl cp POD-NAME:/tmp/foo /tmp/bar         # Copy /tmp/foo from a remote pod to /tmp/bar locally
kubectl top pods                              # Show pod usage (cpu/mem)
kubectl top nodes                             # Show node usage (cpu/mem)
```
