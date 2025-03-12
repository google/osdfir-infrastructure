#!/bin/sh
# This script can be used to create the executable signing keys for the GRR clients.
set -e

mkdir certs

# Generate the GRR client executable signing private key
openssl genrsa -out ./certs/exe-sign-private-key.pem

# Generate the GRR client executable signing public key
openssl rsa -in ./certs/exe-sign-private-key.pem -pubout -out ./certs/exe-sign-public-key.pem

PRI_KEY=$(cat ./certs/exe-sign-private-key.pem | sed ':a;N;$!ba;s/\n/\\\\n/g')

PUB_KEY=$(cat ./certs/exe-sign-public-key.pem | sed ':a;N;$!ba;s/\n/\\\\n/g')

echo $PRI_KEY
echo $PUB_KEY

sed -i "s'EXE_SIGN_PRIVATE_KEY'$PRI_KEY'g" ./templates/server-local-secret.yaml
sed -i "s'EXE_SIGN_PUBLIC_KEY'$PUB_KEY'g" ./templates/server-local-secret.yaml
