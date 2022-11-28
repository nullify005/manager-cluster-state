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
        case ${2} in
            development)
                kubectl apply -f ./certs/private-sealed-secrets.yaml
                kustomize build ./clusters/development | kubectl apply -f -
            ;;
            *)
                kubectl apply -f ./certs/private-sealed-secrets.yaml
                kustomize build ./clusters/local | kubectl apply -f -
                kubectl wait -n flux-system helmrelease/sealed-secrets --for=condition=ready
                kustomize build ./apps | kubectl apply -f -
            ;;
        esac
        ;;
    secrets)
        if [ ! -e ./clusters/${2}/secret.yaml ]; then
            echo "missing secret at: .//clusters/${2}/secret.yaml"
            exit 1
        fi
        kubectl apply -f ./clusters/${2}/secret.yaml
        ;;
    *)
        echo "no command specified, wanted (start|up|create|stop|down|delete)"
        exit 1
        ;;
esac