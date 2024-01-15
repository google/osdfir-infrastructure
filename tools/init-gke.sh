#!/bin/bash
# OSDFIR Infrastructure GKE cluster bootstrap helper.
# This script can be used to bootstrap a private GKE cluster in GCP.
# You can optionally route traffic through the GCP Load Balancer enabled through the Helm chart.
# Requirements:
# - have 'gcloud' installed.
# - authenticate against your GCP project with "gcloud auth login"
# - account being used to run script should have an IAM policy of instance.admin and container.admin used to create the necessary resources.
#
# Use --help to show you commands supported.

set -o posix
set -e

# Please review the section below and update to your preference. The default
# values are for a production level environment.
#
# The cluster name, number of minimum and maximum nodes, machine type and disk
# size of the deployed cluster and nodes within it. If you enable --no-node-autoscale
# the `CLUSTER_MIN_NODE_SIZE becomes the `MAX_NODE_SIZE`.
CLUSTER_NAME='osdfir-cluster'
CLUSTER_MIN_NODE_SIZE='1'
CLUSTER_MAX_NODE_SIZE='20'
CLUSTER_MACHINE_TYPE='e2-standard-32'
CLUSTER_DISK_SIZE='200'
# The region and zone where the cluster will run. Note that multi-zone clusters
# are currently not supported.
ZONE='us-central1-f'
REGION='us-central1'
# VPC network to configure the cluster in. This will be automatically created
# if it does not already exist.
VPC_NETWORK='default'
# Control pane IP range for the control pane VPC. Due to the cluster being
# private, this is required for the control pane and cluster to communicate
# privately.
VPC_CONTROL_PANE='172.16.0.0/28' # Set to default
# The Turbinia service account name. If you update this name, please be sure to
# to update the `turbinia.gcp.ServiceAccountName` value in the Helm chart.
SA_NAME="turbinia"

# Help menu
if [[ "$*" == *--help ||  "$*" == *-h ]] ; then
  echo "OSDFIR Infrastructure GKE cluster bootstrap script"
  echo "Options:"
  echo "--no-cluster                   Do not create the cluster"
  echo "--no-nat                       Do not deploy the Cloud NAT (use only if you already have a Cloud NAT deployed as it's required by the private cluster to pull third party dependencies)"
  echo "--no-turbinia-sa               Do not create a Turbinia GCP service account (use only if disabling the Turbinia deployment in OSDFIR Infrastructure)"
  echo "--node-autoscale               Enable Node autoscaling (experimental)"
  exit 1
fi

# Check if gcloud is installed
if [[ -z "$( which gcloud )" ]] ; then
  echo "gcloud CLI not found.  Please follow the instructions at "
  echo "https://cloud.google.com/sdk/docs/install to install the gcloud "
  echo "package first."
  exit 1
fi

# Check configured gcloud project
if [[ -z "$DEVSHELL_PROJECT_ID" ]] ; then
  DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
  ERRMSG="ERROR: Could not get configured project. Please either restart "
  ERRMSG+="Google Cloudshell, or set configured project with "
  ERRMSG+="'gcloud config set project PROJECT' when running outside of Cloudshell."
  if [[ -z "$DEVSHELL_PROJECT_ID" ]] ; then
    echo $ERRMSG
    exit 1
  fi
  echo "Environment variable \$DEVSHELL_PROJECT_ID was not set at start time "
  echo "so attempting to get project config from gcloud config."
  echo -n "Do you want to use $DEVSHELL_PROJECT_ID as the target project? (y / n) > "
  read response
  if [[ $response != "y" && $response != "Y" ]] ; then
    echo $ERRMSG
    exit 1
  fi
fi

# TODO: Do real check to make sure credentials have adequate roles
if [[ $( gcloud -q --project $DEVSHELL_PROJECT_ID auth list --filter="status:ACTIVE" --format="value(account)" | wc -l ) -eq 0 ]] ; then
  echo "No gcloud credentials found.  Use 'gcloud auth login' or 'gcloud auth application-default login' to log in"
  exit 1
fi

# Create the Turbinia service account
if [[ "$*" != *--no-turbinia-sa* ]] ; then
    # Enable IAM services
    gcloud -q --project $DEVSHELL_PROJECT_ID services enable iam.googleapis.com
    SA_MEMBER="serviceAccount:$SA_NAME@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"
    if [[ -z "$(gcloud -q --project $DEVSHELL_PROJECT_ID iam service-accounts list --format='value(name)' --filter=name:/$SA_NAME@)" ]] ; then
      gcloud --project $DEVSHELL_PROJECT_ID iam service-accounts create "${SA_NAME}" --display-name "${SA_NAME}"
      # Grant IAM roles to the service account
      echo "Grant permissions on service account"
      gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=$SA_MEMBER --role='roles/compute.instanceAdmin'
      gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=$SA_MEMBER --role='roles/iam.serviceAccountUser'
    else
      echo "The Turbinia GCP service account $SA_NAME already exists. Skipping creation..."
    fi
else
  echo "--no-turbinia-sa specified. Skipping Turbinia GCP service account creation..."
fi

# Deploy the VPC Network if it does not already exist
networks=$(gcloud -q --project $DEVSHELL_PROJECT_ID compute networks list --filter="name=$VPC_NETWORK" |wc -l)
if [[ "${networks}" -lt "2" ]]; then
  echo "VPC network $VPC_NETWORK not found. Creating VPC network $VPC_NETWORK..."
  gcloud compute networks create $VPC_NETWORK --subnet-mode=auto --project $DEVSHELL_PROJECT_ID
else
  echo "VPC network $VPC_NETWORK found. Skipping VPC network creation...."
fi

# Allow Egress connectivity through GCP Cloud Router & NAT
if [[ "$*" != *--no-nat* ]] ; then
    # Deploy the GCP Cloud router if it does not already exist
    routers=$(gcloud -q --project $DEVSHELL_PROJECT_ID compute routers list --regions="$REGION" --filter="name=$VPC_NETWORK" | wc -l)
    if [[ "${routers}" -lt "2" ]]; then
      echo "GCP router $VPC_NETWORK not found in $REGION. Creating GCP router $VPC_NETWORK for $REGION ..."
      gcloud compute routers create $VPC_NETWORK --network $VPC_NETWORK --region $REGION --project $DEVSHELL_PROJECT_ID
    else
      echo "GCP router $VPC_NETWORK found in $REGION. Skipping GCP router creation..."
    fi
    # Deploy the GCP NAT if it does not already exist
    nat=$(gcloud -q --project $DEVSHELL_PROJECT_ID compute routers nats list --router=$VPC_NETWORK --router-region $REGION | wc -l)
    if [[ "${routers}" -lt "2" ]]; then
      echo "Cloud NAT $VPC_NETWORK not found in $REGION. Creating Cloud NAT $VPC_NETWORK for $REGION ..."
      gcloud compute routers nats create $VPC_NETWORK --project $DEVSHELL_PROJECT_ID --router-region $REGION --router $VPC_NETWORK --nat-all-subnet-ip-ranges --auto-allocate-nat-external-ips
    else
      echo "Cloud NAT $VPC_NETWORK found in $REGION. Skipping Cloud NAT creation..."
    fi
else
  echo "--no-nat specified. Skipping Cloud Router and NAT creation..."
fi

# Create GKE cluster and authenticate to it
if [[ "$*" != *--no-cluster* ]] ; then
  echo "Enabling Container API"
  gcloud -q --project $DEVSHELL_PROJECT_ID services enable container.googleapis.com
  echo "Enabling Compute API"
  gcloud -q --project $DEVSHELL_PROJECT_ID services enable compute.googleapis.com
  echo "Enabling Filestore API"
  gcloud -q --project $DEVSHELL_PROJECT_ID services enable file.googleapis.com
  if [[ "$*" != *--node-autoscale* ]] ; then
    echo "Creating cluster $CLUSTER_NAME with a node size of $CLUSTER_MIN_NODE_SIZE. Each node will be configured with a machine type $CLUSTER_MACHINE_TYPE and disk size of $CLUSTER_DISK_SIZE"
    gcloud -q --project $DEVSHELL_PROJECT_ID container clusters create $CLUSTER_NAME --machine-type $CLUSTER_MACHINE_TYPE --disk-size $CLUSTER_DISK_SIZE --num-nodes $CLUSTER_MIN_NODE_SIZE --master-ipv4-cidr $VPC_CONTROL_PANE --network $VPC_NETWORK --zone $ZONE --shielded-secure-boot --shielded-integrity-monitoring --no-enable-master-authorized-networks --enable-private-nodes --enable-ip-alias --scopes "https://www.googleapis.com/auth/cloud-platform" --labels "osdfir-infra=true" --workload-pool=$DEVSHELL_PROJECT_ID.svc.id.goog --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcpFilestoreCsiDriver
  else
    echo "--node-autoscale specified. Creating cluster $CLUSTER_NAME with a minimum node size of $CLUSTER_MIN_NODE_SIZE to scale up to a maximum node size of $CLUSTER_MAX_NODE_SIZE. Each node will be configured with a machine type $CLUSTER_MACHINE_TYPE and disk size of $CLUSTER_DISK_SIZE"
    gcloud -q --project $DEVSHELL_PROJECT_ID container clusters create $CLUSTER_NAME --machine-type $CLUSTER_MACHINE_TYPE --disk-size $CLUSTER_DISK_SIZE --num-nodes $CLUSTER_MIN_NODE_SIZE --master-ipv4-cidr $VPC_CONTROL_PANE --network $VPC_NETWORK --zone $ZONE --shielded-secure-boot --shielded-integrity-monitoring --no-enable-master-authorized-networks --enable-private-nodes --enable-ip-alias --scopes "https://www.googleapis.com/auth/cloud-platform" --labels "osdfir-infra=true" --workload-pool=$DEVSHELL_PROJECT_ID.svc.id.goog --enable-autoscaling --min-nodes=$CLUSTER_MIN_NODE_SIZE --max-nodes=$CLUSTER_MAX_NODE_SIZE --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcpFilestoreCsiDriver
  fi
  # Add Workload Identity bind
  gcloud iam service-accounts add-iam-policy-binding $SA_NAME@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:$DEVSHELL_PROJECT_ID.svc.id.goog[default/$SA_NAME]" --project $DEVSHELL_PROJECT_ID
else
  echo "--no-cluster specified. Skipping GKE cluster creation..."
fi
