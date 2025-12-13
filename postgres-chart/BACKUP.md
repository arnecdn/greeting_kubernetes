# Backup Configuration for CNPG with MinIO

This Helm chart now includes backup functionality for CloudNativePG (CNPG) using MinIO as S3-compatible object storage.

## Prerequisites

1. **MinIO Installation**: Ensure MinIO is deployed and accessible in your cluster
2. **Bucket Creation**: Create a bucket in MinIO for storing backups (e.g., `postgres-backups`)

## Configuration

### Basic Backup Setup

Update your `values.yaml` to enable backups:

```yaml
backup:
  enabled: true
  destinationPath: "s3://postgres-backups/cluster-backups"
  endpointURL: "http://minio.cnpg-system.svc.cluster.local:9000"
  minioAccessKey: "your-minio-access-key"
  minioSecretKey: "your-minio-secret-key"
  wal:
    retention: "7d"
  data:
    retention: "7d"
  retentionPolicy: "7d"
```

### Scheduled Backups

To enable automatic scheduled backups, uncomment and configure the schedule:

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM (cron format)
  # ... other backup configuration
```

### MinIO Connection

The chart creates a secret with MinIO credentials automatically. Make sure:

1. MinIO service is accessible at the specified `endpointURL`
2. The bucket specified in `destinationPath` exists in MinIO
3. The MinIO credentials have read/write access to the bucket

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

1. Store MinIO credentials securely
2. Consider using Kubernetes secrets or external secret management
3. Enable TLS for MinIO endpoints in production
4. Review backup retention policies based on your requirements
