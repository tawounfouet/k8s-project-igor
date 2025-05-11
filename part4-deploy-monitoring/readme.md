
```sh
3k8s-project/
├── part1-installation/
│   ├── installation_steps.md
│   └── screenshots/
├── part2-multi-env/
│   ├── dev/
│   │   ├── backend.yaml
│   │   ├── frontend.yaml
│   │   ├── mysql.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   └── limitrange.yaml
│   ├── staging/
│   ├── prod/
├── part3-security-access/
│   ├── rbac/
│   ├── network-policies/
│   ├── resource-quotas/
├── part4-deploy-monitoring/
│   ├── hpa/
│   ├── prometheus/
│   ├── grafana/
│   └── nodeport-services/
├── diagrams/
├── scripts/
├── architecture.md
└── presentation.pdf
```

### Partie 4 : Déploiements avancés et monitoring

1. Configurer deux stratégies de déploiement différentes :
    - Rolling update pour l'environnement de production (max 25% indisponible à la fois)
    - Recreate pour l'environnement de développement
2. Mettre en place un HorizontalPodAutoscaler pour le backend en production :
    - Scaling basé sur l'utilisation CPU (> 70%)
    - Minimum 2 pods, maximum 5 pods
    - Créer un script simple pour générer de la charge sur l'API
3. Installer Prometheus et Grafana dans un namespace `monitoring` :
    - Configurer Prometheus pour collecter les métriques des pods et des nodes
    - Créer un tableau de bord Grafana pour visualiser :
        - L'utilisation CPU et mémoire par namespace
        - Le nombre de pods par déploiement
        - Le statut des liveness/readiness probes
        - Les temps de réponse des services
4. Configurer des services NodePort pour exposer les applications frontend :
    - Exposer chaque frontend sur un port différent
    - Documenter comment accéder aux différentes applications
    - Expliquer les différences entre les types de services (ClusterIP, NodePort, LoadBalancer)

**Livrable attendu** : Configuration complète du monitoring, captures d'écran des tableaux de bord, fichiers YAML pour les services NodePort et les HPA, documentation sur les stratégies de déploiement.







### 📁 hpa/
```yaml
# hpa-backend-prod.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### 📁 prometheus/
```yaml
# prometheus-deployment.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: prometheus-config
              mountPath: /etc/prometheus/
      volumes:
        - name: prometheus-config
          configMap:
            name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  type: NodePort
  ports:
    - port: 9090
      nodePort: 30090
  selector:
    app: prometheus
```

```yaml
# prometheus-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
```


### 📁 grafana/
```yaml
# grafana-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana
          image: grafana/grafana
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  ports:
    - port: 3000
      nodePort: 30030
  selector:
    app: grafana
```


### 📁 nodeport-services/
```yaml
# frontend-nodeport-dev.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-dev-nodeport
  namespace: dev
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30001
```

```yaml
# frontend-nodeport-prod.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-prod-nodeport
  namespace: prod
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30002
```



#### Step 1: Create Others Configuration Files

```sh
# Create directory structure if it doesn't exist
mkdir -p part4-deploy-monitoring/{hpa,prometheus,grafana,nodeport-services,deployment-strategies,load-test}

```

**Create Backend Deployment Strategy Files**

```sh
# Prod Deployment with Rolling Update Strategy
cat > part4-deploy-monitoring/deployment-strategies/backend-prod.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: prod
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: backend:latest
          imagePullPolicy: Never
          env:
            - name: DB_HOST
              value: mysql
            - name: DB_USER
              valueFrom:
                configMapKeyRef:
                  name: mysql-config
                  key: MYSQL_USER
            - name: DB_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: mysql-config
                  key: MYSQL_PASSWORD
            - name: DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: mysql-config
                  key: MYSQL_DATABASE
          ports:
            - containerPort: 8000
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 15
            periodSeconds: 10
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
EOF

# Dev Deployment with Recreate Strategy
cat > part4-deploy-monitoring/deployment-strategies/backend-dev.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: dev
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: backend:latest
          imagePullPolicy: Never
          env:
            - name: DB_HOST
              value: mysql
            - name: DB_USER
              valueFrom:
                configMapKeyRef:
                  name: mysql-config
                  key: MYSQL_USER
            - name: DB_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: mysql-config
                  key: MYSQL_PASSWORD
            - name: DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: mysql-config
                  key: MYSQL_DATABASE
          ports:
            - containerPort: 8000
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 15
            periodSeconds: 10
EOF
```

**Create Load Test Script**
```sh
cat > part4-deploy-monitoring/load-test/load-generator.sh << 'EOF'
#!/bin/bash

# Simple load generator for backend API
# Usage: ./load-generator.sh [URL] [REQUESTS] [CONCURRENCY]

URL=${1:-http://$(minikube ip):30001/api}
REQUESTS=${2:-1000}
CONCURRENCY=${3:-10}

echo "Generating load: $REQUESTS requests, $CONCURRENCY concurrent"
echo "Target URL: $URL"

# Install hey if not available
if ! command -v hey &> /dev/null; then
    echo "Installing hey load testing tool..."
    go get -u github.com/rakyll/hey
fi

# Run load test
hey -n $REQUESTS -c $CONCURRENCY $URL

EOF

chmod +x part4-deploy-monitoring/load-test/load-generator.sh
```

### Step 2: Apply Everything in Correct Order
Now let's apply all the configurations in the correct order:

```sh
# 1. Create the monitoring namespace
kubectl create namespace monitoring

# 2. Deploy Prometheus
kubectl apply -f part4-deploy-monitoring/prometheus/prometheus-configmap.yaml
kubectl apply -f part4-deploy-monitoring/prometheus/prometheus-deployment.yaml

# 3. Deploy Grafana
kubectl apply -f part4-deploy-monitoring/grafana/grafana-deployment.yaml

# 4. Apply deployment strategies
kubectl apply -f part4-deploy-monitoring/deployment-strategies/backend-dev.yaml
kubectl apply -f part4-deploy-monitoring/deployment-strategies/backend-prod.yaml

# 5. Configure HPA
kubectl apply -f part4-deploy-monitoring/hpa/hpa-backend-prod.yaml

# 6. Configure NodePort services
kubectl apply -f part4-deploy-monitoring/nodeport-services/frontend-nodeport-dev.yaml
kubectl apply -f part4-deploy-monitoring/nodeport-services/frontend-nodeport-prod.yaml
```

### Step 3: Verify Everything is Running
Check that all components are running:
```sh
# Check Prometheus and Grafana
kubectl get pods -n monitoring
kubectl get services -n monitoring

#  Check Pod Details
kubectl describe pod prometheus-0 -n monitoring
kubectl describe pod grafana-0 -n monitoring

#  Check Service Details
kubectl describe service prometheus -n monitoring
kubectl describe service grafana -n monitoring


# Check NodePort services
kubectl get services -n dev
kubectl get services -n prod

# Check deployments with their strategies
kubectl describe deployment backend -n dev
kubectl describe deployment backend -n dev

# Check HPA
kubectl get hpa -n prod



# 3. Enable Port Forwarding
# For Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# In another terminal, for Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

```

### Step 4: Access the Monitoring Tools
```sh
# Get minikube IP
MINIKUBE_IP=$(minikube ip)

# Access Prometheus
echo "Prometheus available at: http://$MINIKUBE_IP:30090"
# Prometheus available at: http://192.168.49.2:30090
curl -X GET http://$MINIKUBE_IP:30090/metrics

# Access Grafana
echo "Grafana available at: http://$MINIKUBE_IP:30030"
# Default credentials: admin/admin
# Grafana available at: http://192.168.49.2:30030

curl -X GET http://$MINIKUBE_IP:30030

```


### Running Port Forwarding in Detached Mode
To run port forwarding in detached mode (in the background), you can use this script. Save it as start-monitoring.sh in your part4-deploy-monitoring directory:

`start-monitoring.sh` 
```sh
#!/bin/bash
# filepath: /Users/awf/Infrastruture/k8s/k8s-project/part4-deploy-monitoring/start-monitoring.sh

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
```

complementary script to stop the port forwarding when you're done:
`stop-monitoring.sh`
```sh
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
```

Make both scripts executable:

```sh
# chmod +x /Users/awf/Infrastruture/k8s/k8s-project/part4-deploy-monitoring/start-monitoring.sh
# chmod +x /Users/awf/Infrastruture/k8s/k8s-project/part4-deploy-monitoring/stop-monitoring.sh

chmod +x start-monitoring.sh
chmod +x stop-monitoring.sh

# or from the parent directory
chmod +x part4-deploy-monitoring/start-monitoring.sh
chmod +x part4-deploy-monitoring/stop-monitoring.sh
```

#### How to Use
Start monitoring:
```sh
./start-monitoring.sh
```
Stop monitoring:
```sh
./stop-monitoring.sh
```
### Step 5: Generate Load
```sh
# Generate load on the backend API
# Make sure to replace the URL with the correct one
# URL=$(minikube ip):30001/api
# ./load-generator.sh $URL 1000 10
# or
./load-generator.sh http://$(minikube ip):30001/api 1000 10
```


## Detached Port Forwarding

For convenience, you can run port forwarding in detached mode (background):

```bash
# Start port forwarding in background
./start-monitoring.sh

# Access services
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (default: admin/admin)

# When finished, stop port forwarding
./stop-monitoring.sh
```