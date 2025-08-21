# SlashTEC Airport Services - CI/CD Pipeline

A production-ready GitOps CI/CD pipeline for Airport and Country microservices using Jenkins, ArgoCD, Helm, and Kubernetes.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🚀 Overview

This project demonstrates a complete GitOps CI/CD pipeline with:

- **2 Microservices**: Airport Service (port 8000) & Country Service (port 8001)
- **GitOps Workflow**: Git → ArgoCD → Kubernetes
- **CI/CD Pipeline**: Jenkins builds → Docker images → Auto-deployment
- **Infrastructure**: Kubernetes, Helm, ArgoCD, Docker
- **Security**: Environment variables, non-root containers, resource limits

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │───▶│   Jenkins   │───▶│ Docker Hub  │
│  (Source)   │    │   (Build)   │    │ (Registry)  │
└─────────────┘    └─────────────┘    └─────────────┘
       │                                      │
       │                                      │
       ▼                                      ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   ArgoCD    │───▶│ Kubernetes  │───▶│  Services   │
│  (Deploy)   │    │ (Orchestrate)│    │ (Running)   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## ✅ Prerequisites

### Required Software
- **Docker** (20.10+)
- **Kubernetes** (minikube/kind/k3s or cloud cluster)
- **kubectl** (latest)
- **Helm** (3.0+)
- **Git** (2.0+)

### Required Accounts
- **Docker Hub** account (for image registry)
- **GitHub** account (for code repository)
- **Jenkins** server (cloud or local)

### System Requirements
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: 20GB free space
- **CPU**: 2 cores minimum, 4 cores recommended

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/malikalaja/slashTEC.git
cd slashTEC
```

### 2. Start Kubernetes Cluster
```bash
# Using minikube
minikube start --driver=docker --disk-size=40g --memory=4096 --cpus=2

# Verify cluster
kubectl get nodes
```

### 3. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 4. Create Application Namespace
```bash
kubectl create namespace preprod
```

### 5. Deploy ArgoCD Application
```bash
kubectl apply -f argo/unified-services-app.yaml
```

### 6. Access ArgoCD UI
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
# Username: admin
# Password: (from step above)
```

### 7. Build and Push Images (Optional - for testing)
```bash
# Build images
docker build -t YOUR_DOCKERHUB/airport-service:latest -f docker/Dockerfile .
docker build -t YOUR_DOCKERHUB/country-service:latest -f docker/Dockerfile.country .

# Push to registry
docker login
docker push YOUR_DOCKERHUB/airport-service:latest
docker push YOUR_DOCKERHUB/country-service:latest
```

## 🔧 Detailed Setup

### Environment Configuration

1. **Create `.env` file** (never commit to Git):
```bash
# AWS Configuration (if using ECR)
AWS_ACCOUNT_ID=your-account-id
AWS_REGION=us-west-2

# Docker Hub Configuration
DOCKER_REGISTRY=your-dockerhub-username

# ArgoCD Configuration  
ARGOCD_SERVER_URL=https://your-argocd-server.com
```

2. **Update Helm values** in `helm-unified/values.yaml`:
```yaml
airportService:
  image:
    repository: YOUR_DOCKERHUB/airport-service
    tag: "your-tag"

countryService:
  image:
    repository: YOUR_DOCKERHUB/country-service  
    tag: "your-tag"
```

### Jenkins Pipeline Setup

1. **Import Pipeline Jobs**:
   - `jenkins/airport-service-pipeline`
   - `jenkins/country-service-pipeline`

2. **Configure Jenkins Credentials**:
   - Docker Hub credentials
   - AWS credentials (if using ECR)
   - GitHub access token

3. **Run Pipelines** to build and deploy automatically

## 📖 Usage

### Manual Sync with ArgoCD CLI

1. **Install ArgoCD CLI**:
```bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
```

2. **Login and Sync**:
```bash
# Port forward (if not already running)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Login
argocd login localhost:8080 --username admin --password YOUR_PASSWORD --insecure

# Sync application
argocd app sync preprod-airport-services
```

### Access Services

1. **Get Service URLs**:
```bash
# Check NodePort services
kubectl get svc -n preprod

# Access via NodePort
minikube ip  # Get cluster IP
# Airport Service: http://CLUSTER_IP:30618
# Country Service: http://CLUSTER_IP:30619
```

2. **Port Forward (Alternative)**:
```bash
# Airport Service
kubectl port-forward svc/airport-service -n preprod 8000:8000

# Country Service  
kubectl port-forward svc/country-service -n preprod 8001:8001
```

### Version Management

1. **Create New Release**:
```bash
# Use the provided script
./CREATE-NEW-TAG.sh

# Or manually
git tag v1.1.0
git push origin v1.1.0
```

2. **Update ArgoCD Target**:
```bash
# Update argo/unified-services-app.yaml
kubectl patch application preprod-airport-services -n argocd --type='merge' \
  -p='{"spec":{"source":{"targetRevision":"v1.1.0"}}}'
```

## 🧪 Testing

### System Health Check
```bash
# Run comprehensive test
./QUICK-SYSTEM-TEST.sh

# Check individual components
kubectl get pods -n preprod
kubectl get application -n argocd
kubectl get all -n preprod
```

### Service Health Checks
```bash
# Check service endpoints
curl http://CLUSTER_IP:30618/health/live  # Airport Service
curl http://CLUSTER_IP:30619/health/live  # Country Service
```

## 🐛 Troubleshooting

### Common Issues

#### 1. ImagePullBackOff Error
**Symptom**: Pods stuck in `ImagePullBackOff`
**Cause**: Docker images don't exist in registry
**Solution**:
```bash
# Build and push images manually
docker build -t your-registry/airport-service:tag -f docker/Dockerfile .
docker push your-registry/airport-service:tag

# Or run Jenkins pipeline to build automatically
```

#### 2. ArgoCD Sync Failed
**Symptom**: Application shows "OutOfSync" or "Failed"
**Cause**: Resource conflicts or incorrect configuration
**Solution**:
```bash
# Force refresh and sync
argocd app sync preprod-airport-services --force

# Check application details
argocd app get preprod-airport-services
```

#### 3. Namespace Issues
**Symptom**: Resources deployed to wrong namespace
**Cause**: Hardcoded namespaces in templates
**Solution**: Verify `argo/unified-services-app.yaml` has correct destination namespace

#### 4. Disk Space Issues (Minikube)
**Symptom**: `no space left on device`
**Solution**:
```bash
minikube delete
minikube start --disk-size=40g --memory=4096
```

### Helpful Commands

```bash
# Check all resources
kubectl get all --all-namespaces

# ArgoCD application status
kubectl get application -n argocd

# Check events for troubleshooting
kubectl get events -n preprod --sort-by='.lastTimestamp'

# View pod logs
kubectl logs -n preprod deployment/airport-service
kubectl logs -n preprod deployment/country-service

# Clean restart
kubectl rollout restart deployment/airport-service -n preprod
kubectl rollout restart deployment/country-service -n preprod
```

## 📚 Reference Documentation

- **Cloud Jenkins Setup**: `CLOUD-JENKINS-REFERENCE.md`
- **Troubleshooting Guide**: `CLOUD-JENKINS-TROUBLESHOOTING.md`
- **System Testing**: Run `./QUICK-SYSTEM-TEST.sh`

## 🔒 Security

- **Environment Variables**: Use `.env` file (excluded from Git)
- **Image Security**: Non-root user, minimal base images
- **Resource Limits**: Memory and CPU limits configured
- **Network Security**: Services exposed via NodePort (customize as needed)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📞 Support

For issues and questions:
- Check troubleshooting section above
- Review logs: `kubectl logs -n preprod <pod-name>`
- Run system test: `./QUICK-SYSTEM-TEST.sh`
- Check ArgoCD UI: `https://localhost:8080`

---

## 🎯 Quick Command Reference

| Task | Command |
|------|---------|
| Start minikube | `minikube start --disk-size=40g --memory=4096` |
| Install ArgoCD | `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml` |
| Get ArgoCD password | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |
| Deploy application | `kubectl apply -f argo/unified-services-app.yaml` |
| Check pods | `kubectl get pods -n preprod` |
| System test | `./QUICK-SYSTEM-TEST.sh` |
| Port forward ArgoCD | `kubectl port-forward svc/argocd-server -n argocd 8080:443` |
| Access services | `minikube ip` then visit `IP:30618` and `IP:30619` |

---

**🚀 Ready to deploy? Your GitOps pipeline awaits!** 
