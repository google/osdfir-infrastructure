# OSDFIR Infrastructure

OSDFIR Infrastructure simplifies the deployment and integration of Open Source
Digital Forensics tools to Kubernetes clusters (local or cloud) using Helm.

Currently, OSDFIR Infrastructure supports the deployment and integration of the following tools:

* [dfTimewolf](https://github.com/log2timeline/dftimewolf) for orchestrating forensic collection, processing and data export, helping pass data between tools using recipes (e.g. importing processed Plaso files from Turbinia into Timesketch)
* [Timesketch](https://github.com/google/timesketch) for collaborative forensic timeline analysis featuring analyzers to help identitify patterns in data, support for Plaso, JSONL, or CSV file imports, and built-in integrations to tools such as:
  * [DFIQ](https://dfiq.org/) for digital forensics investigative questions and the approaches to answering them
  * [Sigma](https://github.com/SigmaHQ/sigma) for detection and hunting rules to run across timelines
  * [Unfurl](https://github.com/obsidianforensics/unfurl) for graph analysis of URLs
* [Turbinia](https://github.com/google/turbinia) for automating processing of forensic evidence at scale helping find prevelant badness and includes built-in integrations to many tools such as:
  * [Container Explorer](https://github.com/google/container-explorer) for container level processing
  * [Docker Explorer](https://github.com/google/docker-explorer) for docker container level processing
  * [Fraken](https://github.com/google/turbinia/tree/master/tools/fraken) for multi-threaded yara scanning
  * [Libcloudforensics](https://github.com/google/cloud-forensics-utils/) for mounting evidence from cloud platforms
  * [Plaso](https://github.com/log2timeline/plaso) (and related projects such as dfVFS, libyal) for extracting data from a variety of sources into a correlated super timeline
* [Yeti](https://github.com/yeti-platform/yeti) for DFIR and threat intelligence tracking, enabling responders to store and analyze CTI (observables, TTPs, campaigns, etc.) from internal and external systems and integrates with Timesketch
* [GRR](https://github.com/google/grr) for incident response and remote live forensics.

These tools can be used independently as well by following the documentation on the tool's repository or by installing a tool specific Helm chart which includes any built-in integrations.

## Installing the Charts

To get started, ensure you have [Helm](https://helm.sh) installed and are authenticated to your Kubernetes cluster.
> **IMPORTANT**: For cloud deployments, Turbinia currently only supports attaching disks from GCP environments. Manual disk attachment or utilizing other evidence types is necessary
for other cloud providers.

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

> **Note**: The default configuration of the Helm chart installs it within your cluster for internal access. To enable external access, follow the instructions provided in the Helm chart's README.

To uninstall the chart:

```console
helm uninstall my-release
```

Please refer to the links below for more details on configuring OSDFIR Infrastructure,
using individual tools, and accessing helpful guides.

* [Getting Started with Minikube](docs/getting-started.md)
* [OSDFIR Infrastructure Helm Chart](charts/osdfir-infrastructure/README.md)
* [Timesketch Helm Chart](charts/timesketch/README.md)
* [Turbinia Helm Chart](charts/turbinia/README.md)
* [Troubleshooting Helm Charts](docs/troubleshooting.md)
* [Understanding Helm Charts](docs/understanding-helm.md)
* [Yeti Helm Chart](charts/yeti/README.md)
* [GRR Helm Chart](charts/grr/README.md)

---

##### Obligatory Fine Print

This is not an official Google product (experimental or otherwise), it is just
code that happens to be owned by Google.
