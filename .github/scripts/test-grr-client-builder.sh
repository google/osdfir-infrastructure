#!/usr/bin/env bash
set -euo pipefail

chart="charts/osdfir-infrastructure/charts/grr"
helm="${HELM:-helm}"

default_render="$("$helm" template test "$chart")"
grep -Fq -- "--build-arg=FLEETSPEAK_FRONTEND=10.0.0.2" <<<"$default_render"
grep -Fq -- "--build-arg=FLEETSPEAK_FRONTEND_PORT=30443" <<<"$default_render"
grep -Fq "Waiting for the external Fleetspeak endpoint to serve the current certificate" <<<"$default_render"

external_render="$("$helm" template test "$chart" \
  --set clientBuilder.address=external.example.test \
  --set-string clientBuilder.port=443 \
  --set-string clientBuilder.trustedCert=test-cert)"
grep -Fq -- "--build-arg=FLEETSPEAK_FRONTEND=external.example.test" <<<"$external_render"
grep -Fq -- "--build-arg=FLEETSPEAK_FRONTEND_PORT=443" <<<"$external_render"
grep -Fq -- "--build-arg=FLEETSPEAK_TRUSTED_CERT_B64=dGVzdC1jZXJ0" <<<"$external_render"
if grep -Fq "Waiting for the external Fleetspeak endpoint to serve the current certificate" <<<"$external_render"; then
  exit 1
fi

certificate="$(
  awk '/^  tls.crt: / { print $2; exit }' <<<"$external_render" |
    openssl base64 -d -A
)"
grep -Fq "DNS:external.example.test" <<<"$(openssl x509 -noout -text <<<"$certificate")"

job_name="$(
  awk '/^  name: test-grr-client-builder-/ { print $2; exit }' <<<"$external_render"
)"
changed_render="$("$helm" template test "$chart" \
  --set clientBuilder.address=external.example.test \
  --set-string clientBuilder.port=8443 \
  --set-string clientBuilder.trustedCert=test-cert)"
changed_job_name="$(
  awk '/^  name: test-grr-client-builder-/ { print $2; exit }' <<<"$changed_render"
)"
if [[ "$job_name" == "$changed_job_name" ]]; then
  echo "Error: Job name did not change when clientBuilder inputs were modified!" >&2
  exit 1
fi
echo "Job name updated successfully on input change."

grep -Fq "ClientBuilder.fleetspeak_client_config: /config/config.windows.textproto" <<<"$external_render"
grep -Fq 'configuration_key: "HKEY_LOCAL_MACHINE\\SOFTWARE\\FleetspeakClient"' \
  "$chart/containers/grr-client/config/config.windows.textproto.tmpl"

provided_cert_render="$("$helm" template test "$chart" \
  --set fleetspeak.generateCert=false \
  --set-string fleetspeak.frontend.cert=test-cert \
  --set-string fleetspeak.frontend.key=test-key)"
grep -Fq "tls.crt: dGVzdC1jZXJ0" <<<"$provided_cert_render"
grep -Fq "tls.key: dGVzdC1rZXk=" <<<"$provided_cert_render"
