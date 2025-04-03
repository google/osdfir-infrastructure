#!/bin/sh
# This script can be used to create the executable signing keys for the GRR clients.
# Note: This is optional and just intended as an example for how keys could be created manually.
set -e

mkdir certs

# Generate the GRR client executable signing private key
openssl genrsa -out ./certs/exe-sign-private-key.pem

# Generate the GRR client executable signing public key
openssl rsa -in ./certs/exe-sign-private-key.pem -pubout -out ./certs/exe-sign-public-key.pem
