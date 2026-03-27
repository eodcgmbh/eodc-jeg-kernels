################################################################################
# vvvvv inspired by minimal-notebook vvvvv
#
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/minimal-notebook:2025-03-27
FROM $BASE_IMAGE

LABEL maintainer="David Fischak <david.fischak@eodc.eu>"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Julia dependencies
# install Julia packages in /opt/julia instead of ${HOME}
ENV JULIA_DEPOT_PATH=/opt/julia \
    JULIA_PKGDIR=/opt/julia \
    IJULIA_DEBUG=true

# Setup Julia
RUN /opt/setup-scripts/setup_julia.py

USER ${NB_UID}

COPY julia-packages.jl /tmp/julia-packages.jl
COPY setup-julia-packages.bash /opt/setup-scripts/setup-julia-packages.bash

# Setup IJulia kernel & other packages
RUN /opt/setup-scripts/setup-julia-packages.bash


################################################################################
# vvvvv inspired by julia-notebook vvvvv


ENV PATH=${PATH}:${CONDA_DIR}/bin

COPY conda-deps-sys.yaml /tmp/conda-deps-sys.yaml

RUN pip install --upgrade ipykernel==6.29.5

RUN conda install --name base --channel conda-forge "mamba>=2.0.8"

USER ${NB_UID}

RUN mamba install --yes --verbose --file /tmp/conda-deps-sys.yaml && \
    mamba clean --all && \
    conda clean --all && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

ADD jupyter_enterprise_gateway_kernel_image_files_docker-julia.tar.gz /usr/local/bin/

USER root

RUN apt-get update && \
    apt-get install --assume-yes --quiet --no-install-recommends libkrb5-dev && \
    apt-get autoremove --yes && \
    apt-get autoclean --yes && \
    rm --force --recursive /var/lib/apt/lists/*

RUN mv /usr/local/bin/init.jl \
    $(julia --eval "using IJulia; println(pathof(IJulia))" | rev | cut --delimiter='/' --fields=2- | rev)
RUN mv /usr/local/bin/eventloop.jl \
    $(julia --eval "using IJulia; println(pathof(IJulia))" | rev | cut --delimiter='/' --fields=2- | rev)


RUN chown jovyan:users /usr/local/bin/bootstrap-kernel.sh && \
    chmod 0755 /usr/local/bin/bootstrap-kernel.sh && \
    chown --recursive jovyan:users /usr/local/bin/kernel-launchers

USER jovyan

ENV KERNEL_LANGUAGE=julia

HEALTHCHECK NONE

CMD /usr/local/bin/bootstrap-kernel.sh
