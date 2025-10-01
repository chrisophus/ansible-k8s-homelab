#!/bin/bash
set -e

echo "🧪 Starting dry run tests..."

# Test basic connectivity
echo "🔍 Testing connectivity..."
ansible -i inventory.ini all -m ping || {
    echo "❌ Connectivity test failed - check your inventory and SSH access"
    exit 1
}

# Run system validation
echo "🔍 Running system validation..."
ansible-playbook -i inventory.ini test-playbook.yml

# Dry run SSH setup
echo "🔑 Dry run SSH setup..."
ansible-playbook -i inventory.ini ssh-setup.yml --check --diff

# Dry run main playbook
echo "🚀 Dry run main deployment..."
ansible-playbook -i inventory.ini site.yml --check --diff

echo "✅ Dry run completed successfully!"
echo "💡 If everything looks good, run without --check --diff to deploy"