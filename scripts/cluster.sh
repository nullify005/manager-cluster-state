#!/bin/bash

# manage a local cluster

set -ex

VERSION="v1.24.8-k3s1-arm64"
CLUSTER="manager-cluster-state"

function secrets {
    set +e
    kubectl create ns flux-system
    set -e
    if [ -e ./clusters/${1}/secrets.yaml ]; then
        kubectl apply -f ./clusters/${1}/secrets.yaml
    fi
    kubectl apply -f ./certs/private-sealed-secrets.yaml
}

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
        shift
        secrets ${@}
        case ${1} in
            development)
                kustomize build ./clusters/development | kubectl apply -f -
            ;;
            *)
                kustomize build ./infrastructure/crds | kubectl apply -f -
                kubectl wait -n flux-system helmrelease/sealed-secrets --for=condition=ready
                kustomize build ./infrastructure/environments/local | kubectl apply -f -
                kustomize build ./apps | kubectl apply -f -
            ;;
        esac
        ;;
    secrets)
        shift
        secrets ${@}
        ;;
    bootstrap)
        shift
        secrets ${@}
        flux bootstrap --components-extra="image-reflector-controller,image-automation-controller" \
            github --owner=nullify005 --repository=manager-cluster-state --personal=true --path ./clusters/${1} --verbose
        ;;
    blat)
        flux uninstall
        kubectl delete ns flux-system
        ;;
    *)
        echo "no command specified, wanted (start|up|create|stop|down|delete)"
        exit 1
        ;;
esac