#! /usr/bin/env bash


exit 0 # Remove this line to run the script

(
    ./build_kernel_image.sh &
    ./build_kernelspec_image.sh &
) &
pid_build=$!

minikube start --embed-certs --memory=4g --cpus=4 &
pid_mkb=$!

wait $pid_build $pid_mkb
helm upgrade --install enterprise-gateway ./enterprise_gateway/etc/kubernetes/helm/enterprise-gateway/ \
    --kube-context minikube --create-namespace --namespace jeg \
    --set kernel.shareGatewayNamespace=true \
    --set kernel.launchTimeout=600 \
    --set kernelspecs.image=docker.io/uberdavid/julia-kernelspec:alpha \
    --set kernel.allowedKernels="{r_kubernetes,python_kubernetes,julia_kubernetes}"

# New shell
kubectl port-forward --namespace jeg svc/enterprise-gateway 8888:8888 &

# New shell
jupyter lab --gateway-url=http://localhost:8888 --no-browser --GatewayClient.request_timeout=600.0
