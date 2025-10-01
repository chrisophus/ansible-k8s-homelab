# Kubernetes HA Homelab with Ansible

A production-grade 3-node HA Kubernetes cluster deployment using Ansible, featuring:
- **High Availability**: 3 control plane nodes with keepalived VIP
- **Networking**: Calico CNI with proper IPAM
- **Security**: Automatic updates with reboot management
- **Foundation**: Ready for application deployment via Helm

## Architecture

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│    node1    │  │    node2    │  │    node3    │
│ (control)   │  │ (control)   │  │ (control)   │
│   prio:110  │  │   prio:100  │  │   prio:90   │
└─────────────┘  └─────────────┘  └─────────────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
                 VIP: 192.168.1.100
```

## Prerequisites

- 3 Ubuntu 22.04+ servers with sudo access
- 4GB+ RAM and 2+ CPU cores per node
- Network connectivity between all nodes
- SSH key-based authentication configured

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone <this-repo>
   cd ansible-k8s-homelab
   ```

2. **Edit inventory.ini** with your actual hosts:
   ```ini
   [controlplane]
   node1 ansible_host=192.168.1.10 keepalived_priority=110
   node2 ansible_host=192.168.1.11 keepalived_priority=100
   node3 ansible_host=192.168.1.12 keepalived_priority=90

   [all:vars]
   ansible_user=your-ssh-user
   ```

3. **Configure variables** in `group_vars/all.yml`:
   ```yaml
   # Network configuration
   network_interface: "eth0"
   cluster_vip: "192.168.1.100"
   keepalived_password: "your-secure-password"

   # Monitoring passwords
   grafana_password: "your-grafana-password"
   ```

4. **Validate configuration**:
   ```bash
   # Validate your configuration (recommended)
   ansible-playbook validate-config.yml
   ```

5. **Deploy the cluster**:
   ```bash
   # Deploy base cluster
   ansible-playbook -i inventory.ini site.yml
   ```

## Components

### Core Cluster
- **Kubernetes**: v1.33.x with kubeadm
- **CNI**: Calico with IPAM
- **Load Balancer**: keepalived with VIP
- **Runtime**: containerd
- **Security**: Automatic updates with scheduled reboots

### Post-Deployment Applications
Deploy these separately using Helm:
- **Storage**: Longhorn distributed storage
- **Monitoring**: Prometheus/Grafana stack
- **Applications**: Plex, Jellyfin, or other services

## Access Points

After deployment:

- **Kubernetes API**: `https://<cluster_vip>:6443`
- **kubectl**: Configure with `scp user@<any-node>:~/.kube/config ~/.kube/config`

## Configuration

### Network Settings
Configure in `group_vars/all.yml`:
```yaml
network_interface: "eth0"           # Your network interface
cluster_vip: "192.168.1.100"       # VIP for HA
keepalived_password: "secure-pass"  # keepalived auth
```

## Playbooks

- `site.yml` - Main cluster deployment
- `validate-config.yml` - Configuration validation
- `reset-k8s-only.yml` - Cluster reset/cleanup

## Maintenance

### Adding Nodes
See `README-adding-nodes.md` for detailed instructions.

### Backup
```bash
# Backup etcd
kubectl -n kube-system get secret etcd-certs -o yaml > etcd-backup.yaml

# Application data backups depend on your storage solution
```

### Updates
```bash
# Update Kubernetes version in group_vars/all.yml, then:
ansible-playbook -i inventory.ini site.yml
```

## Next Steps: Application Deployment

After your cluster is running, deploy applications using Helm:

### Longhorn Storage
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

### Prometheus/Grafana Stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

## Troubleshooting

### Common Issues

1. **VIP not responding**:
   ```bash
   # Check keepalived status
   ansible all -i inventory.ini -m shell -a "systemctl status keepalived"
   ```

2. **Pods stuck pending**:
   ```bash
   # Check node resources
   kubectl describe nodes
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

3. **Storage issues**:
   ```bash
   # Check storage driver status (depends on your solution)
   kubectl get pods -n <storage-namespace>
   kubectl get pv,pvc --all-namespaces
   ```

### Logs
```bash
# Cluster logs
kubectl logs -n kube-system -l component=kube-apiserver
kubectl logs -n kube-system -l k8s-app=calico-node

# Application logs (examples)
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
kubectl logs -n <app-namespace> -l app=<app-name>
```

## Security Notes

- Change default passwords in `group_vars/all.yml`
- Use vault encryption for sensitive variables:
  ```bash
  ansible-vault encrypt group_vars/secrets.yml
  ```
- Configure firewall rules for cluster ports
- Use TLS for all external access

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## Support

For issues and questions:
- Check the troubleshooting section
- Review Kubernetes and component documentation
- Open an issue with detailed logs and configuration