# Backup Configuration for CNPG with Garage

This Helm chart configures CloudNativePG (CNPG) backups against a generic S3-compatible object store, using Garage as the default example.

## Prerequisites

Garage is deployed with `../garage-chart` (see the Garage section in the top-level README):

```bash
helm upgrade --install garage ../garage-chart -n garage --create-namespace --wait
```

Its post-install/post-upgrade Job:
- creates the bucket `barman-cloud-greeting-backup`
- creates (or reuses) the Garage access key `barman-greeting` with read/write on the bucket
- writes `ACCESS_KEY_ID`, `ACCESS_SECRET_KEY` and `REGION` into `cnpg-system/garage-credentials`

Do not create this Secret by hand: Garage only accepts keys it has issued or imported
(`GK` + 24 hex characters, 64-hex secret).

## Configuration

Update your `values.yaml` to enable backups:

```yaml
backup:
  enabled: true
  objectStoreName: garage-backup-store
  retentionPolicy: 1d
  destinationPath: "s3://barman-cloud-greeting-backup"
  endpointURL: "http://garage.garage.svc.cluster.local:3900"
  s3SecretName: garage-credentials
  s3AccessKeyIdKey: ACCESS_KEY_ID
  s3AccessSecretKeyKey: ACCESS_SECRET_KEY
  s3RegionKey: REGION
  walCompression: gzip
  walMaxParallel: 2
```

`s3RegionKey` is required for Garage: it rejects request signatures for any region other than its own
(`garage` by default), and Barman otherwise signs for `us-east-1`.

### Deployment order

1. CNPG operator and Barman Cloud plugin (creates the `cnpg-system` namespace)
2. `garage-chart` (Garage, bucket, key and the Secret)
3. This chart

### Scheduled Backups

To enable automatic scheduled backups, configure the schedule:

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  # ... other backup configuration
```

### Object Store Connection

Make sure:

1. The Garage service is reachable from the CNPG pods at the configured `endpointURL`
2. The bucket in `destinationPath` already exists
3. The secret has read/write access to that bucket

### Testing Backup

After deployment, you can trigger a manual backup:

```bash
kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: manual-backup-$(date +%Y%m%d-%H%M%S)
  namespace: cnpg-system
spec:
  cluster:
    name: postgres-greeting
EOF
```

### Monitoring Backups

Check backup status:

```bash
# Check cluster status
kubectl get clusters -n cnpg-system

# Check backup status
kubectl get backups -n cnpg-system

# Check scheduled backup status
kubectl get scheduledbackups -n cnpg-system
```

## Security Notes

1. Store object-store credentials securely in Kubernetes secrets
2. Consider using external secret management in production
3. Enable TLS for the object-store endpoint when required
4. Review backup retention policies based on your requirements
