# 3k8S Project: Infrastructure Web Multi-Environnements avec Kubernetes


## Table des matières
- Introduction
- Architecture Globale
- Partie 1: Installation et Configuration du Cluster
- Partie 2: Architecture Multi-Environnements
- Partie 3: Sécurité et Contrôle d'Accès
- Partie 4: Déploiements Avancés et Monitoring
- Difficultés Rencontrées et Solutions
- Perspectives d'Amélioration
- Conclusion

### Introduction
Ce document présente la mise en œuvre d'une infrastructure Kubernetes complète pour déployer une application web multi-tiers (frontend, backend, base de données) dans trois environnements isolés (développement, staging, production). Le projet répond aux besoins de TechSolutions pour moderniser son infrastructure en adoptant les principes DevOps et l'orchestration de conteneurs.


### Architecture Globale
L'architecture globale du projet est divisée en plusieurs parties, chacune correspondant à une étape clé de la mise en œuvre. Voici un aperçu de l'architecture :


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


```

L'architecture se compose de:
- Cluster Kubernetes: Implémenté avec Minikube pour simuler un environnement de production
- Trois namespaces isolés: `dev`, `staging`, et `prod` avec des ressources et configurations spécifiques
- Composants d'application:
    - Frontend (interface utilisateur)
    - Backend (API REST)
    - Base de données (MySQL/MariaDB)
- Sécurité: RBAC, NetworkPolicies, et ResourceQuotas
- Monitoring: Prometheus et Grafana pour la surveillance des métriques