#! /usr/bin/env bash


set -x

cd ../kernel-python/container/

# Create the tarball of the kernel files
tar --gzip --create --dereference \
    --file=jupyter_enterprise_gateway_kernel_image_files_docker-python.tar.gz \
    kernel-launchers/ bootstrap-kernel.sh

# Build the Docker image
docker build --tag "ghcr.io/eodcgmbh/python-jeg-kernel:beta" .

# Cleanup
rm jupyter_enterprise_gateway_kernel_image_files_docker-python.tar.gz

set +x
