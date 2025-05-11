#!/bin/bash
# filepath: ./k8s-project/part4-deploy-monitoring/start-monitoring.sh

# Kill any existing port forwards for these ports
echo "Stopping any existing port forwards..."
lsof -ti:9090 | xargs kill -9 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# Start Prometheus port forwarding in background
echo "Starting Prometheus port forwarding..."
kubectl port-forward -n monitoring svc/prometheus 9090:9090 > /tmp/prometheus-forward.log 2>&1 &
PROMETHEUS_PID=$!
echo "Prometheus PID: $PROMETHEUS_PID"

# Start Grafana port forwarding in background
echo "Starting Grafana port forwarding..."
kubectl port-forward -n monitoring svc/grafana 3000:3000 > /tmp/grafana-forward.log 2>&1 &
GRAFANA_PID=$!
echo "Grafana PID: $GRAFANA_PID"

# Save PIDs to file for easy cleanup later
echo "$PROMETHEUS_PID $GRAFANA_PID" > /tmp/monitoring-pids.txt

echo "Port forwarding started in background"
echo "Prometheus available at: http://localhost:9090"
echo "Grafana available at: http://localhost:3000"
echo ""
echo "To stop port forwarding, run: ./stop-monitoring.sh"