#!/bin/sh
# This script can be used to download all the necessary Timesketch configuration
# files locally to this machine. Please run when you'd like to make some more
# changes to the config file before deployment.
set -o posix
set -e

# Create config directory
mkdir -p configs/

echo -n "* Fetching configuration files.." 
# Fetch default Timesketch config files
git clone https://github.com/google/timesketch.git
cp -r timesketch/data/* configs/
rm -rf timesketch
echo "OK"