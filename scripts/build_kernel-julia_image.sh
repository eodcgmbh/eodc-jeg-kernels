#! /usr/bin/env bash


set -x

cd ../kernel-julia/container/

# Create the tarball of the kernel files
tar --gzip --create --dereference \
    --file=jupyter_enterprise_gateway_kernel_image_files_docker-julia.tar.gz \
    kernel-launchers/ bootstrap-kernel.sh eventloop.jl init.jl

# Build the Docker image
docker build --tag "ghcr.io/eodcgmbh/julia-jeg-kernel:beta" .

# Cleanup
rm jupyter_enterprise_gateway_kernel_image_files_docker-julia.tar.gz

set +x
