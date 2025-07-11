# Use the official Docker Hub Ubuntu base image
FROM ubuntu:24.04

# Prevent needing to configure debian packages, stopping the setup of
# the docker container.
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install poetry and any other dependency that your worker needs.
RUN apt-get update && apt-get install -y --no-install-recommends \
    kmod \
    # Add your dependencies here
    && rm -rf /var/lib/apt/lists/*

# Default command if not run from docker-compose (and command being overidden)
CMD ["sleep 3600"]