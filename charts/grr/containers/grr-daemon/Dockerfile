# Copyright 2024 Google LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM ghcr.io/google/fleetspeak:cl-601420666 AS fleetspeak
FROM ghcr.io/google/grr:latest AS grr
COPY config /config
COPY grr-client-config.yaml /config/grr.client.yaml

WORKDIR /

# Create a dummy Client.executable_signing_public_key if none is provided in the config file
# Reasoning: This ensures that the repackaging runs through (see below)
RUN if [ $(grep -ic "Client.executable_signing_public_key:" /config/grr.client.yaml) -eq 0 ]; \
    then \
      grr_config_updater generate_keys; \
      grep -oz "Client.executable_signing_public_key: '-----BEGIN PUBLIC KEY-----.*-----END PUBLIC KEY-----" \
        /usr/src/grr/grr/core/install_data/etc/server.local.yaml | tr '\0' "'" >> /config/grr.client.yaml; \
    fi

RUN grr_client_build repack_multiple \
            --templates /client_templates/ubuntu-installers/grr_*_amd64.deb.zip \
            --repack_configs /config/grr.client.yaml \
            --output_dir /

FROM ubuntu:22.04
WORKDIR /

COPY config /config
COPY --from=grr /config/grr.client.yaml /config/grr.client.yaml

COPY --from=fleetspeak /fleetspeak/bin/client /usr/local/bin/fleetspeak-client
COPY --from=grr /grr.client/grr_*_amd64.deb .
RUN dpkg -i grr_*_amd64.deb && rm grr_*_amd64.deb
ENTRYPOINT ["fleetspeak-client", "-config" , "/config/config.textproto", "-alsologtostderr"]
