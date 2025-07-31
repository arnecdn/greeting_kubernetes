# greeting_kubernetes
The project includes plattform services running in a Kubernetes environment for the greeting application.
Kafka
Keda
LGTM stack
OTEL Collector 


The resources are deployed with Helm from public and local Helm charts. 
All resources have their own local configuration files. 


# Kafka
Kafkfa is used as an intermediate message broker for the greeting application in order to decouple the producer and consumer applications.
The Kafka-cluster is installed in KRaft mode, which means that it runs as a single node without the need for ZooKeeper.

## Installation
In order to install the local Kafka node in KRaft mode, use the local installation config.
 
``` 
helm install kafka-chart ./kafka-chart --namespace default --create-namespace
helm uninstall kafka-chart --namespace default
```

## Creating the application topic 'greeting' for producer and consumer
The producer application greeting_rust needs the topic `greetings` to be created in order to send messages to it.
This is done by applying the `values.yaml` file to the Kafka Helm chart with an upgrade.
```
helm upgrade kafka-chart ./kafka-chart --namespace default --values ./kafka-chart/values.yaml
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

helm upgrade my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --values helm-my-lgtm-stack-values.yaml
helm install my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0 --create-namespace --values helm-my-lgtm-stack-values.yaml
helm -n lgtm-stack diff upgrade my-lgtm-distributed grafana/lgtm-distributed -f kubernetes/helm-my-lgtm-stack-values.yaml

```

## Grafana Tempo
Configuring Tempo.configmap-> replication_factor from 3 to one

## Opentelemetry Collector
https://opentelemetry.io/docs/collector/quick-start/

install opentelemetry collector for logs, trace and metrics
```
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm install my-opentelemetry-collector open-telemetry/opentelemetry-collector \
   --set image.repository="otel/opentelemetry-collector-k8s" \
   --set mode=statefulset
   
helm upgrade my-opentelemetry-collector open-telemetry/opentelemetry-collector --values helm-otel-collector-values.yaml 
```

For adding tracing export from otel collector, the tempo-distributor must be configured for the otlp.
Added configuration for otlp grpc and http to the configmap of tempo-distributor
