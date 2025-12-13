# greeting_kubernetes
// Kubernetes setup for greeting application infrastructure
This project contains the Kubernetes setup for the greeting application infrastructure.

The following components are included:
Kafka
Keda
LGTM stack
Grafana Alloy

The resources are deployed with Helm from public and local Helm charts. 
All resources have their own local configuration files. 

## Installation from base
The default installation of the complete sett of backing services for the greeting application group, 
the following commands can be run. 
``` 
helm install kafka-chart ./kafka-chart --namespace default
helm install keda kedacore/keda --namespace default
helm install my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0 --create-namespace --values helm-my-lgtm-stack-values.yaml
helm install --namespace default grafana-alloy grafana/alloy --values helm-grafana-alloy-values.yaml
```



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

```
helm repo add grafana https://grafana.github.io/helm-charts
helm install my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0 --create-namespace --values helm-my-lgtm-stack-values.yaml
helm uninstall my-lgtm-distributed grafana/lgtm-distributed -n lgtm-stack

helm upgrade my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --values helm-my-lgtm-stack-values.yaml

helm -n lgtm-stack diff upgrade my-lgtm-distributed grafana/lgtm-distributed -f kubernetes/helm-my-lgtm-stack-values.yaml

```

# Grafana Alloy
Grafana Alloy is a Grafana distribution that includes Grafana, Loki, Tempo, and Prom
etheus, providing a complete observability solution.
It is designed to be easy to install and use, with a focus on providing a unified experience

```
helm install --namespace default grafana-alloy grafana/alloy --values helm-grafana-alloy-values.yaml
helm uninstall --namespace default my-grafana-alloy
helm upgrade --namespace default my-grafana-alloy grafana/alloy --values helm-grafana-alloy-values.yaml
```


For adding tracing export from otel collector, the tempo-distributor must be configured for the otlp.
Added configuration for otlp grpc and http to the configmap of tempo-distributor

### CNPG
To install CloudNativePG in a non-cluster-wide mode, use the following Helm command:
```
hhelm upgrade --install cnpg \
--namespace cnpg-system \
--create-namespace \
--set config.clusterWide=false \
--version 0.27.0 \
cnpg/cloudnative-pg


helm uninstall cnpg --namespace cnpg-system
```

### PostgreSQL Cluster
To install a PostgreSQL cluster using the local Helm chart, use the following command:

```
helm upgrade --install postgres-greeting ./postgres-chart -n cnpg-system --create-namespace

helm uninstall postgres-greeting --namespace cnpg-system
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


helm uninstall greeting-minio
```

## Complete Uninstall Commands

To uninstall all the Helm charts and clean up the deployment, use the following commands in reverse order of installation:

### Uninstall Grafana Alloy
```bash
helm uninstall grafana-alloy --namespace default
```

### Uninstall LGTM Stack
```bash
helm uninstall my-lgtm-distributed --namespace lgtm-stack
```

### Uninstall PostgreSQL Cluster
```bash
# Uninstall the local postgres-chart
helm uninstall postgres-greeting --namespace cnpg-system

# Uninstall CNPG operator
helm uninstall cnpg --namespace cnpg-system
```

### Uninstall KEDA
```bash
helm uninstall keda --namespace default
```

### Uninstall Kafka
```bash
helm uninstall kafka-chart --namespace default
```

### Clean up Namespaces (optional)
```bash
kubectl delete namespace lgtm-stack
kubectl delete namespace cnpg-system
kubectl delete namespace cnpg-database
```