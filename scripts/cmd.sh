#! /usr/bin/env bash


exit 0 # Remove this line to run the script

(
    ./build_kernel_image.sh &
    ./build_kernelspec_image.sh &
) &
pid_build=$!

minikube start minikube start --cpus=4 --memory=4g --embed-certs=true --driver=docker &
pid_mkb=$!

wait $pid_build $pid_mkb
helm upgrade --install enterprise-gateway ./etc/kubernetes/helm/enterprise-gateway/ \
    --kube-context minikube \
    --create-namespace --namespace jeg \
    --set kernel.shareGatewayNamespace=true \
    --set kernel.launchTimeout=600 \
    --set kernelspecs.enabled=false \
    --set nfs.enabled=false \
    --set kernelspecsPvc.enabled=true \
    --set kernelspecsPvc.name=jeg-kernelspec-pvc \
    --set kernel.allowedKernels="{R_kubernetes,python_kubernetes,julia_kubernetes}"
    #--set kernelspecs.image=ghcr.io/eodcgmbh/julia-jeg-kernelspec:beta \

# New shell
kubectl port-forward --namespace jeg svc/enterprise-gateway 8888:8888 &

# New shell
jupyter lab --gateway-url=http://localhost:8888 --no-browser --GatewayClient.request_timeout=600.0



# @minikube
sudo mkdir --parents /mnt/jeg/kernelspecs
sudo tar --extract --file=kernelspecs.tar
sudo chmod --recursive 755 /mnt/jeg/kernelspecs/

# @local
tar --create --gzip --directory=kernelspecs --file=kernelspecs.tar .
minikube cp ./kernelspecs.tar /mnt/jeg/kernelspecs/
