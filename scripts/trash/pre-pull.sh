#! /usr/bin/env bash


python3 -c "import docker; dc=docker.from_env(); dc.images.pull('ghcr.io/eodcgmbh/julia-jeg-kernel', tag='beta')"
python3 -c "import docker; dc=docker.from_env(); dc.images.pull('ghcr.io/eodcgmbh/julia-jeg-kernelspec', tag='beta')"


# Manual image management on running kernel-image-puller pod
#import docker
#client = docker.from_env()
#client.images.list()
#client.images.pull(<image name>)
#client.images.remove(<image name>)
