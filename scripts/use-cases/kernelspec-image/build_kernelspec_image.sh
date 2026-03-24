#! /usr/bin/env bash


set -x

cd ../kernel-julia/gateway/kernelspec-image

# Build the Docker image
docker build --tag "ghcr.io/eodcgmbh/eodc-jeg-kernels/jeg-kernelspecs:alpha" .

set +x
