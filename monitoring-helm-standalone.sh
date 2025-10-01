#!/bin/bash
# Standalone Helm deployment for monitoring stack
# Alternative to Ansible approach

set -e

VIP="192.168.0.100"
GRAFANA_PASSWORD="homelab123!"

echo "🚀 Installing monitoring stack with Helm..."

# Add helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create values file
cat > /tmp/monitoring-values.yaml << EOF
prometheus:
  prometheusSpec:
    retention: 30d
    additionalScrapeConfigs:
      - job_name: 'temperature-exporter'
        static_configs:
          - targets:
              - '192.168.0.48:9101'
              - '192.168.0.79:9101'
              - '192.168.0.252:9101'
      - job_name: 'reboot-required'
        static_configs:
          - targets:
              - '192.168.0.48:9102'
              - '192.168.0.79:9102'
              - '192.168.0.252:9102'
  service:
    type: NodePort
    nodePort: 30090

grafana:
  adminPassword: "$GRAFANA_PASSWORD"
  service:
    type: NodePort
    nodePort: 30300

alertmanager:
  service:
    type: NodePort
    nodePort: 30093
EOF

# Deploy monitoring stack
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values /tmp/monitoring-values.yaml \
  --timeout 10m

echo "✅ Monitoring stack deployed!"
echo "📊 Grafana: http://$VIP:3000 (admin/$GRAFANA_PASSWORD)"
echo "📈 Prometheus: http://$VIP:9090"
echo "🚨 AlertManager: http://$VIP:9093"