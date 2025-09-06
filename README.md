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

helm uninstall my-lgtm-distributed grafana/lgtm-distributed -n lgtm-stack

helm repo add grafana https://grafana.github.io/helm-charts
helm install my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0 --create-namespace


helm upgrade my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --values helm-my-lgtm-stack-values.yaml
helm install my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0 --create-namespace --values helm-my-lgtm-stack-values.yaml

helm -n lgtm-stack diff upgrade my-lgtm-distributed grafana/lgtm-distributed -f kubernetes/helm-my-lgtm-stack-values.yaml

```

# Grafana Alloy
Grafana Alloy is a Grafana distribution that includes Grafana, Loki, Tempo, and Prom
etheus, providing a complete observability solution.
It is designed to be easy to install and use, with a focus on providing a unified experience

```
helm install --namespace default my-grafana-alloy grafana/alloy --values helm-grafana-alloy-values.yaml
helm install --namespace default grafana-alloy grafana/alloy --values helm-grafana-alloy-values.yaml
helm uninstall --namespace default my-grafana-alloy
helm upgrade --namespace default my-grafana-alloy grafana/alloy --values helm-grafana-alloy-values.yaml
```


For adding tracing export from otel collector, the tempo-distributor must be configured for the otlp.
Added configuration for otlp grpc and http to the configmap of tempo-distributor


##Jaeger
Added a Jaeger installation 

```
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts   
helm install jaeger jaegertracing/jaeger --namespace jaeger --create-namespace
helm upgrade jaeger jaegertracing/jaeger --namespace jaeger --create-namespace --values helm-jaeger-values.yaml
```