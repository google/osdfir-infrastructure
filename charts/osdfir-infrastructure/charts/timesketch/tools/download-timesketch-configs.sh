#!/bin/sh
# This script can be used to download all the necessary Timesketch configuration
# files locally to this machine. Please run when you'd like to make some more
# changes to the config file before deployment.
# It accepts an optional --release argument to specify a branch/tag.
set -o posix
set -e

# Default branch/tag
release_branch="master"
temp_dir="timesketch_temp"

# --- Argument Parsing ---
while [ $# -gt 0 ]; do
  case "$1" in
    --release)
      # Check if the argument value is provided and not empty and not another option
      if [ -n "$2" ] && [ "${2#--}" = "$2" ]; then
        release_branch="$2"
        shift 2 # Consume --release and its value
      else
        echo "Error: --release requires a branch/tag name argument." >&2
        echo "Usage: $0 [--release <branch_name>]" >&2
        exit 1
      fi
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      echo "Usage: $0 [--release <branch_name>]" >&2
      exit 1
      ;;
  esac
done

# Create config directory
mkdir -p timesketch-configs/

echo "* Fetching configuration files from branch/tag: ${release_branch}.."
# Fetch default Timesketch config files from the specified branch/tag
# Use a temporary directory name and shallow clone for efficiency
rm -rf "${temp_dir}" # Clean up any previous temporary directory just in case
git clone --depth 1 --branch "${release_branch}" https://github.com/google/timesketch.git "${temp_dir}"

# Copy the data directory contents
cp -r "${temp_dir}/data/"* timesketch-configs/
# Clean up the temporary cloned repository
rm -rf "${temp_dir}"
echo "OK"
