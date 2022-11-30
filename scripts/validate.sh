#!/usr/bin/env bash

# This script downloads the Flux OpenAPI schemas, then it validates the
# Flux custom resources and the kustomize overlays using kubeconform.
# This script is meant to be run locally and in CI before the changes
# are merged on the main branch that's synced by Flux.

# Copyright 2020 The Flux authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script is meant to be run locally and in CI to validate the Kubernetes
# manifests (including Flux custom resources) before changes are merged into
# the branch synced by Flux in-cluster.

# Prerequisites
# - yq v4.6
# - kustomize v4.1
# - kubeconform v0.4.12


WORKDIR="./gen"

CI_FLUX_REL="https://github.com/fluxcd/flux2/releases/download/v0.37.0/crd-schemas.tar.gz"
CI_FLUX_SHA="e96731db40f844a745d17c4736583fe6c5ded1f93edb1ebd9a030f3deaec9c1a"
CI_KUBECONFORM_REL="https://github.com/yannh/kubeconform/releases/download/v0.5.0/kubeconform-linux-amd64.tar.gz"
CI_KUBECONFORM_SHA="5b39700d0924072313ad7e898b6101ea0ebdd3634301b1176b25a8572e62190e"

set -x
if [ ${CI} ]; then
    `which kubeconform`
    if [ $? -ne 0 ]; then
        curl -o /tmp/kubeconform.tar.gz -s -L ${CI_KUBECONFORM_REL}
        sha256sum /tmp/kubeconform.tar.gz | grep -q ${CI_KUBECONFORM_SHA}
        if [ $? -ne 0 ]; then
            echo "ERROR: invalid sha256 for kubeconform"
            exit 1
        fi
        tar -xvf /tmp/kubeconform.tar.gz -C /usr/local/bin/
        chmod +x /usr/local/bin/kubeconform
    fi
fi

if [ ! -x ${WORKDIR}/flux-crd-schemas/master-standalone-strict ]; then
    echo "INFO - Downloading Flux OpenAPI schemas"
    mkdir -p ${WORKDIR}/flux-crd-schemas/master-standalone-strict
    curl -sL ${CI_FLUX_REL} -o ${WORKDIR}/crd-schems.tar.gz
    sha256sum ${WORKDIR}/crd-schems.tar.gz | grep -q ${CI_FLUX_SHA}
    if [ $? -ne 0 ]; then
      echo "ERROR - schemas package doesn't match the SHA"; exit 1
    fi
    tar zxf ${WORKDIR}/crd-schems.tar.gz -C ${WORKDIR}/flux-crd-schemas/master-standalone-strict
    rm -f ${WORKDIR}/crd-schems.tar.gz
else
    echo "INFO - Using cached Flux OpenAPI schemas"
fi

set +ex
find . -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Validating $file"
    yq e 'true' "$file" > /dev/null
done

kubeconform_config=( "-strict" "-ignore-missing-schemas" "-schema-location" "default" "-schema-location" "${WORKDIR}/flux-crd-schemas" "-verbose")

echo "INFO - Validating clusters"
find ./clusters -maxdepth 2 -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    kubeconform "${kubeconform_config[@]}" "${file}"
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      exit 1
    fi
done

# mirror kustomize-controller build options
kustomize_flags=("--load-restrictor=LoadRestrictionsNone")
kustomize_config="kustomization.yaml"

echo "INFO - Validating kustomize overlays"
find . -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Validating kustomization ${file/%$kustomize_config}"
    kustomize build "${file/%$kustomize_config}" "${kustomize_flags[@]}" | \
      kubeconform "${kubeconform_config[@]}"
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      exit 1
    fi
done