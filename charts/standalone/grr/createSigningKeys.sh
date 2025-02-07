#!/bin/sh
# This script can be used to create the executable signing keys for the GRR clients.
set -e

# Generate the GRR client executable signing private key
openssl genrsa -out charts/grr/containers/grr-client/config/exe-sign-private-key.pem

# Generate the GRR client executable signing public key
openssl rsa -in charts/grr/containers/grr-client/config/exe-sign-private-key.pem -pubout -out charts/grr/containers/grr-client/config/exe-sign-public-key.pem

PRI_KEY=$(cat charts/grr/containers/grr-client/config/exe-sign-private-key.pem | \
                     sed ':a;N;$!ba;s/\n/\\\\n/g')

PUB_KEY=$(cat charts/grr/containers/grr-client/config/exe-sign-public-key.pem | \
                    sed ':a;N;$!ba;s/\n/\\\\n/g')

echo $PRI_KEY
echo $PUB_KEY

sed -i "s'EXE_SIGN_PUBLIC_KEY'$PUB_KEY'g" charts/grr/containers/grr-client/grr-client-config.yaml
sed -i "s'EXE_SIGN_PRIVATE_KEY'$PRI_KEY'g" charts/grr/containers/grr-client/config/grr.yaml
sed -i "s'EXE_SIGN_PUBLIC_KEY'$PUB_KEY'g" charts/grr/containers/grr-client/config/grr.yaml
sed -i "s'EXE_SIGN_PRIVATE_KEY'$PRI_KEY'g" charts/grr/templates/secret/sec-grr-server-local.yaml
sed -i "s'EXE_SIGN_PUBLIC_KEY'$PUB_KEY'g" charts/grr/templates/secret/sec-grr-server-local.yaml
