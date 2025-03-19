ARG BASE_CONTAINER=quay.io/jupyter/julia-notebook:2024-12-31
FROM ${BASE_CONTAINER}

ENV PATH=${PATH}:${CONDA_DIR}/bin

COPY conda-deps-sys.yaml /tmp/conda-deps-sys.yaml
COPY julia-packages.jl /tmp/julia-packages.jl

RUN pip install --upgrade ipykernel==6.29.5

USER ${NB_UID}

RUN mamba install --yes --verbose --file /tmp/conda-deps-sys.yaml && \
    mamba clean --all && \
    conda clean --all && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

ADD jupyter_enterprise_gateway_kernel_image_files_docker-julia.tar.gz /usr/local/bin/

USER root

RUN mv /usr/local/bin/init.jl \
    $(julia --eval "using IJulia; println(pathof(IJulia))" | rev | cut --delimiter='/' --fields=2- | rev)
RUN mv /usr/local/bin/eventloop.jl \
    $(julia --eval "using IJulia; println(pathof(IJulia))" | rev | cut --delimiter='/' --fields=2- | rev)


#RUN julia /tmp/julia-packages.jl


RUN apt-get update && \
    apt-get install --assume-yes --quiet --no-install-recommends libkrb5-dev && \
    apt-get autoremove --yes && \
    apt-get autoclean --yes && \
    rm --force --recursive /var/lib/apt/lists/*

RUN chown jovyan:users /usr/local/bin/bootstrap-kernel.sh && \
    chmod 0755 /usr/local/bin/bootstrap-kernel.sh && \
    chown --recursive jovyan:users /usr/local/bin/kernel-launchers

USER jovyan

ENV KERNEL_LANGUAGE=julia

HEALTHCHECK NONE

CMD /usr/local/bin/bootstrap-kernel.sh
