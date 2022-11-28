# manager-cluster-state

a experiment in gitops management of my HVAC controller applications deployed on rasperry pi 3's

## goals

* stateless, repeatables builds & deployments into k8s
* includes base infra within k8s (cni, metrics, logging etc.)
* includes the apps which need which I want to run
* can be built & iterated on locally in addition to a remote cluster

## running

the following is for local context only

assumes docker-desktop is running for k3d

```
./scripts/cluster.sh up
```

then to apply the config to the cluster

```
./scripts/cluster.sh apply
```

## cheatsheet

if the helm deployments get stuck or cannot be reconciled
```
flux suspend hr <release name>
# fix whatever the problem is & apply again
flux resume hr <release name>
```

## notes

### helm values

when using `valuesFiles` in the `HelmRelease` spec it doesn't automatically include the
`values.yaml` from the chart itself?
I'm sure there's a good reason for this design decision, but I don't feel like it makes
sense as then you have to include the values for the chart itself for every release ... why?

## todo

* work out the environment config overlay
* especially for deployed applications running different config per environment
* work out secrets injection
* service-intesis
* actually blat the pi's & replace them with this
* fold the base system provisioning into it?

## alternative idea

working through the examples for environment customisation is making me annoyed at just
how ugly it could be using kustomize as the method for overlay

this is annoying because helm basically does this for us, we just need to use it better

the only issue is that helm references need to be "in a repo of some kind" (which includes OCI)
meaning that it's a PITA to reproduce the environment entirely locally without reference to an
outside repo or having commits / branches etc.

the option I'm considering is this:

* within this repo flux ONLY ever points to helm releases ... except that we still need kustomization
  overlay for values files etc. ...
* then use helm to do all the heavy lifting, which feels a little more natural

do some kind of generation, which tries to abstract away some of the flux bits until we gen the
manifests at the end, which themselves are pushed into the repo ...