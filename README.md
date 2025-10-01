# Kubernetes Homelab Cluster

This Ansible playbook deploys a highly available 3-node Kubernetes cluster optimized for homelab use.

## Features
- All nodes are both control-plane and workers (maximum resource efficiency)
- High availability via keepalived virtual IP
- Automatic OS security updates with scheduled reboots
- Prometheus monitoring with node_exporter
- Zero-downtime cluster upgrades
- Idempotent operations for reliable re-runs

## Prerequisites
- 3 Ubuntu 22.04+ nodes with SSH access
- User with sudo privileges
- Network connectivity between all nodes
- Update the inventory.ini with your node IPs

## Quick Start

1. **Configure your inventory:**
   ```bash
   # Edit inventory.ini with your node IPs
   vim inventory.ini
   ```

2. **Update variables:**
   ```bash
   # Edit group_vars/all.yml
   # - Set correct network interface name (replace eth0)
   # - Change keepalived password
   # - Adjust VIP to match your network
   vim group_vars/all.yml
   ```

3. **Deploy cluster:**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

4. **Access your cluster:**
   ```bash
   # Copy kubeconfig from the first control plane node
   scp ubuntu@192.168.1.10:~/.kube/config ~/.kube/config

   # Test access via VIP
   kubectl --server=https://192.168.1.100:6443 get nodes
   ```

## Upgrades

To upgrade Kubernetes:

1. Update `kube_version` and `kube_version_short` in `group_vars/all.yml`
2. Run the upgrade playbook:
   ```bash
   ansible-playbook -i inventory.ini upgrade.yml
   ```

The upgrade process:
- Runs serially (one node at a time)
- Drains workloads before upgrading
- Ensures zero downtime
- Maintains HA throughout the process

## Security Features

- **Automatic OS updates**: Security patches applied daily
- **Scheduled reboots**: Automatic reboots at 3 AM when required
- **Monitoring**: Prometheus metrics for reboot status
- **Package holds**: Prevents accidental K8s component upgrades

## Architecture

- **Keepalived**: Provides floating VIP for API server HA
- **Flannel CNI**: Pod networking (10.244.0.0/16)
- **Containerd**: Container runtime
- **All nodes schedulable**: Control plane nodes run workloads

## Troubleshooting

**Check cluster status:**
```bash
kubectl get nodes -o wide
kubectl get pods -A
```

**Check keepalived status:**
```bash
ansible all -i inventory.ini -m shell -a "systemctl status keepalived"
```

**View VIP status:**
```bash
ansible all -i inventory.ini -m shell -a "ip addr show | grep 192.168.1.100"
```

**Reboot monitoring:**
```bash
# Check if reboot is required
ansible all -i inventory.ini -m shell -a "ls -la /var/run/reboot-required"

# Check reboot metric
curl http://NODE_IP:9100/metrics | grep reboot_required
```