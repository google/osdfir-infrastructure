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

FROM ghcr.io/google/grr:latest
COPY --from=fleetspeak /fleetspeak/bin/client /usr/local/bin/fleetspeak-client
COPY config /config
COPY grr-client-config.yaml /config/grr.client.yaml
WORKDIR /
ENTRYPOINT ["fleetspeak-client", "-config" , "/config/config.textproto", "-alsologtostderr"]
