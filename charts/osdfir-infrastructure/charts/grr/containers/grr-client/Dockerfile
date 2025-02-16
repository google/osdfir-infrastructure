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
FROM ghcr.io/google/grr:latest AS grr
COPY config /config
COPY grr-client-config.yaml /config/grr.client.yaml

RUN mkdir /client_installers && \
    grr_config_updater repack_clients \
      --secondary_configs /config/grr.yaml \
      --noupload

FROM ubuntu:22.04
WORKDIR /

COPY --from=grr /config/communicator.txt /etc/fleetspeak-client/communicator.txt
COPY --from=grr /config/config.textproto /etc/fleetspeak-client/client.config
COPY --from=grr /config/grr.client.yaml /etc/fleetspeak-client/grr.client.yaml

COPY --from=grr /client_installers/grr_*_amd64.deb .
RUN dpkg -i grr_*_amd64.deb && rm grr_*_amd64.deb
ENTRYPOINT ["fleetspeak-client", "-config" , "/etc/fleetspeak-client/client.config", "-alsologtostderr"]
