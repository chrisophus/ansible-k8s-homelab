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

## Testing Before Production

### Option 1: Vagrant VMs (Recommended)
Test the full setup in VirtualBox VMs:

```bash
# Start Vagrant VMs
vagrant up cp1 cp2 cp3

# Test with Vagrant inventory
ansible-playbook -i inventory-vagrant.ini test-playbook.yml

# Bootstrap SSH keys
ansible-playbook -i inventory-vagrant.ini bootstrap.yml

# Deploy full cluster
ansible-playbook -i inventory-vagrant.ini site.yml -e @group_vars/vagrant.yml

# Test cluster
vagrant ssh cp1 -c "kubectl get nodes"
```

### Option 2: Dry Run Testing (Recommended for real hardware)
Test against your real hardware without making changes:

```bash
# Run automated dry run test
./test-dry-run.sh

# Or manually:
ansible-playbook -i inventory.ini test-playbook.yml
ansible-playbook -i inventory.ini site.yml --check --diff
```

### Option 3: Single Node Test
Test on just one physical node first:

```bash
# Run automated single node test
./test-single-node.sh

# Or manually:
ansible-playbook -i inventory-single.ini test-single.yml
```

### Reset/Cleanup
If you need to reset nodes back to clean state:

```bash
# Reset all nodes
ansible-playbook -i inventory.ini reset.yml

# Reset single node
ansible-playbook -i inventory-single.ini reset.yml
```

## Quick Start

1. **Configure your inventory:**
   ```bash
   # Edit inventory.ini with your node IPs
   vim inventory.ini
   ```

2. **Setup SSH keys (first time only):**
   ```bash
   # If you only have password access initially
   ansible-playbook -i inventory.ini bootstrap.yml --ask-pass --ask-become-pass

   # Or if you already have some SSH access
   ansible-playbook -i inventory.ini ssh-setup.yml
   ```

3. **Update variables:**
   ```bash
   # Edit group_vars/all.yml
   # - Set correct network interface name (replace eth0)
   # - Change keepalived password
   # - Adjust VIP to match your network
   vim group_vars/all.yml
   ```

4. **Deploy cluster:**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

5. **Access your cluster:**
   ```bash
   # Copy kubeconfig from the first control plane node
   scp ubuntu@192.168.0.48:~/.kube/config ~/.kube/config

   # Test access via VIP
   kubectl --server=https://192.168.0.100:6443 get nodes
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

## SSH Key Management

The playbooks include two approaches for SSH key distribution:

### bootstrap.yml - Initial Setup
Use when you only have password access to your nodes:
```bash
# Setup SSH keys with password authentication
ansible-playbook -i inventory.ini bootstrap.yml --ask-pass --ask-become-pass

# Optionally disable password auth (be careful!)
ansible-playbook -i inventory.ini bootstrap.yml --ask-pass --ask-become-pass -e disable_password_auth=true
```

### ssh-setup.yml - Full Key Distribution
Use when you have SSH access and want full inter-node connectivity:
```bash
# Distribute keys for inter-node communication
ansible-playbook -i inventory.ini ssh-setup.yml
```

This sets up:
- SSH keys for all nodes to communicate with each other
- Proper SSH client configuration
- Known hosts entries
- Connectivity testing

## Troubleshooting

**Check SSH connectivity:**
```bash
# Test SSH access to all nodes
ansible all -i inventory.ini -m ping

# Test inter-node SSH
ansible all -i inventory.ini -m shell -a "ssh cp1 'hostname'"
```

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