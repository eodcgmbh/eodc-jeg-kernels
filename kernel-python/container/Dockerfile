ARG BASE_CONTAINER=quay.io/jupyter/scipy-notebook:2025-03-17
FROM ${BASE_CONTAINER}

ENV PATH=${PATH}:${CONDA_DIR}/bin

COPY conda-deps-geo.yaml /tmp/conda-deps-geo.yaml
COPY conda-deps-sys.yaml /tmp/conda-deps-sys.yaml

RUN pip install --upgrade ipykernel==6.29.5

RUN mamba install --yes --verbose --file /tmp/conda-deps-sys.yaml && \
    mamba install --yes --verbose --file /tmp/conda-deps-geo.yaml && \
    mamba clean --all && \
    conda clean --all && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

ADD jupyter_enterprise_gateway_kernel_image_files*.tar.gz /usr/local/bin/

USER root

RUN apt-get update && \
    apt-get install --assume-yes --quiet --no-install-recommends libkrb5-dev && \
    apt-get autoremove --yes && \
    apt-get autoclean --yes && \
    rm --force --recursive /var/lib/apt/lists/*

RUN chown jovyan:users /usr/local/bin/bootstrap-kernel.sh && \
	chmod 0755 /usr/local/bin/bootstrap-kernel.sh && \
	chown --recursive jovyan:users /usr/local/bin/kernel-launchers

USER jovyan

ENV KERNEL_LANGUAGE=python

HEALTHCHECK NONE

CMD /usr/local/bin/bootstrap-kernel.sh