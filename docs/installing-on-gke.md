# Deploying OSDFIR Infrastructure on Google Kubernetes Engine (GKE)

In this tutorial you will learn how to deploy and configure OSDFIR Infrastructure
on Google Kubernetes Engine (GKE). You will then learn how to process a Google
Cloud disk using OpenRelik and then import any created timelines into Timesketch.

## Prerequisites

💻 **Google Cloud Account**: You'll need a Google Cloud Platform (GCP) account.
To create an account, you'll need to provide a credit card or bank account for
verification. Visit the [Get started with Google Cloud page](https://cloud.google.com/docs/get-started)
and follow the instructions.

> *Note*: 💵 If you have never used Google Cloud before, you may be eligible for
the [Google Cloud Free Program](https://cloud.google.com/free/docs/gcp-free-tier/#free-trial),
which gives you a 90-day trial period that includes $300 in free Cloud Billing
credits to explore and evaluate Google Cloud.

💻 **Software**: You will also need to install the following software on your laptop:

1. [gcloud](https://cloud.google.com/sdk/docs/install): A set of tools to create
and manage Google Cloud resources.
2. [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): The Kubernetes
command-line tool that allows you to configure Kubernetes clusters.
3. [Helm](https://helm.sh/): The package manager for Kubernetes, which we will
use to install OSDFIR Infrastructure with.

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
                       file.googleapis.com \
                       pubsub.googleapis.com \
                       storage.googleapis.com
```

## Step 2: Set up Environment Variables

Before creating the Kubernetes (K8s) cluster, define the following environment
variables in your terminal. You do not have to create any of these resources
beforehand, as this guide will walk you through the process.

Replace the placeholders with your actual values:

```bash
export PROJECT_ID="your-gcp-project"  # Your Google Cloud project ID
export PROJECT_NUMBER="your-gcp-number"  # Your Google Cloud project number
export CLUSTER="osdfir-autopilot-cluster"  # The name you choose for your K8s cluster
export REGION="your-gcp-region" # GCP Region of your K8s cluster
export ZONE="your-gcp-zone" # GCP Zone of the test disk you will create and process
export NAMESPACE="default"  # Your K8s namespace (can be left as 'default')
export GCS_BUCKET="openrelik-my-unique-id-12345" # Your GCS bucket name (must be globally unique)
export PUBSUB_TOPIC="openrelik-pubsub" # Your Google Cloud PubSub Topic
export PUBSUB_SUBSCRIPTION="openrelik-sub" # Your Google Cloud PubSub Subscription
export OPENRELIK_FOLDER_ID=1 # Your OpenRelik Folder ID to store images into (defaults to 1 for new installs)
```

> *Note*: You can find the GCP project number by running `gcloud projects describe $PROJECT_ID`

## Step 3: Create the GKE Autopilot Cluster

Now, create the GKE cluster with the following command:

```bash
gcloud container clusters create-auto $CLUSTER \
  --release-channel=rapid \
  --cluster-version=1.34.1-gke.1829001 \
  --region $REGION
```

Important Considerations:

* A shared filesystem like GCP Filestore is required. This involves configuring
a Persistent Volume Claim (PVC) with `ReadWriteMany` access in Kubernetes, which
is configured in`Step 8` using the persistence flags.

### Configure kubectl to Access the Cluster

Once the cluster has been created, set up the Google Kubernetes Engine auth
plugin for kubectl:

```bash
sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials $CLUSTER --region $REGION
```

Now check that you can connect to the cluster:

```bash
kubectl get nodes -o wide
```

## Step 4: Configuring OpenRelik

To configure OpenRelik in GCP, follow these steps to create the required GCP
resources.

### Create the GCS Bucket

First, we need to create a Google Cloud Storage (GCS) bucket. This bucket will
serve as the ingestion point for OpenRelik. It's where you will upload the disk
images you want to process.

The command below uses the `$GCS_BUCKET` variable you defined in Step 2. We also
add the `--uniform-bucket-level-access` flag, which is the recommended setting
for simplifying permissions management on the bucket.

```bash
gcloud storage buckets create gs://$GCS_BUCKET --uniform-bucket-level-access
```

### Create the GCS Bucket Notification

Next, we need a way for OpenRelik to be notified automatically when a new disk is uploaded. This command creates a Pub/Sub notification on the bucket.

Any time a new object (like a disk image) is added to this bucket, GCS will automatically send a message to the Pub/Sub topic you defined with your
`$PUBSUB_TOPIC` variable. This event-driven workflow is what triggers the
OpenRelik gcp importer to pull down the artifact from GCS.

```bash
gcloud storage buckets notifications create gs://$GCS_BUCKET --topic=$PUBSUB_TOPIC
```

### Create the PubSub Subscription

In the last step, we told the bucket to send messages to a topic. Now, we need
to create the "mailbox" or subscription that OpenRelik will listen to.

This command creates a Pub/Sub subscription (using your
`$PUBSUB_SUBSCRIPTION` variable) and attaches it to the topic from `Step 5`. The OpenRelik gcp importer service, once deployed in your GKE cluster, will listen
to this specific subscription to receive the "new artifact" messages in GCS
and begin its work to pull down the file into the OpenRelik shared file storage.

```bash
gcloud pubsub subscriptions create $PUBSUB_SUBSCRIPTION --topic=projects/$PROJECT_ID/topics/$PUBSUB_TOPIC
```

### Create the GCP Service Account

To pull artifacts from Google Cloud Storage with OpenRelik, you need a dedicated
 GCP service account with the necessary permissions to subscribe to the PubSub
 topic and read GCS bucket objects.

```bash
# Grant the PubSub subscriber role for subscribing to GCS bucket notifications
gcloud projects add-iam-policy-binding projects/$PROJECT_ID \
    --role=roles/pubsub.subscriber \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/openrelik
```

```bash
# Grant the Storage Object User role for reading and downloading artifacts from GCS
gcloud projects add-iam-policy-binding projects/$PROJECT_ID \
    --role=roles/storage.objectUser \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/openrelik
```

```bash
# Grant the Service Account user role to allow the account to act as a service account
gcloud projects add-iam-policy-binding projects/$PROJECT_ID \
    --role=roles/iam.serviceAccountUser \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/openrelik
```

These commands grant the following roles to the service account:

* PubSub Subscriber: Allows OpenRelik to subscribe to PubSub messages notifying of a new upload to the configured GCS bucket.
* Storage Object User: Allows OpenRelik to retrieve disk artifacts from the GCS
bucket.
* Service Account User: Allows the OpenRelik service account to act as this newly
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
helm install my-release osdfir-charts/osdfir-infrastructure --version 2.5.8 \
    --set openrelik.gcp.enabled=true \
    --set openrelik.gcp.projectID=$PROJECT_ID \
    --set openrelik.gcp.subscriptionID=$PUBSUB_SUBSCRIPTION \
    --set openrelik.persistence.storageClass="standard-rwx" \
    --set openrelik.persistence.accessModes={"ReadWriteMany"} \
    --set openrelik.persistence.size=10Gi \
    --set openrelik.config.initWorkerNbd=true \
    --set timesketch.persistence.storageClass="standard-rwx" \
    --set timesketch.persistence.accessModes={"ReadWriteMany"} \
    --set timesketch.persistence.size=10Gi
```

The command deploys OSDFIR Infrastructure on the Kubernetes cluster while enabling
OpenRelik GCP integration and increasing the OSDFIR Infrastructure disk size to
10 Gigabytes to allow for enough space for the processed forensic output.

Verify the deployment:

```bash
kubectl get pods
```

You should see pods for Timesketch, OpenRelik, GRR, and Yeti in a Running state.
It may take a few minutes for all the Pods to show a `Running` state.

## Step 6: Expose Fleetspeak/GRR on L4 LoadBalancer

The default way that the Fleetspeak frontend for GRR is exposed is through a ```NodePort``` (port 30443) on the node IP.

```node``` exposes the Fleetspeak frontend as a ```NodePort``` service.

* Find the IP for one of your cluster nodes and install the chart as following:

> **Note**: Run kubectl get nodes -o wide for a list of IPs to Nodes.

```bash
helm upgrade my-release osdfir-charts/osdfir-infrastructure \
  --set grr.fleetspeak.frontend.expose="node" \
  --set grr.fleetspeak.frontend.address="$NODE_IP" \
  --reuse-values
```

* Once the Fleetspeak frontend ```pod``` is running you can install the GRR agent
  binaries on your clients in the same network as the node is running in.
* This is the simplest mode and only suitable for demo purposes.
* For a production grade deployment use either an interal or an external L4 LoadBalancer as described below.

### Use an Internal L4 LoadBalancer

```internal``` exposes the Fleetspeak frontend as an [internal Google Cloud L4 LoadBalancer](https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balancing)

* This allows you to keep your Fleetspeak/GRR cluster on your private VPC.
* You will have to reserve a static internal IP address in your Google Cloud Project first.

```bash
gcloud compute addresses create fleetspeak-frontend-internal \
  --region=$REGION --subnet=default

# Find the IP address that you have been allocated.
gcloud compute addresses describe fleetspeak-frontend-internal --region=$REGION
```

* Choose the values for the ```REGION``` and ```SUBNETWORK```
 so they match the location where you run your GKE cluster.

```bash
helm upgrade my-release osdfir-charts/osdfir-infrastructure \
  --set grr.fleetspeak.frontend.expose="internal" \
  --set grr.fleetspeak.frontend.address="$IP_ADDRESS" \
  --reuse-values
```

* Once the Fleetspeak frontend ```pod``` is running you can install the GRR agent
 binaries on your clients in the same Google Cloud VPC as the node is running in.

### Use an External L4 LoadBalancer

```external``` exposes the Fleetspeak frontend as an [external Google Cloud L4 LoadBalancer](https://cloud.google.com/kubernetes-engine/docs/how-to/backend-service-based-external-load-balancer)

* This allows you to run your Fleetspeak/GRR cluster so it is available from
 anywhere on the Internet. Use this with caution as it exposes your cluster externally!
* You will have to reserve a static external IP address in your Google Cloud Project first.

```bash
gcloud compute addresses create fleetspeak-frontend-external --region=$REGION
     
# Find the IP address that you have been allocated.
gcloud compute addresses describe fleetspeak-frontend-external --region=$REGION
```

* Choose the value for the ```REGION``` so it matches the location where
 you run your GKE cluster.

```bash
helm upgrade my-release osdfir-charts/osdfir-infrastructure \
  --set grr.fleetspeak.frontend.expose="external" \
  --set grr.fleetspeak.frontend.address="$IP_ADDRESS" \
  --reuse-values
```

* Once the Fleetspeak frontend ```pod``` is running you can install the GRR agent
 binaries on your clients anywhere where they have access to the Internet.

## Step 7: Process a Google Cloud Disk

With OSDFIR Infrastructure deployed, you're ready to process a GCP disk.

Before you begin, you will have to create a folder within the OpenRelik UI
to store your disk in and make a note of the folder id.

To connect to OpenRelik, you'll then need to use `kubectl port-forward` to
forward the OpenRelik services locally to your machine. This allows you
to access the OpenRelik UI and the OpenRelik API from your local machine.

For example, to port-forward from a release named `my-release`, open up two new
tabs or terminals, then run the following commands in each terminal.

For the OpenRelik UI:

```bash
kubectl --namespace default port-forward service/my-release-openrelik 8711:8711
```

For the OpenRelik API:

```bash
kubectl --namespace default port-forward service/my-release-openrelik-api 8710:8710  
```

Log into the OpenRelik UI using the openrelik credentials. By default, the user
will be `openrelik`. To find the password, for example from a release named `my-release`:

```bash
kubectl get secret --namespace default my-release-openrelik-secret -o jsonpath="{.data.openrelik-user}" | base64 -d; echo ""
```

Once you are in the OpenRelik UI, create a folder to store your GCP image in and
make a note of the folder id. Typically for fresh installs, this would be `1`.

Now you can create a disk to process. For example, to create a disk with one of
the base debian images, run:

```bash
gcloud compute disks create test-debian-disk \
  --image=debian-12-bookworm-arm64-v20241009 \
  --image-project debian-cloud \
  --size 10GB \
  --zone $ZONE 
```

Important Considerations:

* If you encounter an error stating that the image cannot be found, you can list
the available Debian images by running:

    ```bash
    gcloud compute images list --filter debian-cloud
    ```

    Then, choose an available image name from the list and update the `--image`
    flag in the disk creation command accordingly.


Now create an image of the disk created in the previous step:

```bash
gcloud compute images create test-debian-image --source-disk test-debian-disk --source-disk-zone $ZONE
```

Finally, export the image into the OpenRelik GCS bucket, please make note of the
`OPENRELIK_FOLDER_ID` using the correct folder id:

```bash
gcloud compute images export --destination-uri=gs://$GCS_BUCKET/$OPENRELIK_FOLDER_ID/test-debian-image.raw --project=$PROJECT_ID --image=test-debian-image
```

Once the `gcloud compute images export` completes, log back into the OpenRelik
UI, navigate to the folder you created and you should find the image
`test-debian-image.raw` within the folder. From here, get familiar with the
OpenRelik UI, then when you are ready, create a new OpenRelik Workflow. Select
the following Jobs: `Log2timeline Plaso` and `Timesketch Exporter`. This will
process the disk with the OpenRelik Plaso worker and then export the generated
Plaso file into Timesketch.

You can monitor the progress of the processing in the OpenRelik UI
(`http://localhost:8711`) . Once the processing is complete, log in to
Timesketch (`http://localhost:5000`) and verify that a new timeline has been
created. You can then explore the timeline to analyze the processed artifacts.
When using Google Cloud Shell, you can utilize the
[web preview feature](https://cloud.google.com/shell/docs/using-web-preview#preview_the_application)
to view the UIs.

Congratulations on completing the setup and processing your first disk! Explore
the optional workflows for more examples.

### Additional Workflows

### Setup dfTimewolf and CLI configs

OSDFIR Infrastructure utilizes dfTimewolf for orchestrating forensic collection
and processing. dfTimewolf allows you to define "recipes" that specify how data
should be collected, processed by tools like OpenRelik, and exported to
platforms like Timesketch.

To install dfTimewolf, you'll need to have Python 3.12 or greater, `git`, and
`pip` installed on your machine. dfTimewolf uses poetry for simplified
dependency management.

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
    "openrelik_api": "http://127.0.0.1:8710",
    "openrelik_ui": "http://127.0.0.1:8711"
}
EOF
```

Now you have dfTimewolf installed and configured to interact with your OSDFIR
Infrastructure deployment.

#### Using Timesketch

To learn more about using Timesketch in detail check out the [user guide](https://timesketch.org/guides/user/sketch-overview/).

#### Searching for IoCs with Yeti

Yeti enhances your Timesketch investigations by enabling you to search for
Yeti Intelligence (IoCs, threat data, etc.) across Timesketch timelines.

Learn how to use Yeti with Timesketch by following this
[guide](https://yeti-platform.io/guides/indicators-timesketch/investigation/).
