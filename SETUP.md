# Setup Instructions

## Before You Begin

This repository has been sanitized for public sharing. You'll need to configure it for your environment.

## Required Configuration

### 1. Create your inventory file
```bash
cp inventory.ini.example inventory.ini
```

Edit `inventory.ini` with your actual:
- Hostnames and IP addresses
- SSH username
- SSH key path

### 2. Create your variables file
```bash
cp group_vars/all.yml.example group_vars/all.yml
```

Edit `group_vars/all.yml` with your:
- Network interface name
- VIP address for your network
- Secure keepalived password

### 3. Important Security Steps

**Change the default password:**
- `keepalived_password` - Used for HA failover authentication between nodes

**Recommended: Use Ansible Vault for secrets**
```bash
# Create encrypted secrets file
ansible-vault create group_vars/secrets.yml

# Add sensitive variables:
keepalived_password: "your-real-password"
```

Then reference in `group_vars/all.yml`:
```yaml
keepalived_password: "{{ vault_keepalived_password }}"
```

### 4. Network Configuration

Ensure your network settings match your environment:
- `network_interface`: Run `ip addr` to find your interface name
- `cluster_vip`: Choose an unused IP in your network range
- Firewall rules for cluster communication

## Deployment

Once configured, deploy the cluster:

```bash
# Validate configuration first
ansible-playbook validate-config.yml

# Deploy base cluster
ansible-playbook -i inventory.ini site.yml
```

## Post-Deployment: Application Setup

After the cluster is running, add applications using Helm:

```bash
# Example: Longhorn storage
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace

# Example: Monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

## Verification

After deployment, verify everything is working:

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Test cluster API access
kubectl cluster-info
```

## Security Reminders

- [ ] Changed keepalived default password
- [ ] Configured firewall rules for cluster ports
- [ ] Set up TLS certificates for external access
- [ ] Configured backup procedures for etcd
- [ ] Secured kubectl access with proper RBAC

## Getting Help

If you encounter issues:
1. Check the main README.md troubleshooting section
2. Verify your configuration matches your environment
3. Check component logs for specific error messages
4. Open an issue with detailed logs and configuration (remove sensitive data!)