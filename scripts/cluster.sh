#!/bin/bash

# manage a local cluster

set -ex

VERSION="v1.25.3-k3s1-arm64"
CLUSTER="manager-cluster-state"

case ${1} in
    start|up|create)
        k3d cluster create ${CLUSTER} --image rancher/k3s:${VERSION} -p "80:80@loadbalancer" -p "443:443@loadbalancer" --agents 2
        flux install --components-extra="image-reflector-controller,image-automation-controller" --verbose
        flux check
        ;;
    stop|down|delete)
        k3d cluster delete ${CLUSTER}
        ;;
    apply)
        find ./clusters/local -name \*.yaml -exec kubectl apply -f {} \;
        kustomize build ./infrastructure/ | kubectl apply -f -
        kustomize build ./apps/ | kubectl apply -f -
        ;;
    *)
        echo "no command specified, wanted (start|up|create|stop|down|delete)"
        exit 1
        ;;
esac