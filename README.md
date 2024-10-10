# greeting_kubernetes
The project includes resources for enabling the greeting sample apps infrastructure as Kafka, LGTM stack and OTEL Collector 
running in a Minikube Kubernetes environment.
The resources can be installed with the following sample commands


# Kafka
## Installation
In order to install the local Kafka node in KRaft mode, use the local installation config.

```
kubectl apply -f kubernetes/kafka.yaml
```
## Create greeting topic for producer and consumber
```
kubectl exec -it kafka-0 -- bash
kafka-topics --create --topic greetings --partitions 10 --bootstrap-server kafka-0:9092
```
# Observability
Observability is implemented based on OpenTelemetry.
Further documentation to
## install LGTM stack

```
helm install my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0 --create-namespace
helm upgrade my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0
helm uninstall my-lgtm-distributed grafana/lgtm-distributed -n lgtm-stack


helm upgrade my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --values kubernetes/helm-my-lgtm-stack-values.yaml
helm install my-lgtm-distributed --namespace=lgtm-stack grafana/lgtm-distributed --version 2.1.0 --values kubernetes/helm-my-lgtm-stack-values.yaml
helm -n lgtm-stack diff upgrade my-lgtm-distributed grafana/lgtm-distributed -f kubernetes/helm-my-lgtm-stack-values.yaml

```

## Grafana Tempo
Configuring Tempo.configmap-> replication_factor from 3 to one

## Opentelemetry Collector
https://opentelemetry.io/docs/collector/quick-start/

install opentelemetry collector for logs, trace and metrics
```
helm install my-opentelemetry-collector open-telemetry/opentelemetry-collector \
   --set image.repository="otel/opentelemetry-collector-k8s" \
   --set mode=statefulset
   
helm upgrade my-opentelemetry-collector open-telemetry/opentelemetry-collector --values kubernetes/helm-otel-collector-values.yaml 
```

For adding tracing export from otel collector, the tempo-distributor must be configured for the otlp.
Added configuration for otlp grpc and http to the configmap of tempo-distributor
