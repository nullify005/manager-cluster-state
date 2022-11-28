# manager-cluster-state

a experiment in gitops management of my HVAC controller applications deployed on rasperry pi 3's

## goals

* stateless, repeatables builds & deployments into k8s
* includes base infra within k8s (cni, metrics, logging etc.)
* includes the apps which need which I want to run
* can be built & iterated on locally in addition to a remote cluster

## running

### locally with local filesystem as the reference

the following is for local context only which tries to avoid all things Git

assumes docker-desktop is running for k3d

`./scripts/cluster.sh up`

then to apply the config to the cluster

`./scripts/cluster.sh apply`

it's important to note that in this mode you can't use flux Kustomization objects which depend
on Git repos that you are actively working on, because the context is meant to be all local

also as a consequence dependancies between certain objects (HelmRelease excluded) don't work
and must be handed outside using standard k8s kustomize and `wait`

clean up with

`./scripts/cluster.sh stop`

### locally using git as the reference

same as the local environment, but switches to using flux `Kustomize` & Git as the source

here we get to exercise the full `DependsOn` featureset to ensure ordering of cluster components

`./scripts/cluster.sh up`

then to apply the config

`./scripts/cluster.sh apply development`

if you want to switch out which branch is in use then modify `./clusters/development/sources.yaml`

typically iteration here is:

* make a branch
* commit & push to the branch
* ensure that `sources.yaml` points to the branch
* start up the cluster & apply the config

from there it'll start behaving as a GitOps based cluster

### remotely to production

here the bootstrapping is a little different & uses the actual `flux bootstrap` to push the gotk etc.
into the target repo

* get the cluster to a state where you can interact with the API
* run `./scripts/cluster.sh bootstrap production`
  this will push in the baseline secrets (git repo access via SSH, GH tokens, & the SealedSecrets key)

then sit back & wait for things to reconcile (on the pi3's this can take a while ...)

## cheatsheet

### stuck HelmRelease

if the helm deployments get stuck or cannot be reconciled
```
flux suspend hr <release name>
# fix whatever the problem is & apply again
flux resume hr <release name>
```

### hating flux

`./scripts/cluster.sh blat`

which will uninstall flux & bin the namespace (don't forget to hunt down & kill any ClusterRole, ClusterRoleBinding, & PodSecurityPolicy objects which aren't ns scoped)

## notes

### helm values

when using `valuesFiles` in the `HelmRelease` spec it doesn't automatically include the
`values.yaml` from the chart itself?
I'm sure there's a good reason for this design decision, but I don't feel like it makes
sense as then you have to include the values for the chart itself for every release ... why?

### Kustomization can't depend on HelmRelease & visa-versa

looks like it's a known thing without a resolution that a HelmRelease can't depend on a Kustomization or
visa versa.

this is pretty annoying & means you have to effectively wrap HelmRelease in Kusomization's so that ultimately
the dependancy tree works properly.

locally this is super frustrating because you can't replicate dependancies easily without shells scripting &
`wait` commands.

I suppose this is why there are examples of using OCI repos as the source reference so that you can emulate
the remote environment without using Git as the Source basis ...

### still annoyed with environment overlays

the complete lack of any templating which keys / pivots on an environment name is really fucking annoying &
ends up meaning that environment specific things only get run / tested when you are at the final environment,
which isn't idea from a development & testing point of view

probably need to look harder into OCI repos & Kustomization's as the actual base for local rather than
using kustomize

ideally I want to get to a single set of files which are able to pivot per environment based on post rendering
to ensure that we're actually using the same build plan for every environment with very minor tweaks

### ditch HelmRelease or go harder?

I like helm, it's convenient but I get the sense that flux really really wants you to unroll helm deployments
into their resulting manifests & then manage that

There's several threads on using an intermediary step / a "build" if you will that results in just the manifests
which then flux sync's with rather than it natively having to deal with HelmRelease & the environment overlays

my early concerns with unrolling is working out the dependancy heirarchy

## todo

* add a log & metrics shipper to the cluster
* experiment with Grafana Cloud for remote write so the cluster doesn't need to run grafana & prom itself (except for scraping)
* pull out the prom config values into their own upstream repo (or a subset of this repo) so that the values aren't a mess
* pull out the grafana dashboards so that the JSON config isn't inlined within a ConfigMap which makes that a PITA to diff
* add some sort of PR check process using GitHub Actions
* make the repo public?
