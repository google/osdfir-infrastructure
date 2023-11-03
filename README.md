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

To get started, ensure you have [Helm](https://helm.sh) installed and are authenticated to your Kubernetes cluster.

Once complete, add the repo containing the Helm charts as follows:

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions of the packages.
You can then run `helm search repo osdfir-charts` to see the available charts.

To install the OSDFIR Infrastructure chart using a release name of `my-release`:

```console
helm install my-release osdfir-charts/osdfir-infrastructure
```

To uninstall the chart:

```console
helm uninstall my-release
```

Please refer to the links below for more details on configuring OSDFIR Infrastructure,
using individual tools, and accessing helpful guides.

* [OSDFIR Infrastructure Helm Chart](charts/osdfir-infrastructure/README.md)
* [Turbinia Helm Chart](charts/turbinia/README.md)
* [Timesketch Helm Chart](charts/timesketch/README.md)
* [Getting Started with Minikube](docs/getting-started.md)
* [Understanding Helm Charts](docs/understanding-helm.md)
* [Troubleshooting Helm Charts](docs/troubleshooting.md)
