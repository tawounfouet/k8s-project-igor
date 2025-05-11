#!/bin/bash
# filepath: /Users/awf/Infrastruture/k8s/k8s-project/part4-deploy-monitoring/stop-monitoring.sh

if [ -f /tmp/monitoring-pids.txt ]; then
    echo "Stopping monitoring port forwards..."
    PIDS=$(cat /tmp/monitoring-pids.txt)
    for PID in $PIDS; do
        if ps -p $PID > /dev/null; then
            echo "Killing process $PID"
            kill $PID
        fi
    done
    rm /tmp/monitoring-pids.txt
    echo "Port forwarding stopped"
else
    echo "No monitoring processes found"
    
    # Kill by port as a fallback
    echo "Checking for processes on monitoring ports..."
    lsof -ti:9090 | xargs kill -9 2>/dev/null || true
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    echo "Done"
fi