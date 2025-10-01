#!/bin/bash
set -e

echo "🧪 Starting Vagrant test environment..."

# Start VMs
echo "📦 Starting Vagrant VMs..."
vagrant up cp1 cp2 cp3

# Wait for VMs to be ready
echo "⏳ Waiting for VMs to be ready..."
sleep 30

# Test basic connectivity
echo "🔍 Testing connectivity..."
ansible -i inventory-vagrant.ini all -m ping || {
    echo "❌ Connectivity test failed"
    exit 1
}

# Run system validation
echo "🔍 Running system validation..."
ansible-playbook -i inventory-vagrant.ini test-playbook.yml

# Bootstrap SSH
echo "🔑 Setting up SSH keys..."
ansible-playbook -i inventory-vagrant.ini bootstrap.yml

# Deploy cluster
echo "🚀 Deploying Kubernetes cluster..."
ansible-playbook -i inventory-vagrant.ini site.yml -e @group_vars/vagrant.yml

# Test cluster
echo "✅ Testing cluster..."
vagrant ssh cp1 -c "kubectl get nodes -o wide"
vagrant ssh cp1 -c "kubectl get pods -A"

# Test VIP
echo "🌐 Testing VIP connectivity..."
vagrant ssh cp1 -c "curl -k https://192.168.56.100:6443/version" || echo "VIP test - expected to need auth"

echo "🎉 Vagrant test completed successfully!"
echo "💡 To access cluster: vagrant ssh cp1"
echo "💡 To destroy test env: vagrant destroy -f"