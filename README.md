# OSDFIR Infrastructure
OSDFIR Infrastructure helps setup Open Source
Digital Forensics tools to Kubernetes clusters using Helm. 

Currently, OSDFIR Infrastructure
supports the deployment of the following tools:
  * Timesketch; ref https://github.com/google/timesketch
  * Turbinia; ref https://github.com/google/turbinia
  * dfTimewolf integration; ref https://github.com/log2timeline/dftimewolf

## Installing the Charts
To get started, ensure you have [Helm](https://helm.sh) installed and are 
authenticated to your Kubernetes cluster, then using a release name of your 
choice, such as `osdfir-release`, run:

```console
helm install osdfir-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```
The command deploys OSDFIR Infrastructure on the Kubernetes cluster in the 
default configuration. See the [GKE Installations](charts/osdfir-infrastructure/README.md) 
section for installing to GCP environments or to quickly get started with a local 
cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

For more information on how to install and configure OSDFIR Infrastructure or individual tools, please refer to the links below.
- [OSDFIR Infrastructure Install Guide](charts/osdfir-infrastructure/README.md)
- [Timesketch Install Guide](charts/timesketch/README.md)
- [Turbinia Install Guide](charts/turbinia/README.md)