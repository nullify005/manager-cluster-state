# manager-cluster-state

a experiment in gitops management of my HVAC controller applications deployed on rasperry pi 3's

## goals

* stateless, repeatables builds & deployments into k8s
* includes base infra within k8s (cni, metrics, logging etc.)
* includes the apps which need which I want to run
* can be built & iterated on locally in addition to a remote cluster

## todo

* work out the environment config overlay
* especially for deployed applications running different config per environment
* work out secrets injection
* service-intesis
* actually blat the pi's & replace them with this
* fold the base system provisioning into it?