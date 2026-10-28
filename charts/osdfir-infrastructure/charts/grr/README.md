# GRR Helm Chart

[GRR](https://github.com/google/grr) Rapid Response is an incident response framework focused on remote live forensics.

[Overview of GRR](https://grr-doc.readthedocs.io/)

Before we get started make sure you clone the repo onto your machine.

```console
git clone https://github.com/google/osdfir-infrastructure.git
cd osdfir-infrastructure
export REPO=$(pwd)
```

## 1. Quick Start

A convenient way to get started is to run GRR on a `minikube` cluster.

The GRR chart repacks the client templates for Darwin, Linux and Windows when it is installed.

The resulting `.pkg`, `.deb`, `.rpm`, and `.msi` installers are uploaded to GRR and are available in
the Admin UI under **Binaries → executables → installers**.

After the installation finishes you can download and run the respective installer for your client OS.

Make sure that your client machine has network connectivity to the `minikube ip` (see below) so it can reach the GRR server.

```console
minikube start
export REPO=$(pwd)
export NODE_IP=$(minikube ip)

# Install the GRR chart
helm install grr \
  "$REPO/charts/osdfir-infrastructure/charts/grr" \
  --set clientBuilder.address="$NODE_IP"
  --set-string clientBuilder.port=30443 \
  --set grr.fleetspeak.frontend.expose="node" \
  --set grr.fleetspeak.frontend.address="$NODE_IP"

# Wait for all pods to be in the 'running' state then port forward the GRR Admin UI.
kubectl port-forward service/grr-grr-admin 8000:8000
```

You can now point your browser to [http://localhost:8000](http://localhost:8000) to access the GRR Admin UI.


Alternatively, instead of having to run an external GRR client you can run a GRR client as a Kubernetes Daemonset in the GRR cluster.

Note that while this is convenient for demos it is not otherwise recommended.

```console
minikube start --insecure-registry="192.168.49.0/24" --addons=registry
export REPO=$(pwd)
export NODE_IP=$(minikube ip)
export CLIENT_IMAGE=grr-client:v0.1

# Install the GRR chart
helm install grr \
  "$REPO/charts/osdfir-infrastructure/charts/grr" \
  --set clientBuilder.address="$NODE_IP" \
  --set-string clientBuilder.port=30443 \
  --set grr.fleetspeak.frontend.expose="node"
  --set grr.fleetspeak.frontend.address="$NODE_IP"  \
  --set grr.daemon.image="localhost:5000/$CLIENT_IMAGE" \
  --set grr.clientBuilder.kanikoInsecure=true \
  --set clientBuilder.imageOnRegistry="$NODE_IP:5000/$CLIENT_IMAGE"

# Wait for all pods to be in the 'running' state
# Label the minikube node with 'grrclient=installed' to get the GRR client installed in a daemonset. 
kubectl get nodes
kubectl label nodes --overwrite minikube  grrclient=installed

# Port forward the GRR Admin UI
kubectl port-forward service/grr-grr-admin 8000:8000
```

You can now point your browser to [http://localhost:8000](http://localhost:8000) to access the GRR Admin UI and run some test Flows.

## 2. Build clients for an external Fleetspeak address

The chart repacks the GRR client templates when it is installed. The resulting
`.deb`, `.rpm`, and `.msi` installers are uploaded to GRR and are available in
the Admin UI under **Binaries → executables → installers**.

By default, the builder embeds the first Kubernetes node internal IP and
`fleetspeak.frontend.listenPort` in those installers. For a client outside the
cluster, set an address and port that the client can reach:

```console
helm upgrade --install grr \
  "$REPO/charts/osdfir-infrastructure/charts/grr" \
  --set clientBuilder.address=grr.example.com \
  --set-string clientBuilder.port=30443
```

When installing the unified OSDFIR Infrastructure chart, prefix these settings
with the subchart name:

```console
helm upgrade --install osdfir "$REPO/charts/osdfir-infrastructure" \
  --set grr.clientBuilder.address=grr.example.com \
  --set-string grr.clientBuilder.port=30443
```

The default self-signed Fleetspeak certificate includes the configured client
address. Changing the client address or port rotates that certificate, restarts
the Fleetspeak frontend, and creates a client-builder Job with a new name. This
allows `helm upgrade` to repack the installers without attempting to patch the
immutable pod template of the previous Job.

The builder retrieves the certificate from the external endpoint by default.
If that endpoint is not reachable from the cluster, or TLS terminates at a
proxy, provide the certificate that clients should trust:

```console
helm upgrade --install grr \
  "$REPO/charts/osdfir-infrastructure/charts/grr" \
  --set clientBuilder.address=grr.example.com \
  --set-string clientBuilder.port=443 \
  --set-file clientBuilder.trustedCert=./fleetspeak-frontend.crt
```

To configure the Fleetspeak frontend with an existing certificate instead of a
self-signed one, provide both the certificate and private key:

```console
helm upgrade --install grr \
  "$REPO/charts/osdfir-infrastructure/charts/grr" \
  --set fleetspeak.generateCert=false \
  --set-file fleetspeak.frontend.cert=./fleetspeak-frontend.crt \
  --set-file fleetspeak.frontend.key=./fleetspeak-frontend.key \
  --set-file clientBuilder.trustedCert=./fleetspeak-frontend.crt
```

### 2.1. Validate with KIND

Expose the default Fleetspeak NodePort when creating a disposable KIND cluster:

```yaml
# kind.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30443
        hostPort: 30443
        protocol: TCP
```

```console
kind create cluster --name grr-client-test --config kind.yaml
```

Choose an address that is reachable both from the target client and, when
certificate discovery is used, from the cluster. Install the chart with that
address:

```console
export FLEETSPEAK_ADDRESS=<externally-reachable-address>

helm upgrade --install grr \
  "$REPO/charts/osdfir-infrastructure/charts/grr" \
  --set clientBuilder.address="$FLEETSPEAK_ADDRESS" \
  --set-string clientBuilder.port=30443 \
  --wait
```

Verify TLS reachability before waiting for the client build:

```console
openssl s_client \
  -connect "$FLEETSPEAK_ADDRESS:30443" \
  -servername "$FLEETSPEAK_ADDRESS" </dev/null
```

Wait for the current builder Job and inspect its logs:

```console
kubectl wait --for=condition=complete \
  job -l app.kubernetes.io/component=client-builder \
  --timeout=20m

kubectl logs \
  job/$(kubectl get job \
    -l app.kubernetes.io/component=client-builder \
    -o jsonpath='{.items[0].metadata.name}')
```

Open the GRR Admin UI and download an installer:

```console
kubectl port-forward service/grr-grr-admin 8000:8000
```

After installing it on a test machine, confirm the new client appears in GRR
and that its Fleetspeak connection targets the configured external address and
port.

## 3. Run GRR with Fleetspeak-on-Spanner

[GRR](https://github.com/google/grr) and [Fleetspeak](https://github.com/google/fleetspeak) are both backed by a datastore for their operational data.

The default datastore implementation for both GRR and Fleetspeak is MySQL.

MySQL is a reasonable choice for GRR installations with less than 10,000 clients.

If your fleet is surpassing 10,000 GRR clients we recommend exploring the option of running Fleetspeak on [Google Cloud Spanner](https://cloud.google.com/spanner).

You can find more background information about the configuration in this [blog post](https://osdfir.blogspot.com/2025/06/unlocking-fleetspeak-large-scale-and.html).

If you would like to test the Fleetspeak-on-Spanner setup before adopting the approach you can do so with `minikube` and the [Spanner emulator](https://docs.cloud.google.com/spanner/docs/emulator).

Follow the instructions below to set up GRR with Fleetspeak-on-Spanner on `minikube`.

```console
minikube start --insecure-registry="192.168.49.0/24" --addons=registry
export REPO=$(pwd)
export NODE_IP=$(minikube ip)
export CLIENT_IMAGE=grr-client:v0.1

helm install grr \
  "$REPO/charts/osdfir-infrastructure/charts/grr" \
  --set clientBuilder.address="$NODE_IP" \
  --set-string clientBuilder.port=30443 \
  --set grr.fleetspeak.frontend.expose="node" \
  --set grr.fleetspeak.frontend.address="$NODE_IP"  \
  --set grr.daemon.image="localhost:5000/$CLIENT_IMAGE" \
  --set grr.clientBuilder.kanikoInsecure=true \
  --set clientBuilder.imageOnRegistry="$NODE_IP:5000/$CLIENT_IMAGE" \
  --set fleetspeak.spanner.emulateSpanner=true  \
  --set fleetspeak.spanner.useSpanner=true

# Wait for all pods to be in the 'running' state and the client builder job to complete
kubectl get job
# The output should look similar to the below:
# NAME                     STATUS     COMPLETIONS   DURATION   AGE
# grr-grr-client-builder   Complete   1/1           9m55s      11m
kubectl wait --for=condition=complete job --all --timeout=900s
# The output should look similar to the below:
# job.batch/grr-grr-client-builder condition met

# Label the minikube node with 'grrclient=installed' to get the GRR client installed in a daemonset. 
kubectl get nodes
kubectl label nodes --overwrite minikube  grrclient=installed

# Port forward the GRR Admin UI
kubectl port-forward service/grr-grr-admin 8000:8000
```

You can now point your browser to [http://localhost:8000](http://localhost:8000) to access the GRR Admin UI and run some test Flows.
