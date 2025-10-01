#!/bin/bash
set -e

echo "🧪 Starting single node test..."

# Test basic connectivity
echo "🔍 Testing connectivity to single node..."
ansible -i inventory-single.ini all -m ping || {
    echo "❌ Connectivity test failed - check your inventory-single.ini"
    exit 1
}

# Run system validation
echo "🔍 Running system validation..."
ansible-playbook -i inventory-single.ini test-playbook.yml

# Setup SSH if needed
echo "🔑 Setting up SSH..."
ansible-playbook -i inventory-single.ini ssh-setup.yml

# Deploy to single node
echo "🚀 Deploying to single node..."
ansible-playbook -i inventory-single.ini test-single.yml

# Test the deployment
echo "✅ Testing single node deployment..."
ansible -i inventory-single.ini controlplane -m shell -a "kubectl get nodes" -b

echo "🎉 Single node test completed!"
echo "💡 To reset: ansible-playbook -i inventory-single.ini reset.yml"