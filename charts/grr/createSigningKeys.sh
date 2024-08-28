#!/bin/sh
# This script can be used to create the executable signing keys for the GRR clients.
set -e

# Generate the GRR client executable signing private key
openssl genrsa -out  charts/grr/certs/exe-sign-private-key.pem

# Generate the GRR client executable signing public key
openssl rsa -in  charts/grr/certs/exe-sign-private-key.pem -pubout -out charts/grr/certs/exe-sign-public-key.pem
