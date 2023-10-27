# OSDFIR Infrastructure

OSDFIR Infrastructure helps setup Open Source
Digital Forensics tools to Kubernetes clusters using Helm.

Currently, OSDFIR Infrastructure supports the deployment and integration of the following tools:

* [Timesketch](https://github.com/google/timesketch) for collaborative forensic timeline analysis. Using sketches you and your collaborators can organize and work together while using analyzers to help identify patterns in data
* [Turbinia](https://github.com/google/turbinia) for automating processing of forensic evidence at scale and helps perform analysis to find some of the most prevalent badness. Includes built-in integrations to many tools such as:
  * [Container Explorer](https://github.com/google/container-explorer) for container level processing
  * [Docker Explorer](https://github.com/google/docker-explorer) for docker container level processing
  * [Fraken](https://github.com/google/turbinia/tree/master/tools/fraken) for multi-threaded yara scanning
* [dfTimewolf](https://github.com/log2timeline/dftimewolf) a framework for orchestrating forensic collection, processing and data export, helping data be passed along between tools
* [Plaso](https://github.com/log2timeline/plaso) (and related projects such as dfVFS, libyal) used to extract and parse data from a variety of sources (e.g. files, logs, disks, registry hives) into a correlated super timeline and is built into Turbinia and Timesketch containers for timeline generation
* [Libcloudforensics](https://github.com/google/cloud-forensics-utils/) used for collecting and mounting evidence from cloud platforms, imported into dfTimewolf and Turbinia as a library

## Installing the Charts

To get started, ensure you have [Helm](https://helm.sh) installed and are authenticated to your Kubernetes cluster, then using a release name of your choice, such as `my-release`, run:

```console
helm install my-release oci://us-docker.pkg.dev/osdfir-registry/osdfir-charts/osdfir-infrastructure
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster in the default configuration. See the [GKE Installations](charts/osdfir-infrastructure/README.md) section for installing to GCP environments or to quickly get started with a local cluster, see [minikube install docs](https://minikube.sigs.k8s.io/docs/start/).

For more information on how to install and configure OSDFIR Infrastructure or individual tools, please refer to the links below.

* [OSDFIR Infrastructure Install Guide](charts/osdfir-infrastructure/README.md)
* [Timesketch Install Guide](charts/timesketch/README.md)
* [Turbinia Install Guide](charts/turbinia/README.md)
