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
#set -x

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

OPENRELIK_API_URL="http://localhost:8710"
OPENRELIK_URL="http://localhost:8711"

if [[ "$1" == "cloud" ]]; then
  OPENRELIK_API_HOSTNAME="openrelik.${OPENRELIK_HOSTNAME}"
  OPENRELIK_API_URL="https:\/\/${OPENRELIK_API_HOSTNAME}"
  OPENRELIK_URL="https:\/\/${OPENRELIK_HOSTNAME}"
  echo "CERTIFICATE_NAME: ${CERTIFICATE_NAME}"
  echo "OPENRELIK_HOSTNAME: ${OPENRELIK_HOSTNAME}"
  echo "PROJECT: ${PROJECT}"
  echo "REDIS_ADDRESS: ${REDIS_ADDRESS}"
  echo "ZONE: ${ZONE}"
elif [[ "$1" == "local" ]]; then
  ENABLE_GCP=false
  OPENRELIK_DB="openrelik"
  OPENRELIK_DB_ADDRESS="svc-postgres"
  OPENRELIK_DB_USER="openrelik"
  PROJECT="none"
  ZONE="none"
else
  echo "usage: config.sh [cloud|local]"
  exit
fi

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
    sed -i "s#${search_pattern}#${replacement_value}#g" "${filename}"
  else
    sed -i "" "s#${search_pattern}#${replacement_value}#g" "${filename}"
  fi
}

# Setup variables
echo -e "\033[1;34m[1/8] Setting up variables...\033[0m\c"
STORAGE_PATH="\/usr\/share\/openrelik\/data\/artifacts"
POSTGRES_PASSWORD="$(generate_random_string)"
RANDOM_JWT_STRING="$(generate_random_string)"
RANDOM_SESSION_STRING="$(generate_random_string)"
echo -e "\r\033[1;32m[1/8] Setting up variables... Done\033[0m"

echo "ENABLE_GCP: ${ENABLE_GCP}"
echo "OPENRELIK_API_HOSTNAME: ${OPENRELIK_API_HOSTNAME}"
echo "OPENRELIK_API_URL: ${OPENRELIK_API_URL}"
echo "OPENRELIK_DB: ${OPENRELIK_DB}"
echo "OPENRELIK_DB_ADDRESS: ${OPENRELIK_DB_ADDRESS}"
echo "OPENRELIK_DB_USER: ${OPENRELIK_DB_USER}"
echo "OPENRELIK_URL: ${OPENRELIK_URL}"
echo "RANDOM_JWT_STRING: ${RANDOM_JWT_STRING}"
echo "RANDOM_SESSION_STRING: ${RANDOM_SESSION_STRING}"
echo "STORAGE_PATH: ${STORAGE_PATH}"

# Fetch installation files
echo -e "\033[1;34m[2/8] Copying settings file...\033[0m\c"
cp settings_template.toml settings.toml
echo -e "\r\033[1;32m[2/8] Copying settings file... Done\033[0m"

# Replace placeholder values in settings.toml
echo -e "\033[1;34m[3/8] Configuring settings...\033[0m\c"
replace_in_file "<REPLACE_WITH_ALLOWED_ORIGIN>" "${OPENRELIK_URL}" "settings.toml"
replace_in_file "<REPLACE_WITH_API_SERVER_URL>" "${OPENRELIK_API_URL}" "settings.toml"
replace_in_file "<REPLACE_WITH_ENABLE_GCP>" "${ENABLE_GCP}" "settings.toml"
replace_in_file "<REPLACE_WITH_POSTGRES_DATABASE_NAME>" "${OPENRELIK_DB}" "settings.toml"
replace_in_file "<REPLACE_WITH_POSTGRES_USER>" "${OPENRELIK_DB_USER}" "settings.toml"
replace_in_file "<REPLACE_WITH_POSTGRES_SERVER>" "${OPENRELIK_DB_ADDRESS}" "settings.toml"
replace_in_file "<REPLACE_WITH_PROJECT_ID>" "${PROJECT}" "settings.toml"
replace_in_file "<REPLACE_WITH_RANDOM_SESSION_STRING>" "${RANDOM_SESSION_STRING}" "settings.toml"
replace_in_file "<REPLACE_WITH_RANDOM_JWT_STRING>" "${RANDOM_JWT_STRING}" "settings.toml"
replace_in_file "<REPLACE_WITH_STORAGE_PATH>" "${STORAGE_PATH}" "settings.toml"
replace_in_file "<REPLACE_WITH_UI_SERVER_URL>" "${OPENRELIK_URL}" "settings.toml"
replace_in_file "<REPLACE_WITH_ZONE>" "${ZONE}" "settings.toml"

if [[ "$1" == "cloud" ]]; then
# Replace placeholders in values-gcp.yaml
replace_in_file "<REPLACE_WITH_API_SERVER_HOSTNAME>" "${OPENRELIK_API_HOSTNAME}" "values-gcp.yaml"
replace_in_file "<REPLACE_WITH_API_SERVER_URL>" "${OPENRELIK_API_URL}" "values-gcp.yaml"
replace_in_file "<REPLACE_WITH_CERTIFICATE_NAME>" "${CERTIFICATE_NAME}" "values-gcp.yaml"
replace_in_file "<REPLACE_WITH_PROJECT_ID>" "${PROJECT}" "values-gcp.yaml"
replace_in_file "<REPLACE_WITH_REDIS_URL>" "redis:\/\/${REDIS_ADDRESS}:6379" "values-gcp.yaml"
replace_in_file "<REPLACE_WITH_UI_SERVER_HOSTNAME>" "${OPENRELIK_HOSTNAME}" "values-gcp.yaml"
fi

if [[ "$1" == "local" ]]; then
# Replace placeholders in values.yaml
replace_in_file "<REPLACE_WITH_POSTGRES_PASSWORD>" "${POSTGRES_PASSWORD}" "settings.toml"
replace_in_file "<REPLACE_WITH_API_SERVER_URL>" "${OPENRELIK_API_URL}" "values.yaml"
replace_in_file "<REPLACE_WITH_POSTGRES_PASSWORD>" "${POSTGRES_PASSWORD}" "values.yaml"
replace_in_file "<REPLACE_WITH_POSTGRES_USER>" "${OPENRELIK_DB_USER}" "values.yaml"
fi
echo -e "\r\033[1;32m[3/8] Configuration settings... Done\033[0m"

mkdir -p templates/configmap
kubectl create configmap cm-settings --dry-run=client -o=yaml --from-file=settings.toml -n openrelik > templates/configmap/cm-settings.yaml
