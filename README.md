# OSDFIR Infrastructure

OSDFIR Infrastructure helps setup Open Source
Digital Forensics tools to Kubernetes clusters using Helm.

Currently, OSDFIR Infrastructure supports the deployment and integration of the following tools:

* [Turbinia](https://github.com/google/turbinia) for automating processing of forensic evidence at scale helping find prevelant badness and includes built-in integrations to many tools such as:
  * [Plaso](https://github.com/log2timeline/plaso) (and related projects such as dfVFS, libyal) for extracting data from a variety of sources into a correlated super timeline
  * [Container Explorer](https://github.com/google/container-explorer) for container level processing
  * [Docker Explorer](https://github.com/google/docker-explorer) for docker container level processing
  * [Fraken](https://github.com/google/turbinia/tree/master/tools/fraken) for multi-threaded yara scanning
  * [Libcloudforensics](https://github.com/google/cloud-forensics-utils/) for mounting evidence from cloud platforms
* [Timesketch](https://github.com/google/timesketch) for collaborative forensic timeline analysis with built-in analyzers to help identitify patterns in data and supports Plaso, JSONL, or CSV file imports
* [dfTimewolf](https://github.com/log2timeline/dftimewolf) for orchestrating forensic collection, processing and data export, helping pass data between tools

These tools can be used independently as well by following the documentation on the tool's repository or by installing a tool specific Helm chart which includes any built-in integrations.

## Installing the Charts

To get started, ensure you have [Helm](https://helm.sh) installed and are authenticated to your Kubernetes cluster, then using a release name of your choice, such as `my-release`, run:

```console
helm install my-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster in the default configuration. See the [GKE Installations](charts/osdfir-infrastructure/README.md) section for installing to GCP environments or to quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

For more information on how to install and configure OSDFIR Infrastructure or individual tools, please refer to the links below.

* [OSDFIR Infrastructure Install Guide](charts/osdfir-infrastructure/README.md)
* [Turbinia Install Guide](charts/turbinia/README.md)
* [Timesketch Install Guide](charts/timesketch/README.md)
