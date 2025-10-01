# Adding Nodes to Existing Cluster

## Adding Worker Nodes

1. **Update inventory** to include new worker nodes:
```ini
[new_workers]
kube3 ansible_host=192.168.0.200
kube4 ansible_host=192.168.0.201
```

2. **Run the add-worker playbook**:
```bash
ansible-playbook -i inventory.ini add-worker.yml
```

## Adding Control Plane Nodes

1. **Update inventory** to include new control plane nodes:
```ini
[new_controlplanes]
kube3 ansible_host=192.168.0.200 keepalived_priority=80
kube4 ansible_host=192.168.0.201 keepalived_priority=70
```

2. **Run the add-controlplane playbook**:
```bash
ansible-playbook -i inventory.ini add-controlplane.yml
```

## Converting Current Setup to Support Worker Nodes

If you want some nodes to be workers instead of all control planes:

1. **Update inventory.ini**:
```ini
[controlplane]
plex ansible_host=192.168.0.48 keepalived_priority=110
kube1 ansible_host=192.168.0.79 keepalived_priority=100

[workers]
kube2 ansible_host=192.168.0.252

[new_workers]
# Leave empty for now

[new_controlplanes]
# Leave empty for now
```

2. **Update site.yml** to include workers:
```yaml
- hosts: workers
  roles:
    - worker
```

3. **Reset and redeploy**:
```bash
ansible-playbook -i inventory.ini reset-k8s-only.yml
ansible-playbook -i inventory.ini site.yml
```

## Best Practices

- **Control planes**: Always maintain odd numbers (1, 3, 5) for etcd quorum
- **Tokens**: Fresh tokens are generated automatically for each addition
- **Certificates**: Fresh certificate keys are generated for control plane additions
- **Testing**: Always verify with `kubectl get nodes` after adding nodes

## Inventory Groups Reference

- `controlplane`: Existing control plane nodes
- `workers`: Existing worker nodes
- `new_controlplanes`: New control plane nodes to add
- `new_workers`: New worker nodes to add
- `all`: All nodes (used for common setup)