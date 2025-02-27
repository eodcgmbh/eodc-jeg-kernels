#! /usr/bin/env bash


set -x

docker build --tag "ghcr.io/eodcgmbh/eodc-jeg-kernels/jeg-kernelspecs:beta" .

set +x
