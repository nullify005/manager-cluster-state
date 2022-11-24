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