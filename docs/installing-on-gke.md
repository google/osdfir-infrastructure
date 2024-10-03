# Deploying OSDFIR Infrastructure on Google Kubernetes Engine (GKE)

In this tutorial you will learn how to deploy and configure OSDFIR Infrastructure
on Google Kubernetes Engine (GKE). You will learn how to configure.

## 1. Create a Kubernetes Cluster

To get started, let's create a Kubernetes cluster in Google Cloud. You will need
to pick a name for your cluster and a zone to deploy it to. Here, we will go
with "osdfir-test" and the zone "us-central1-f". Let us save it in
environment variables:

```bash
export PROJECT=your-gcp-project
export CLUSTER="osdfir-test"
export ZONE="us-central1-f"
```

Now, create the cluster using the following command:

```bash
gcloud container clusters create $CLUSTER \
--num-nodes=1 \
--machine-type "e2-standard-4" \
--zone $ZONE \
--workload-pool=$PROJECT.svc.id.goog \
--addons GcpFilestoreCsiDriver
```

Set up the Google Kubernetes Engine auth plugin for kubectl:

```bash
gcloud components install gke-gcloud-auth-plugin
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials $CLUSTER
```

Now check that you can connect to the cluster:

```console
kubectl get nodes -o wide
```

> ⏲ It will take 4-5 minutes to create the cluster.

## 2. Create the Turbinia GCP Service Account

```bash
export PROJECT_ID=your-project  # Your Google Cloud project ID.
export PROJECT_NUMBER=your-number # Your Google Cloud project number.
export NAMESPACE=default # Your K8s namespace.
export KSA_NAME=turbinia # Your Turbinia K8s service account name.
```

```bash
gcloud projects add-iam-policy-binding projects/$PROJECT_ID \
    --role=roles/compute.instanceAdmin \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/$KSA_NAME
```

```bash
$ gcloud projects add-iam-policy-binding projects/$PROJECT_ID \
    --role=roles/compute.serviceAccountUser \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/$KSA_NAME
```


## 3. Deploy OSDFIR Infrastructure

```console
helm repo add osdfir-charts https://google.github.io/osdfir-infrastructure
```

```bash
helm install my-release osdfir-charts/osdfir-infrastructure \
    --set turbinia.gcp.enabled=true \
    --set turbinia.gcp.projectID=<GCP_PROJECT_ID> \
    --set turbinia.gcp.projectRegion=<GKE_CLUSTER_REGION> \
    --set turbinia.gcp.projectZone=<GKE_ClUSTER_ZONE>
```

## 4. Setup dfTimewolf and CLI configs

```console
git clone https://github.com/log2timeline/dftimewolf.git && cd dftimewolf
pip install poetry
poetry install
```

## 5. Process a GCP disk

```bash
gcloud compute disks create test-disk
```

```bash
dftimewolf gcp_turbinia_ts $PROJECT_ID --disk_names test-disk
```
