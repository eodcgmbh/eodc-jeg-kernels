#! /usr/bin/env bash


exit 0 # Remove this line to run the script


# Big picture:
# 1. Build and push the kernel image
# 2. Put kernelspecs in a PV and make it available to the enterprise gateway deployment via a PVC
# 3. Install the enterprise gateway with Helm, using the PVC for kernelspecs


# Build the kernel image
./build_kernel-julia_image.sh

# Prepare kernelspecs tarball for transfer to minikube
tar --create --gzip --directory=../../../kernelspecs/ --file=kernelspecs.tar .

# Start minikube
minikube start minikube start --cpus=2 --memory=4g --embed-certs=true

# minikube ssh: Create directory for kernelspecs in minikube
sudo mkdir --parents /mnt/jeg/kernelspecs

# local: Transfer kernelspecs tarball to minikube
minikube cp ./kernelspecs.tar /mnt/jeg/kernelspecs/

# minikube ssh: Extract kernelspecs tarball and set permissions
cd /mnt/jeg/kernelspecs; sudo tar --extract --file=kernelspecs.tar
sudo chmod --recursive 755 /mnt/jeg/kernelspecs/

# Create namespace for JEG
kubectl create namespace jeg

# Create secret for pulling images from GitHub Container Registry
kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=XXX \
    --docker-password=XXX \
    --docker-email=XXX \
    --namespace=jeg

kubectl patch serviceaccount default \
    --patch='{"imagePullSecrets": [{"name": "ghcr-secret"}]}' \
    --namespace=jeg

# Create PV and PVC for kernelspecs
kubectl apply --namespace=jeg --filename=jeg-kernelspec-pv.yaml
kubectl apply --namespace=jeg --filename=jeg-kernelspec-pvc.yaml

# Install JEG with Helm
helm upgrade --install enterprise-gateway ./etc/kubernetes/helm/enterprise-gateway/ \
    --kube-context minikube \
    --create-namespace --namespace jeg \
    --set image=elyra/enterprise-gateway:3.2.3 \
    --set kernel.shareGatewayNamespace=true \
    --set kernel.launchTimeout=600 \
    --set kernelspecs.enabled=false \
    --set nfs.enabled=false \
    --set kernelspecsPvc.enabled=true \
    --set kernelspecsPvc.name=jeg-kernelspec-pvc \
    --set kernel.allowedKernels="{R_kubernetes,python_kubernetes,julia_kubernetes}"
    --set global.imagePullSecrets[0].name=ghcr-secret

# New shell
kubectl port-forward --namespace jeg svc/enterprise-gateway 8888:8888 &

# New shell
jupyter lab --gateway-url=http://localhost:8888 --no-browser --GatewayClient.request_timeout=600.0


