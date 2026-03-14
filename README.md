# greeting_kubernetes
// Kubernetes setup for greeting application infrastructure
This project contains the Kubernetes setup for the greeting application infrastructure.

The following components are included:
Kafka
Keda
LGTM stack

The resources are deployed with Helm from public and local Helm charts. 
All resources have their own local configuration files. 


## Kafka Helm Chart
A local Helm chart is used to deploy a Kafka cluster in KRaft mode.
The chart is located in the `kafka-chart` directory.

### Installation
In order to install the local Kafka node in KRaft mode, use the local installation config.
``` 
helm install kafka-chart ./kafka-chart --namespace default

helm upgrade kafka-chart ./kafka-chart --namespace default

helm uninstall kafka-chart --namespace default

```

## Managing greeting topic for producer and consumer
```
kubectl exec -it kafka-0 -- bash
kafka-topics --list --topic greetings --bootstrap-server kafka-0:9092
kafka-topics --create --topic greetings --partitions 10 --bootstrap-server kafka-0:9092
kafka-topics --alter --topic greetings --partitions 10 --bootstrap-server kafka-0:9092
kafka-topics --delete --topic greetings --bootstrap-server kafka-0:9092
```

# KEDA
For installation of Keda, use Helm with the following commandline parameters.
Setting namespace=default because of some unsolved problem with accessing Kafka in different namespace
There is no configuration, except for the ScaledObject installed when deploying the app greeting-processor-rust POD
```
helm repo add kedacore https://kedacore.github.io/charts
helm install keda kedacore/keda --namespace default
```


# Observability
Observability is implemented based on OpenTelemetry.
Further documentation to
## install LGTM stack

As the lgtm/distributed is obsolete, the meta-monitoring chart is used to deploy the LGTM stack components separately.
Following commands are used to deploy the meta-monitoring chart with the configuration for the LGTM stack components.
https://github.com/grafana/meta-monitoring-chart/blob/main/docs/installation.md

Before installing the meta-monitoring chart, the MinIO secret must be created in the meta namespace, as the LGTM stack components use MinIO for storing data.
```
kubectl create secret generic minio -n meta --from-literal=rootUser=minio123 --from-literal=rootPassword=minio123
helm install meta-monitoring grafana/meta-monitoring -n meta --create-namespace -f meta-monitoring-values.yaml
```

In order to scale the stack for minikube, all replicas can be set to 1 in the `meta-monitoring-values.yaml` file, 
as the default values are set to 3 replicas for each component.

OBS: The meta-monitoring must be installed within the namespace **meta-monitoring**. 
Sub-chastes of the meta-monitoring chart are installed in the same namespace, and apparantly depend on the namespace.

```
helm repo add grafana https://grafana.github.io/helm-charts

kubectl create namespace meta-monitoring
kubectl create secret generic minio -n meta-monitoring --from-literal=rootUser=minio123 --from-literal=rootPassword=minio123
helm install meta-monitoring grafana/meta-monitoring -n meta-monitoring -f meta-monitoring-values.yaml
helm upgrade meta-monitoring grafana/meta-monitoring -n meta-monitoring -f meta-monitoring-values.yaml
helm uninstall meta-monitoring -n meta-monitoring
```


### CNPG
To install CloudNativePG in a non-cluster-wide mode, use the following Helm command:
```
helm upgrade --install cnpg \
--namespace cnpg-system \
--create-namespace \
--set config.clusterWide=false \
--version 0.27.0 \
cnpg/cloudnative-pg
```
Uninstall CloudNativePG operator with the following command:
```
helm uninstall cnpg --namespace cnpg-system
```


### Barman Cloud Plugin
To install the Barman Cloud plugin for CloudNativePG, use the following Helm command:
The Barman Cloud plugin depends on Cert-Manager being installed in the cluster.
Using cert-manager.io Helm chart to install cert-manager:
```
helm repo add jetstack https://charts.jetstack.io --force-update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
```
Uninstall cert-manager with the following command:
```
helm uninstall cert-manager --namespace cert-manager
```

Wait for cert-manager webhook to be ready before installing the Barman Cloud plugin:
```
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s
```

Then install the Barman Cloud plugin:
```
helm upgrade --install plugin-barman-cloud cnpg/plugin-barman-cloud --namespace cnpg-system

helm uninstall plugin-barman-cloud --namespace cnpg-system
```

# Minio

To install MinIO using Helm, you can use the following command:
```
helm upgrade --install greeting-minio minio/minio \
  --namespace cnpg-system \
  --set resources.requests.memory=512Mi \
  --set replicas=1 \
  --set persistence.enabled=false \
  --set mode=standalone \
  --set rootUser=rootuser,rootPassword=rootpass123
```
Uninstall MinIO with the following command:
```
helm uninstall greeting-minio
```

### PostgreSQL Cluster
To install a PostgreSQL cluster using the local Helm chart, use the following command:
In order to install the PostgreSQL cluster, the CNPG operator must be installed first, as described in the previous section.
Also login minio and create access key and secret key for the Barman Cloud plugin to access the MinIO instance.
```
helm upgrade --install postgres-greeting ./postgres-chart -n cnpg-system --create-namespace
```
Uninstall the PostgreSQL cluster with the following command:
```
helm uninstall postgres-greeting --namespace cnpg-system
```


### Clean up Namespaces (optional)
```bash
kubectl delete namespace meta
kubectl delete namespace cnpg-system
kubectl delete namespace cnpg-database
```