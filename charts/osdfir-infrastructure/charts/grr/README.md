# GRR Helm Chart

[GRR](https://github.com/google/grr) Rapid Response is an incident response framework focused on remote live forensics.

[Overview of GRR](https://grr-doc.readthedocs.io/)

Before we get started make sure you clone the repo onto your machine.

```console
git clone https://github.com/google/osdfir-infrastructure.git
cd osdfir-infrastructure
export REPO=$(pwd)
```

## Build clients for an external Fleetspeak address

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

### Validate with KIND

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
