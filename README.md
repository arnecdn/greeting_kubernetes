# greeting_kubernetes
// Kubernetes setup for greeting application infrastructure
This project contains the Kubernetes setup for the greeting application infrastructure.

The following components are included:
Kafka
Keda
LGTM stack
CloudNativePG (PostgreSQL) with Barman Cloud backups
Garage (S3 object storage for the PostgreSQL backups)

The resources are deployed with Helm from public and local Helm charts. 
All resources have their own local configuration files.

Installation steps for the components are described in the following sections.
``` 
helm repo add kedacore https://kedacore.github.io/charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add cnpg https://cloudnative-pg.github.io/charts
`helm repo add jetstack https://charts.jetstack.io`
helm repo update


helm install kafka-chart ./kafka-chart --namespace kafka --create-namespace
helm install keda kedacore/keda --namespace kafka --create-namespace


helm upgrade --install cnpg --namespace cnpg-system --create-namespace --set config.clusterWide=true --version 0.27.0 cnpg/cloudnative-pg

helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s
helm upgrade --install plugin-barman-cloud cnpg/plugin-barman-cloud --namespace cnpg-system

# Garage (object storage for PostgreSQL backups): node, bucket, access key and cnpg-system/garage-credentials
# Requires the cnpg-system namespace (created by the cnpg install above)
helm upgrade --install garage ./garage-chart -n garage --create-namespace --wait

make -C postgres-chart/image
helm upgrade --install postgres-greeting ./postgres-chart -n default

kubectl create namespace meta-monitoring
kubectl create secret generic minio -n meta-monitoring --from-literal=rootUser=minio123 --from-literal=rootPassword=minio123
helm install meta-monitoring grafana/meta-monitoring -n meta-monitoring --create-namespace -f meta-monitoring-values.yaml

``` 


## Kafka Helm Chart
A local Helm chart is used to deploy a Kafka cluster in KRaft mode.
The chart is located in the `kafka-chart` directory.

### Installation
In order to install the local Kafka node in KRaft mode, use the local installation config.
``` 
helm install kafka-chart ./kafka-chart --namespace kafka --create-namespace

helm upgrade kafka-chart ./kafka-chart --namespace kafka --create-namespace

helm uninstall kafka-chart ---namespace kafka --create-namespace

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
helm install keda kedacore/keda --namespace kafka --create-namespace
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
kubectl create namespace meta-monitoring
kubectl create secret generic minio -n meta-monitoring --from-literal=rootUser=minio123 --from-literal=rootPassword=minio123

```

In order to scale the stack for minikube, all replicas can be set to 1 in the `meta-monitoring-values.yaml` file, 
as the default values are set to 3 replicas for each component.

OBS: The meta-monitoring must be installed within the namespace **meta-monitoring**. 
Sub-charts of the meta-monitoring chart are installed in the same namespace, and apparantly depend on the namespace.
```
helm repo add grafana https://grafana.github.io/helm-charts

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

# Garage

Garage is deployed from the local `garage-chart` folder as a single Helm release `garage`. The chart:
- wraps the upstream Garage chart, vendored unmodified in `garage-chart/charts/garage` (Garage v2.5.0, chart 0.10.4);
- configures it for Minikube: multi-arch image `dxflrs/garage` (needed on arm64), single-node mode,
  Garage pinned to the `minikube` node, and admin API enabled with a generated token (Secret `garage-admin-token`);
- runs a post-install/post-upgrade Job that creates the bucket `barman-cloud-greeting-backup`, the access key
  `barman-greeting` with read/write on it, and writes the credentials into Secret `cnpg-system/garage-credentials`.

The Job writes into the `cnpg-system` namespace, so install the CNPG operator first, and install Garage before the PostgreSQL cluster.

### Install or upgrade Garage
```bash
helm upgrade --install garage ./garage-chart -n garage --create-namespace --wait
```
The Job is idempotent and runs on every install and upgrade. For each key it:
- reuses the Garage key `barman-greeting` if it exists;
- otherwise re-imports the credentials already stored in `garage-credentials` (keeps the same key after a Garage reinstall);
- otherwise creates a new key;
- grants read/write on the bucket and writes `ACCESS_KEY_ID`, `ACCESS_SECRET_KEY` and `REGION` into `cnpg-system/garage-credentials`.

Do not create `garage-credentials` by hand. Garage only accepts keys it has issued or imported,
and rejects requests signed for any region other than its own (`garage`).

Buckets, keys and target Secrets are configured in `garage-chart/values.yaml`. Values under its `garage:` section are
passed to the upstream chart (see `garage-chart/charts/garage/values.yaml`).

Check the result:
```bash
kubectl -n garage exec garage-0 -c garage -- /garage status
kubectl -n garage exec garage-0 -c garage -- /garage bucket list
kubectl -n garage exec garage-0 -c garage -- /garage key info barman-greeting
kubectl -n cnpg-system get secret garage-credentials

```

### Update the vendored Garage chart
The upstream chart is not published to a Helm repository. To move to a newer Garage release, replace the folder
from the Garage git repository and update `version` / `appVersion` in `garage-chart/Chart.yaml`:
```bash
rm -rf garage-chart/charts/garage
git -C <path-to-garage-repo> archive <tag> script/helm/garage | tar -x --strip-components=2 -C garage-chart/charts/
```

### Uninstall Garage
```bash
helm uninstall garage -n garage
kubectl -n garage delete pvc --all   # deletes all stored backups and keys
```
The `garage-credentials` Secret is kept. If Garage is reinstalled, the Job imports the same key again,
so PostgreSQL does not need any change.


### PostgreSQL Cluster
To install a PostgreSQL cluster using the local Helm chart, use the following command:
In order to install the PostgreSQL cluster, the CNPG operator must be installed first, as described in the previous section.
The Garage bucket and the `garage-credentials` Secret must exist before backups are enabled (Garage section above).
Backup settings (endpoint, bucket, Secret keys, region) are in the `backup` section of `postgres-chart/values.yaml`;
see `postgres-chart/BACKUP.md` for details.
```
helm upgrade --install postgres-greeting ./postgres-chart -n cnpg-system --create-namespace
```

PVCs for PostgreSQL are managed by CloudNativePG from the chart's `cluster.storage` values.
Example override with an explicit PVC template:
```yaml
cluster:
  storage:
    size: 20Gi
    storageClass: standard
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      volumeMode: Filesystem
      selector:
        matchLabels:
          app: postgres-greeting
```

You can also use a shorthand selector map, and the chart will render it as `matchLabels`:
```yaml
cluster:
  storage:
    pvcTemplate:
      selector:
        app: postgres-greeting
```

Install or upgrade with a custom values file:
```bash
helm upgrade --install postgres-greeting ./postgres-chart -n cnpg-system --create-namespace -f postgres-values.yaml
```

Uninstall the PostgreSQL cluster with the following command:
```
helm uninstall postgres-greeting --namespace cnpg-system
```


### Clean up Namespaces (optional)
Uninstall the Helm releases first, then delete the namespaces. Deleting `garage` removes all stored backups;
deleting `cnpg-system` removes the `garage-credentials` Secret (it is recreated by the next Garage install or upgrade).
```bash
kubectl delete namespace meta-monitoring
kubectl delete namespace garage
kubectl delete namespace cnpg-system
```
