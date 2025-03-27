#ARG BASE_CONTAINER=quay.io/jupyter/julia-notebook:2025-03-25
#FROM ${BASE_CONTAINER}

# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/minimal-notebook
FROM $BASE_IMAGE

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Julia dependencies
# install Julia packages in /opt/julia instead of ${HOME}
ENV JULIA_DEPOT_PATH=/opt/julia \
    JULIA_PKGDIR=/opt/julia

# Setup Julia
RUN /opt/setup-scripts/setup_julia.py

USER ${NB_UID}

COPY setup-julia-packages.bash /tmp/setup-julia-packages.bash

# Setup IJulia kernel & other packages
RUN /opt/setup-scripts/setup-julia-packages.bash

ENV PATH=${PATH}:${CONDA_DIR}/bin

COPY conda-deps-sys.yaml /tmp/conda-deps-sys.yaml
#COPY julia-packages.jl /tmp/julia-packages.jl

RUN pip install --upgrade ipykernel==6.29.5

RUN conda install --name base --channel conda-forge "mamba>=2.0.8"

USER ${NB_UID}

RUN mamba install --yes --verbose --file /tmp/conda-deps-sys.yaml && \
    mamba clean --all && \
    conda clean --all && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

#RUN julia --eval 'println(ENV["JULIA_DEPOT_PATH"])'                                                                                                                                                                '

#RUN julia --eval 'println(ENV["JULIA_DEPOT_PATH"])'

#RUN julia /tmp/julia-packages.jl

ADD jupyter_enterprise_gateway_kernel_image_files_docker-julia.tar.gz /usr/local/bin/
RUN julia --eval "import Pkg; using IJulia; Pkg.update(); ENV[\"IJULIA_DEBUG\"]=true; Pkg.build(\"IJulia\"); Pkg.add([\"DataStructures\"]); Pkg.precompile()"
RUN fix-permissions "${JULIA_PKGDIR}" "${CONDA_DIR}/share/jupyter"

USER root

RUN apt-get update && \
    apt-get install --assume-yes --quiet --no-install-recommends libkrb5-dev && \
    apt-get autoremove --yes && \
    apt-get autoclean --yes && \
    rm --force --recursive /var/lib/apt/lists/*


#RUN julia --eval 'using Pkg; using IJulia; ENV["IJULIA_DEBUG"]=true; Pkg.build("IJulia")'

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

#RUN julia --eval 'println(ENV["JULIA_DEPOT_PATH"])'

CMD /usr/local/bin/bootstrap-kernel.sh
