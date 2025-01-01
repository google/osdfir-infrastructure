#!/bin/bash

# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cat << "EOF"

   ____                   _____      _ _ _
  / __ \                 |  __ \    | (_) |
 | |  | |_ __   ___ _ __ | |__) |___| |_| | __
 | |  | | '_ \ / _ \ '_ \|  _  // _ \ | | |/ /
 | |__| | |_) |  __/ | | | | \ \  __/ | |   <
  \____/| .__/ \___|_| |_|_|  \_\___|_|_|_|\_\
        | |
        |_|

EOF

# Generates a random string of a specified length using characters from a defined set.
function generate_random_string() {
  local charset="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local length=32
  openssl rand -base64 32 | tr -dc "$charset" | fold -w "$length" | head -n 1
}

# This function replaces all occurrences of a search pattern within a specified file
# with a given replacement value. It ensures compatibility with both GNU and BSD
# versions of the 'sed' command.
replace_in_file() {
  local search_pattern="$1"
  local replacement_value="$2"
  local filename="$3"
  # Portable sed usage: handle both GNU and BSD sed
  if sed --version 2>&1 | grep -q GNU; then
    sed -i "s/${search_pattern}/${replacement_value}/g" "${filename}"
  else
    sed -i "" "s/${search_pattern}/${replacement_value}/g" "${filename}"
  fi
}

echo "ARTIFACT_REGISTRY: ${ARTIFACT_REGISTRY}"
echo "GKE_CLUSTER_LOCATION: ${GKE_CLUSTER_LOCATION}"
echo "GKE_CLUSTER_NAME: ${GKE_CLUSTER_NAME}"
echo "OPENRELIK_DB: ${OPENRELIK_DB}"
echo "OPENRELIK_DB_ADDRESS: ${OPENRELIK_DB_ADDRESS}"
echo "OPENRELIK_DB_INSTANCE: ${OPENRELIK_DB_INSTANCE}"
echo "OPENRELIK_DB_USER: ${OPENRELIK_DB_USER}"
echo "PROJECT: ${PROJECT}"
echo "REDIS_ADDRESS: ${REDIS_ADDRESS}"
echo "REGION: ${REGION}"
echo "ZONE: ${ZONE}"

# Setup variables
echo -e "\033[1;34m[1/8] Setting up variables...\033[0m\c"
BASE_DEPLOY_URL="https://raw.githubusercontent.com/openrelik/openrelik-deploy/main/docker"
BASE_SERVER_URL="https://raw.githubusercontent.com/openrelik/openrelik-server/main"
STORAGE_PATH="\/usr\/share\/openrelik\/data\/artifacts"
POSTGRES_USER=${OPENRELIK_DB_USER}
POSTGRES_SERVER=${OPENRELIK_DB_ADDRESS}
POSTGRES_DATABASE_NAME=${OPENRELIK_DB}
RANDOM_SESSION_STRING="$(generate_random_string)"
RANDOM_JWT_STRING="$(generate_random_string)"
echo -e "\r\033[1;32m[1/8] Setting up variables... Done\033[0m"

# Fetch installation files
echo -e "\033[1;34m[2/8] Downloading configuration files...\033[0m\c"
cp config_template.env config.env
cp settings_template.toml settings.toml
echo -e "\r\033[1;32m[2/8] Downloading configuration files... Done\033[0m"

# Replace placeholder values in settings.toml
echo -e "\033[1;34m[3/8] Configuring settings...\033[0m\c"
replace_in_file "<REPLACE_WITH_STORAGE_PATH>" "${STORAGE_PATH}" "settings.toml"
replace_in_file "<REPLACE_WITH_POSTGRES_USER>" "${POSTGRES_USER}" "settings.toml"
replace_in_file "<REPLACE_WITH_POSTGRES_SERVER>" "${POSTGRES_SERVER}" "settings.toml"
replace_in_file "<REPLACE_WITH_POSTGRES_DATABASE_NAME>" "${POSTGRES_DATABASE_NAME}" "settings.toml"
replace_in_file "<REPLACE_WITH_RANDOM_SESSION_STRING>" "${RANDOM_SESSION_STRING}" "settings.toml"
replace_in_file "<REPLACE_WITH_RANDOM_JWT_STRING>" "${RANDOM_JWT_STRING}" "settings.toml"
replace_in_file "<REPLACE_WITH_PROJECT_ID>" "${PROJECT}" "settings.toml"
replace_in_file "<REPLACE_WITH_ZONE>" "${ZONE}" "settings.toml"
replace_in_file "<REPLACE_WITH_ENABLE_GCP>" "${ENABLE_GCP}" "settings.toml"
replace_in_file "<REPLACE_WITH_API_SERVER_URL>" "https:\/\/openrelik.${OPENRELIK_HOSTNAME}" "settings.toml"
replace_in_file "<REPLACE_WITH_UI_SERVER_URL>" "https:\/\/${OPENRELIK_HOSTNAME}" "settings.toml"
replace_in_file "<REPLACE_WITH_ALLOWED_ORIGIN>" "https:\/\/${OPENRELIK_HOSTNAME}" "settings.toml"

# Replace placeholder values in config.env
replace_in_file "<REPLACE_WITH_POSTGRES_USER>" "${POSTGRES_USER}" "config.env"
replace_in_file "<REPLACE_WITH_POSTGRES_DATABASE_NAME>" "${POSTGRES_DATABASE_NAME}" "config.env"
replace_in_file "<REPLACE_WITH_API_SERVER_URL>" "https:\/\/openrelik.${OPENRELIK_HOSTNAME}" "config.env"
echo -e "\r\033[1;32m[3/8] Configuration settings... Done\033[0m"
