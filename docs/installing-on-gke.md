# Deploying OSDFIR Infrastructure on Google Kubernetes Engine (GKE)

In this tutorial you will learn how to deploy and configure OSDFIR Infrastructure
on Google Kubernetes Engine (GKE). You will then learn how to configure dfTimewolf
to process a Google Cloud disk using Turbinia and then import any created timelines
into Timesketch.


GRR is not currently supported in this Helm chart deployment. We are working to
add GRR support in a future release. In the meantime, you can find a dedicated
guide for deploying GRR on GKE [here](https://github.com/google/osdfir-infrastructure/tree/main/cloud).

## Step 1: Set up Environment Variables

Before creating the Kubernetes (K8s) cluster, define the following environment
variables in your terminal. Replace the placeholders with your actual values:

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

## Step 2: Create a Kubernetes Cluster

Now, create the Kubernetes cluster with the specified configurations:

```bash
gcloud container clusters create $CLUSTER \
    --num-nodes=1 \
    --machine-type "e2-standard-4" \
    --zone $ZONE \
    --workload-pool=$PROJECT_ID.svc.id.goog \
    --addons GcpFilestoreCsiDriver
```

> *Note*: It will take 4-5 minutes to create the cluster.

This command creates a single-node cluster with the necessary resources and addons
for running OSDFIR Infrastructure.

Important Considerations:

* GKE Autopilot is not currently supported because Turbinia workers require
elevated privileges for disk processing.
* You need a machine type of at least `e2-standard-4` (or equivalent with at
least 4 CPUs) when deploying to GKE.
* For clusters with more than one node, you'll need to set up a shared filesystem
like GCP Filestore. In Kubernetes, this translates to using a Persistent Volume
Claim (PVC) with `ReadWriteMany` access.

### Configure kubectl to Access the Cluster

Once the cluster has been created, set up the Google Kubernetes Engine auth
plugin for kubectl:

```bash
gcloud components install gke-gcloud-auth-plugin
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials $CLUSTER --zone $ZONE
```

Now check that you can connect to the cluster:

```bash
kubectl get nodes -o wide
```

## Step 3: Create the Turbinia GCP Service Account

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

## Step 4: Deploy the OSDFIR Infrastructure Helm Chart

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
    --set turbinia.serviceaccount.name=$KSA_NAME
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster while enabling
Turbinia GCP integration.

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

## Step 5: Setup dfTimewolf and CLI configs

OSDFIR Infrastructure utilizes dfTimewolf for orchestrating forensic collection
and processing. dfTimewolf allows you to define "recipes" that specify how data
should be collected, processed by tools like Turbinia, and exported to platforms
like Timesketch.

To install dfTimewolf, you'll need to have Python 3.11 or greater, `git`, and
`pip` installed on your machine. dfTimewolf uses Poetry for simplified dependency
management. Follow these steps to install dfTimewolf:

```bash
git clone https://github.com/log2timeline/dftimewolf.git && cd dftimewolf
pip install poetry
poetry install && poetry shell
```

Retrieve the Timesketch password from your deployment. For example, to grab
it from a release named `my-release`, run:

```bash
kubectl get secret --namespace default my-release-timesketch-secret -o jsonpath="{.data.timesketch-user}" | base64 -d
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

## Step 6: Process a Google Cloud Disk

With OSDFIR Infrastructure deployed and dfTimewolf installed and configured,
you're ready to process a GCP disk.

This example uses the dfTimewolf `gcp_turbinia_ts` recipe, which processes an
existing GCP persistent disk with Turbinia and sends the resulting Plaso timeline
to Timesketch.

First, create a disk to process using a name such as `test-disk`:

```bash
gcloud compute disks create test-disk --zone $ZONE
```

> *Important*: The recipe requires that the disk being processed
is in the same zone Turbinia is deployed to.

You'll need to use `kubectl port-forward` to forward the Turbinia and Timesketch
services locally to your machine. This allows you to access the Turbinia UI and
the Timesketch API from your local machine.

For example, to port-forward from a release named `my-release`, run the following
commands in two seperate terminals:

```bash
kubectl --namespace default port-forward service/my-release-turbinia 8000:8000 
kubectl --namespace default port-forward service/my-release-timesketch 5000:5000  
```

This will allow dfTimewolf to access the Turbinia and Timesketch services locally
from your machine.

Then on a third terminal, run the dfTimewolf recipe:

```bash
dftimewolf gcp_turbinia_ts $PROJECT_ID --disk_names test-disk
```

This command will:

* Process the disk with Turbinia, performing various forensic tasks such as running
Plaso and looking for prevelant anomalies.
* Export any generated Plaso files to Timesketch.

You can monitor the progress of the processing in the Turbinia UI
(`http://localhost:8000`) and in the dfTimewolf output. Once the processing is
complete, log in to Timesketch (`http://localhost:5000`) and verify that a new
timeline has been created. You can then explore the timeline to analyze the
processed artifacts.

Congratulations on completing the setup and processing your first disk! Please
feel free to see the optional workflows below for more examples.

### Additional Workflows

#### Processing Disks from a Different Project

In a real-world scenario, you may need to process a GCP instance or disk belonging
to a different project. To do this, you can use the dfTimewolf recipe
`gcp_turbinia_disk_copy_ts`. This recipe copies the disk from the source project
to your analysis project running OSDFIR Infrastructure, then processes it with
Turbinia and sends the Plaso results to Timesketch.

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

#### Searching for IoCs with Yeti

Yeti enhances your Timesketch investigations by enabling you to search for
Yeti Intelligence (IoCs, threat data, etc.) across Timesketch timelines.

Learn how to use Yeti with Timesketch by following this
[guide](https://yeti-platform.io/guides/indicators-timesketch/investigation/).
