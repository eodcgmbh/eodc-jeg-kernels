FROM busybox:stable

RUN mkdir --parents /kernels/julia_kubernetes /kernels/python_kubernetes

COPY ./julia_kubernetes /kernels/julia_kubernetes

COPY ./python_kubernetes /kernels/python_kubernetes

CMD ["sh"]
