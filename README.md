# README

## Components

### container/

These scripts run inside the Julia/Jupyter container or are used to create it.

* `kernel-launchers/`

  This directory is expected to be in the container at `/usr/local/bin/`.

  * `julia/scripts/launch_ijuliakernel.jl`
    * Started by `bootstrap_kernel.sh` with the relevant environment variables (kernel ID, public key, etc.) as parameters, which are set by the JEG at container startup. This, in turn, invokes the `server_listener.py` as a subprocess.
  * `julia/scripts/server_listener.py`
    * This takes the initial connection parameters from the JEG, attempts to find (but not bind to) available ports accordingly for [ZeroMQ](https://zeromq.org/), and finally responds to JEG with a so-called `connection_file`, which includes all parameters to establish a connection between JEG and the Julia kernel.

* `bootstrap-kernel.sh`

  * The script that is initially invoked when the kernel container starts. Depending on the chosen language, it calls the corresponding runtime. In the case of Julia, `launch_ijuliakernel.jl` with the necessary parameters from JEG is started.

* `eventloop.jl`

  * The event loop at the kernel's core that continously receives messages from JEG. This file is slightly extend from recent commits to [IJulia](https://github.com/JuliaLang/IJulia.jl) and needs to be fixed such that no adaptations are required (see comments and FIXME).

* `init.jl`

  * The last startup script for IJulia that is invoked by `launch_ijuliakernel.jl`. This takes the connection parameters created by `server_listener.py` in order to bind to ZeroMQ ports and set up corresponding message queues. Furthermore, all standard streams are redirected to IJulia.

* `Dockerfile`
  * The defining file for Julia kernels. It is based on `quay.io/jupyter/julia-notebook` but extended such that the modified files herein are included in the final image. The startup script is `bootstrap-kernel.sh`.


### gateway/kernelspec-image

These files are meant to be placed at the Jupyter Enterprise Gateway.

* `julia_kubernetes/`
  * `kernel.json`
    * This is the kernel specification that defines the image to be used and how Kubernetes is supposed to start the pod that holds the running Julia kernel container.
  * `logo-64x64.png`
    * The Julia logo.
  * `scripts/kernel-pod.yaml.j2`
    * The Jinja template that defines the kernel's pod can be modified to mount certain paths or set memory and compute limits, for example.
  * `scripts/launch_kubernetes.py`
    * With this script, Kubernetes is instructed to initiate a pod according to the kernel specification. This is unaltered, but must be included nonetheless.


* `Dockerfile`
  * The Dockerfile for this kernelspec image that is mounted by the enterprise gateway pod.

### scripts/

* `build_kernel_image.sh`
  Builds and pushes the Julia kernel image `julia-kernel:alpha`

* `build_kernelspec_image.sh`
  Builds and pushes the kernel specification image `julia-kernelspec:alpha` that includes Julia.

* `cmd.sh`
  Bash commands to start JEG and JupyterLab in a Minikube cluster.

* `pre-pull.sh`
  Some commands that prematurely pull relevant images on the kernel image pullers.

### test/

* `julia-testnb.ipynb`
  * A Julia notebook that allows to test the basic functionalities, including multi-threaded code execution.
