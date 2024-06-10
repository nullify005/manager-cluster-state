#!/bin/bash

# manage a local cluster

set -ex

VERSION="v1.24.8-k3s1"
CLUSTER="manager-cluster-state"

function secrets {
    set +e
    kubectl create ns flux-system
    set -e
    if [ -e ./clusters/${1}/secrets.yaml ]; then
        kubectl apply -f ./clusters/${1}/secrets.yaml
    fi
    pushCerts
}

function getArch {
    export LOCAL_ARCH="arm64"
    localArch=$(uname -m)
    if [ "${localArch}" = "x86_64" ]; then
        export LOCAL_ARCH="amd64"
    fi
}

function pushCerts {
    NS="kube-system"
    NAME="cluster-secrets-20240610"
    set +e
    kubectl -n ${NS} get secret ${NAME} || \
        kubectl -n ${NS} create secret tls ${NAME} --cert=./certs/pub-sealed-secrets.pem --key=./certs/priv-sealed-secrets.pem
    set -e
    kubectl -n ${NS} label --overwrite=true secret ${NAME} sealedsecrets.bitnami.com/sealed-secrets-key=active
}

getArch
case ${1} in
    start|up|create)
        k3d cluster create ${CLUSTER} --image rancher/k3s:${VERSION}-${LOCAL_ARCH} -p "80:80@loadbalancer" -p "443:443@loadbalancer" --agents 2
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
                kubectl wait -n kube-system helmrelease/sealed-secrets --for=condition=ready
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
    certs)
        openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout ./certs/priv-sealed-secrets.pem -out ./certs/pub-sealed-secrets.pem -subj "/CN=sealed-secret/O=sealed-secret"
        ;;
    *)
        echo "no command specified, wanted (start|up|create|stop|down|delete|apply|secrets|bootstrap|blat)"
        exit 1
        ;;
esac