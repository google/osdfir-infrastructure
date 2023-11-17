#!/bin/bash
# OSDFIR Infrastructure integration tests
# This script can be used to test the integration between dfTimewolf, Timesketch, and Turbinia
# Requirements:
# - have 'kubectl' and 'expect' packages installed
# - have the OSDFIR Infrastructure Helm chart deployed and are authenticated to the GKE cluster
# - have the 'dfTimewolf', 'turbinia-client', and 'timesketch' CLI's installed

set -o posix
set -e

LOGS="logs"
OUT_TGZ="e2e-test-logs.tgz"
RELEASE="os"
DISK="disk-1"
SKETCH_ID="1"
FAILED=0

if [ $# -ne  2 ]
then
  echo "Not enough arguments supplied, please provide GCP project and zone"
  echo "$0 [PROJECT] [ZONE]"
  exit 1
fi

GCP_PROJECT="$1"
GCP_ZONE="$2"

echo -n "Started at "
date -Iseconds

kubectl --namespace default port-forward service/$RELEASE-timesketch 5000:5000 > /dev/null 2>&1 &
kubectl --namespace default port-forward service/$RELEASE-turbinia 8000:8000  > /dev/null 2>&1 &

# Run dfTimewolf recipe

TS_SECRET=$(kubectl get secret --namespace default $RELEASE-timesketch-secret -o jsonpath="{.data.timesketch-user}" | base64 -d)
export DFTIMEWOLF_NO_CURSES=1
#dftimewolf gcp_turbinia_ts $GCP_PROJECT $GCP_ZONE --disk_names $DISK --incident_id test213 --timesketch_username timesketch --timesketch_password $TS_SECRET

# Turbinia integration test

cat > $HOME/.turbinia_api_config.json <<EOL
{
	"default": {
		"description": "Turbinia client test config",
		"API_SERVER_ADDRESS": "http://127.0.0.1",
		"API_SERVER_PORT": 8000,
		"API_AUTHENTICATION_ENABLED": false,
		"CLIENT_SECRETS_FILENAME": ".client_secrets.json",
		"CREDENTIALS_FILENAME": ".credentials_default.json"
	}
}
EOL

echo "Starting integration test for Turbinia..."
# Grab all Turbinia request IDs
REQUEST_IDS=$(turbinia-client status summary -j | jq -r '.[] | .[].request_id')

for req in $REQUEST_IDS
do      
	# Grab all PlasoParserTask or PlasoHasherTask where successful = false
	status=$(turbinia-client status request $req -j | jq '[.tasks[]] | map({name: .name, id: .id, successful: .successful}) | map(select(.name == "PlasoParserTask" or .name == "PlasoHasherTask")) | map(select(.successful==false))')
	length=$(echo $status | jq '. | length')
	if [[ $length > 0 ]]
	then
	  echo "A failed Plaso Task for Turbinia request $req has been detected."
	  echo "Listing failed Tasks..."
    # Grab the Task ID
	  tasks=$(echo $status | jq -r '.[] | .id')
	  FAILED=1
	  for t in $tasks
      do
	    echo "Plaso Task ID: $t"
	    turbinia-client status task $t
      #turbinia-client result task $t
	  done
	fi
done

if [ "$FAILED" != "0" ]
then
  echo "Turbinia integration tests failed! Exiting..."
  exit 1
fi

echo "Turbinia integration tests succeeded!"

# Timesketch integration test

echo "Starting integration test for Timesketch..."

# Generate credentials if they don't exist
if ! [ -f ~/.timesketchrc ] && ! [ -f ~/.timesketch.token ]; then
    expect <<END_EXPECT
    spawn timesketch config
    expect "What is the value for <host_uri>"
    send "http://127.0.0.1:5000\r"
    expect "What is the value for <auth_mode>"
    send "userpass\r"
    expect "What is the value for <username>"
    send "timesketch\r"
    expect "Password for user timesketch"
    send "$TS_SECRET\r"
    expect eof
END_EXPECT
fi

timesketch config set sketch $SKETCH_ID
# Grab the error_message field in the sketch.timelines response
TIMESKETCH_STATUS=$(timesketch --output-format json sketch describe | jq '.resource_data.objects | .[].timelines | .[].datasources | .[].error_message')
TIMESKETCH_LENGTH=$(timesketch --output-format json sketch describe | jq '.resource_data.objects | .[].timelines | .[].datasources | .[].error_message | length')

for tl in $TIMESKETCH_LENGTH
do
  # if error_message field is populated
  if [[ $tl > 0 ]]
  then
    FAILED=1
  fi
done

if [[ $FAILED == 1 ]]
then
  echo "A failure in Timesketch importing timelines has been detected!"
  echo $TIMESKETCH_STATUS
fi

if [ "$FAILED" != "0" ]
then
  echo "Timesketch integration tests failed! Exiting..."
  exit 1
fi

echo "Timesketch integration tests succeeded!"
echo -n "Ended at "
date -Iseconds

exit 0