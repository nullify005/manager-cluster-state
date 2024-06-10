#!/bin/bash

set -ex
asdf plugin-add helm https://github.com/Antiarchitect/asdf-helm.git
asdf plugin-add kubectl https://github.com/asdf-community/asdf-kubectl.git
asdf plugin-add helmfile https://github.com/nwiizo/asdf-helmfile.git
asdf plugin-add kustomize https://github.com/Banno/asdf-kustomize.git
asdf plugin-add kubeseal https://github.com/stefansedich/asdf-kubeseal
asdf plugin add kubeconform https://github.com/lirlia/asdf-kubeconform.git
asdf plugin-add flux2 https://github.com/tablexi/asdf-flux2.git
asdf plugin add k3d
asdf install