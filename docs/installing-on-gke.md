# Deploying OSDFIR Infrastructure on Google Kubernetes Engine (GKE)

In this tutorial you will learn how to deploy and configure OSDFIR Infrastructure
on Google Kubernetes Engine (GKE). You will then learn how to configure dfTimewolf
to process a Google Cloud disk using Turbinia and then import any created timelines
into Timesketch.


GRR is not currently supported in this Helm chart deployment. We are working to
add GRR support in a future release. In the meantime, you can find a dedicated
guide for deploying GRR on GKE [here](https://github.com/google/osdfir-infrastructure/tree/main/cloud).

## Prerequisites

💻 **Google Cloud Account**: You'll need a Google Cloud Platform (GCP) account.
To create an account, you'll need to provide a credit card or bank account for
verification. Visit the [Get started with Google Cloud page](https://cloud.google.com/docs/get-started)
and follow the instructions.

> *Note*: 💵 If you have never used Google Cloud before, you may be eligible for
the [Google Cloud Free Program](https://cloud.google.com/free/docs/gcp-free-tier/#free-trial),
which gives you a 90 day trial period that includes $300 in free Cloud Billing
credits to explore and evaluate Google Cloud.

💻 **Software**: You will also need to install the following software on your laptop:

1. [gcloud](https://cloud.google.com/sdk/docs/install): A set of tools to create
and manage Google Cloud resources.
2. [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): The Kubernetes
command-line tool which allows you to configure Kubernetes clusters.
3. [Helm](https://helm.sh/): The package manager for Kubernetes to which we will
be installing OSDFIR Infrastructure with.

ℹ️ We recommend using [Google Cloud Shell](https://cloud.google.com/shell/docs/launching-cloud-shell)
when following this tutorial. It already has the required software installed by default.


## Step 0: Configure gcloud with a Google Cloud project

To set up your Google Cloud environment, run the following command:

```bash
gcloud init
```

You will need to answer "yes" to the following question:

```bash
Do you want to configure a default Compute Region and Zone? (Y/n)?  Y
```

After running the command, you'll be prompted to configure a default Compute
Region and Zone. Choose a region and zone that are geographically close to you
for optimal performance. You'll then see your project name, the selected default
region, and default zone.

Throughout this tutorial, we'll use environment variables like `$PROJECT_ID` to
represent values specific to your GCP setup. You have two options for handling
these:

1. **Manual Replacement**: Replace the variable with your actual value directly
in the command before executing it.
2. **Export Variables**: Export the variables in your shell session, as shown in
the next step. This allows you to use the variables directly in commands.

In the following steps, we'll use the second option: exporting environment
variables. If a step requires you to manually replace a variable, we'll explicitly
state that.

## Step 1: Enable the required Google Cloud APIs

Enable the necessary APIs:

```bash
gcloud services enable iam.googleapis.com \
                       container.googleapis.com \
                       compute.googleapis.com \
                       file.googleapis.com
```

## Step 2: Set up Environment Variables

Before creating the Kubernetes (K8s) cluster, define the following environment
variables in your terminal. You do not have to create any of these resources
beforehand, as this guide will walk you through the process.

Replace the placeholders with your actual values:

```bash
export PROJECT_ID="your-gcp-project"  # Your Google Cloud project ID
export PROJECT_NUMBER="your-gcp-number"  # Your Google Cloud project number
export REGION="us-central1" # The region of your cluster 
export ZONE="us-central1-f"  # The zone where you want to create the cluster
export CLUSTER="osdfir-cluster"  # The name you choose for your K8s cluster
export NAMESPACE="default"  # Your K8s namespace (can be left as 'default')
export KSA_NAME="turbinia"  # Your Turbinia K8s service account (defaults to 'turbinia' if not set)
```

> *Note*: You can find the GCP project number by running `gcloud projects describe $PROJECT_ID`

## Step 3: Create a Kubernetes Cluster

Now, create the Kubernetes cluster with the specified configurations:

```bash
gcloud container clusters create $CLUSTER \
    --num-nodes=1 \
    --machine-type "e2-standard-8" \
    --zone $ZONE \
    --workload-pool=$PROJECT_ID.svc.id.goog \
    --enable-l4-ilb-subsetting \
    --addons=GcpFilestoreCsiDriver,GcsFuseCsiDriver,HttpLoadBalancing
```

> *Note*: It will take 4-5 minutes to create the cluster.

This command creates a single-node cluster with the necessary resources and addons
for running OSDFIR Infrastructure.

Important Considerations:

* GKE Autopilot is not currently supported because Turbinia workers require
elevated privileges for disk processing.
* Only a single zone cluster can be used with Turbinia.
* Deployments require a machine type of at least `e2-standard-8`
(or an equivalent with at least 8 vCPUs).
* For clusters with more than one node, a shared filesystem like GCP Filestore is
required. This involves configuring a Persistent Volume Claim (PVC) with `ReadWriteMany`
access in Kubernetes. Detailed instructions for provisioning shared filesystems
are provided in the 'Provisioning shared filestorage (optional)' section.

OSDFIR Infrastructure provides a [shell script](https://github.com/google/osdfir-infrastructure/blob/main/tools/init-gke.sh)
for automating provisioning of a private GKE cluster. However, working through
these manual steps first is recommended to gain a foundational understanding and
minimize the chances of encountering issues during deployment.

### Configure kubectl to Access the Cluster

Once the cluster has been created, set up the Google Kubernetes Engine auth
plugin for kubectl:

```bash
sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials $CLUSTER --zone $ZONE
```

Now check that you can connect to the cluster:

```bash
kubectl get nodes -o wide
```

## Step 4: Create the Turbinia GCP Service Account

To process virtual machine disks in Google Cloud Platform (GCP) with Turbinia,
you need a dedicated GCP service account with the necessary permissions to attach
and detach disks.

```bash
# Grant the Compute Instance Admin role for attaching and detaching disks
gcloud projects add-iam-policy-binding projects/$PROJECT_ID \
    --role=roles/compute.instanceAdmin \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/$KSA_NAME
```

```bash
# Grant the Service Account user role to allow the account to act as a service account
gcloud projects add-iam-policy-binding projects/$PROJECT_ID \
    --role=roles/iam.serviceAccountUser \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/$KSA_NAME
```

These command grants the following roles to the service account:

* Compute Instance Admin: Allows Turbinia to attach and detach disks from GCP
VMs for processing.
* Service Account User: Allows the Turbinia service account to act as this newly
created service account.

## Step 5: Deploy the OSDFIR Infrastructure Helm Chart

Now it is time to deploy the OSDFIR Infrastructure Helm chart.

The first step is to add the repo and then update to pick up any new changes.

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure
helm repo update
```

To install the chart, specify any release name of your choice.
For example, using `my-release` as the release name, run:

```bash
helm install my-release osdfir-charts/osdfir-infrastructure \
    --set turbinia.gcp.enabled=true \
    --set turbinia.gcp.projectID=$PROJECT_ID \
    --set turbinia.gcp.projectRegion=$REGION \
    --set turbinia.gcp.projectZone=$ZONE \
    --set turbinia.serviceaccount.name=$KSA_NAME \
    --set persistence.size=10Gi
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster while enabling
Turbinia GCP integration and increasing the OSDFIR Infrastructure disk size to
10 Gigabytes to allow for enough space for the processed forensic output.

Verify the deployment:

```bash
kubectl get pods
```

You should see pods for Timesketch, Turbinia, and Yeti in a Running state. It may
take a few minutes for all the services to deploy.

### Provisioning shared filestorage (optional)

While this example uses a single node, you might need persistent storage for
multi-node deployments. To enable persistent storage with a `ReadWriteMany` PVC,
add the following `--set` flags to your helm install command:

```bash
--set persistence.storageClass="standard-rwx" \
--set persistence.accessModes[0]="ReadWriteMany"
```

This configures OSDFIR Infrastructure to provision a GCP Filestore instance with
`ReadWriteMany` access mode, which is suitable for multi-node clusters where
shared storage is required.

## Step 6: Expose Fleetspeak/GRR on L4 LoadBalancer

The default way that the Fleetspeak frontend for GRR is exposed is through a ```NodePort``` (port 30443) on the node IP.

```node``` exposes the Fleetspeak frontend as a ```NodePort``` service.

* Find the IP for one of your cluster nodes and install the chart as following:

> [!NOTE]
> If you are running on minikube this could be done by running ```minikube ip```

```bash
helm install my-release osdfir-charts/osdfir-infrastructure --set fleetspeak.frontend.expose="node" --set fleetspeak.frontend.address="$NODE_IP"
```

* Once the Fleetspeak frontend ```pod``` is running you can install the GRR agent
  binaries on your clients in the same network as the node is running in.
* This is the simplest mode and only suitable for demo purposes.
* For a production grade deployment use either an interal or an external L4 LoadBalancer as described below.

### Use an Internal L4 LoadBalancer

```internal``` exposes the Fleetspeak frontend as an [internal Google Cloud L4 LoadBalancer](https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balancing)

* This allows you to keep your Fleetspeak/GRR cluster on your private VPC.
* You will have to reserve a static internal IP address in your Google Cloud Project first.

```console
gcloud compute addresses create fleetspeak-frontend-internal \
  --region=us-central1 --subnet=default

# Find the IP address that you have been allocated.
gcloud compute addresses describe fleetspeak-frontend-internal --region=us-central1
```

* Choose the values for the ```REGION``` and ```SUBNETWORK```
 so they match the location where you run your GKE cluster.

```bash
helm install my-release osdfir-charts/osdfir-infrastructure --set fleetspeak.frontend.expose="internal" --set fleetspeak.frontend.address="$IP_ADDRESS"
```

* Once the Fleetspeak frontend ```pod``` is running you can install the GRR agent
 binaries on your clients in the same Google Cloud VPC as the node is running in.

### Use an External L4 LoadBalancer

```external``` exposes the Fleetspeak frontend as an [external Google Cloud L4 LoadBalancer](https://cloud.google.com/kubernetes-engine/docs/how-to/backend-service-based-external-load-balancer)

* This allows you to run your Fleetspeak/GRR cluster so it is available from
 anywhere on the Internet. Use this with caution as it exposes your cluster externally!
* You will have to reserve a static external IP address in your Google Cloud Project first.

```console
gcloud compute addresses create fleetspeak-frontend-external --region=us-central1
     
# Find the IP address that you have been allocated.
gcloud compute addresses describe fleetspeak-frontend-external --region=us-central1
```

* Choose the value for the ```REGION``` so it matches the location where
 you run your GKE cluster.

```bash
helm install my-release osdfir-charts/osdfir-infrastructure --set fleetspeak.frontend.expose="external" --set fleetspeak.frontend.address="$IP_ADDRESS"
```

* Once the Fleetspeak frontend ```pod``` is running you can install the GRR agent
 binaries on your clients anywhere where they have access to the Internet.

## Step 7: Setup dfTimewolf and CLI configs

OSDFIR Infrastructure utilizes dfTimewolf for orchestrating forensic collection
and processing. dfTimewolf allows you to define "recipes" that specify how data
should be collected, processed by tools like Turbinia, and exported to platforms
like Timesketch.

To install dfTimewolf, you'll need to have Python 3.11 or greater, `git`, and
`pip` installed on your machine. dfTimewolf uses Poetry for simplified dependency
management.

First, clone the dfTimewolf repository:

```bash
git clone https://github.com/log2timeline/dftimewolf.git && cd dftimewolf
```

Install Poetry, then use it to install dfTimewolf's dependencies:

```bash
pip install poetry
poetry install && poetry shell
```

*Troubleshooting*: If Poetry is not found, add its bin directory to your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Once done, retrieve the Timesketch password from your deployment. For example,
to grab it from a release named `my-release`, run:

```bash
kubectl get secret --namespace default my-release-timesketch-secret -o jsonpath="{.data.timesketch-user}" | base64 -d && echo ""
```

dfTimewolf uses a configuration file called `.dftimewolfrc` to store settings
such as your Timesketch credentials and endpoint. This allows you to avoid
entering these details every time you run a recipe.

Now, create a `.dftimewolfrc` file in your HOME directory, replacing
`$TIMESKETCH_PASSWORD` with the Timesketch password retrieved in the previous step:

```bash
cat >> ~/.dftimewolfrc << EOF
{
    "timesketch_username": "timesketch",
    "timesketch_password": "$TIMESKETCH_PASSWORD",
    "timesketch_endpoint": "http://127.0.0.1:5000",
    "turbinia_api": "http://127.0.0.1:8000"
}
EOF
```

Now you have dfTimewolf installed and configured to interact with your OSDFIR
Infrastructure deployment.

## Step 8: Process a Google Cloud Disk

With OSDFIR Infrastructure deployed and dfTimewolf installed and configured,
you're ready to process a GCP disk.

This example uses the dfTimewolf `gcp_turbinia_ts` recipe, which processes an
existing GCP persistent disk with Turbinia and sends the resulting Plaso timeline
to Timesketch.

To begin, create a disk to process. For example, to create a disk with one of the
base debian images, run:

```bash
gcloud compute disks create test-debian-image \
  --image=debian-12-bookworm-arm64-v20241009 \
  --image-project debian-cloud \
  --size 10GB \
  --zone $ZONE 
```

Important Considerations:

* The recipe requires that the disk being processed is in the same zone Turbinia
is deployed to. To process a disk from a different GCP project or zone, refer to
the "Additional Workflows" section on using the `gcp_turbinia_disk_copy_ts` recipe.

* If you encounter an error stating that the image cannot be found, you can list
the available Debian images by running:

    ```bash
    gcloud compute images list --filter debian-cloud
    ```

    Then, choose an available image name from the list and update the `--image` flag
    in the disk creation command accordingly.

You'll then need to use `kubectl port-forward` to forward the Turbinia and Timesketch
services locally to your machine. This allows you to access the Turbinia UI and
the Timesketch API from your local machine.

For example, to port-forward from a release named `my-release`, open up two new
tabs or terminals, then run the following commands in each terminal.

For the Turbinia service:

```bash
kubectl --namespace default port-forward service/my-release-turbinia 8000:8000
```

For the Timesketch service:

```bash
kubectl --namespace default port-forward service/my-release-timesketch 5000:5000  
```

This will allow dfTimewolf to access the Turbinia and Timesketch services locally
from your machine.

In your original terminal (where you set the environment variables), run the
dfTimewolf recipe:

```bash
dftimewolf gcp_turbinia_ts $PROJECT_ID $ZONE --disk_names test-debian-image
```

This command will:

* Process the disk with Turbinia, performing various forensic tasks such as running
Plaso and looking for prevelant anomalies.
* Export any generated Plaso files to Timesketch.

You can monitor the progress of the processing in the Turbinia UI
(`http://localhost:8000`) and in the dfTimewolf output. Once the processing is
complete, log in to Timesketch (`http://localhost:5000`) and verify that a new
timeline has been created. You can then explore the timeline to analyze the
processed artifacts. When using Google Cloud Shell, you can utilize the
[web preview feature](https://cloud.google.com/shell/docs/using-web-preview#preview_the_application)
to view the UIs.

Congratulations on completing the setup and processing your first disk! Explore
the optional workflows for more examples.

### Additional Workflows

#### Processing Disks from a Different Project or Zone

In a real-world scenario, you may need to process a GCP instance or disk belonging
to a different project or zone. To do this, you can use the dfTimewolf recipe
`gcp_turbinia_disk_copy_ts`. This recipe copies the disk from the source project
to your analysis project running OSDFIR Infrastructure, then processes it with
Turbinia and sends the Plaso results to Timesketch.

This recipe also proves useful when your disk resides within the same project but
in a different zone. In this case, simply specify your analysis project as both
the source and destination project within the recipe.

#### Processing Local Evidence with Turbinia

This method is useful when you have evidence that is not located on a GCP disk
(e.g., evidence from a local machine).

To copy evidence data into the Turbinia pod, first identify a Turbinia pod by
running `kubectl get pods`. Then, use the `kubectl cp` command to copy the evidence
file to the desired location within the pod. For example, to copy `my_evidence.dd`
from your current directory to the `/mnt/turbiniavolume` directory in the
`my-release-turbinia-server-0` pod, run:

```bash
kubectl cp ./my_evidence.dd my-release-turbinia-server-0:/mnt/turbiniavolume/my_evidence.dd
```

To interact with Turbinia and submit processing jobs, you'll need to install the
Turbinia client and configure it to connect to your Turbinia server.

```bash
pip3 install turbinia-client
```

Create a configuration file named `.turbinia_api_config.json` in your home
directory with the following content:

```bash
cat >> ~/.turbinia_api_config.json << EOF
{
    "default": {
        "API_SERVER_ADDRESS": "http://localhost",
        "API_SERVER_PORT": 8000,
        "API_AUTHENTICATION_ENABLED": false,
        "CREDENTIALS_FILENAME": "",
        "CLIENT_SECRETS_FILENAME": ""
    }
}
EOF
```

Then, submit a Turbinia request for the evidence:


```bash
turbinia-client submit rawdisk --source_path /mnt/turbiniavolume/my_evidence.dd
```

This command submits a Turbinia request for the evidence you copied. The
`--source_path` parameter specifies the path to the evidence within the Turbinia
pod.

You can monitor the progress of the processing in the Turbinia UI
(accessible by port-forwarding). Any Plaso jobs that run can have their output
directly downloaded from the Turbinia UI and imported into Timesketch.

#### Using Timesketch

To learn more about using Timesketch in detail check out the [user guide](https://timesketch.org/guides/user/sketch-overview/).

#### Searching for IoCs with Yeti

Yeti enhances your Timesketch investigations by enabling you to search for
Yeti Intelligence (IoCs, threat data, etc.) across Timesketch timelines.

Learn how to use Yeti with Timesketch by following this
[guide](https://yeti-platform.io/guides/indicators-timesketch/investigation/).
