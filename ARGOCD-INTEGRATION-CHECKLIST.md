# 🔗 ArgoCD Integration Checklist

## 🎯 **Files You MUST Edit to Connect Jenkins → ArgoCD**

### 📁 **1. Jenkins Pipeline Configuration**

#### **File**: `jenkins/airport-service-pipeline` (Lines 4-11)
```groovy
# EDIT THESE VALUES:
def branchName     = params.BranchName ?: "main"
def gitUrl         = "YOUR_ACTUAL_GIT_REPO_URL_HERE"           # ⚠️  CHANGE THIS
def gitUrlCode     = "YOUR_ACTUAL_GIT_REPO_URL_HERE"           # ⚠️  CHANGE THIS  
def serviceName    = params.ServiceName ?: "airport-service"
def EnvName        = params.Environment ?: "production"
def registryId     = "YOUR_DOCKER_REGISTRY_HERE"               # ⚠️  CHANGE THIS
def awsRegion      = "us-east-1"
def ecrUrl         = "index.docker.io/v1/"                     # OR your ECR URL
def dockerfile     = "docker/Dockerfile"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = "YOUR_ARGOCD_SERVER_URL_HERE"             # ⚠️  CHANGE THIS
```

#### **File**: `jenkins/country-service-pipeline` (Lines 4-11)
```groovy
# EDIT THESE VALUES:
def branchName     = params.BranchName ?: "main"
def gitUrl         = "YOUR_ACTUAL_GIT_REPO_URL_HERE"           # ⚠️  CHANGE THIS
def gitUrlCode     = "YOUR_ACTUAL_GIT_REPO_URL_HERE"           # ⚠️  CHANGE THIS
def serviceName    = "country-service"
def EnvName        = params.Environment ?: "production"
def registryId     = "YOUR_DOCKER_REGISTRY_HERE"               # ⚠️  CHANGE THIS
def awsRegion      = "us-east-1"
def ecrUrl         = "index.docker.io/v1/"
def dockerfile     = "docker/Dockerfile.country"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = "YOUR_ARGOCD_SERVER_URL_HERE"             # ⚠️  CHANGE THIS
```

### 📁 **2. ArgoCD Application Configuration**

#### **File**: `argo/unified-services-app.yaml` (Line 18)
```yaml
source:
  repoURL: YOUR_ACTUAL_GIT_REPO_URL_HERE              # ⚠️  CHANGE THIS
  path: helm-unified
  targetRevision: main
```

#### **File**: `argo/argocd-project.yaml` (Line 13)
```yaml
sourceRepos:
  - YOUR_ACTUAL_GIT_REPO_URL_HERE                     # ⚠️  CHANGE THIS
  - https://charts.helm.sh/stable
```

### 📁 **3. Docker Registry Configuration**

#### **File**: `argo/unified-services-app.yaml` (Lines 26-32)
```yaml
parameters:
  - name: airportService.image.repository
    value: YOUR_DOCKER_REGISTRY/airport-service       # ⚠️  CHANGE THIS
  - name: countryService.image.repository  
    value: YOUR_DOCKER_REGISTRY/country-service       # ⚠️  CHANGE THIS
```

#### **File**: `helm-unified/values.yaml` (Lines 5-10)
```yaml
airportService:
  image:
    repository: YOUR_DOCKER_REGISTRY/airport-service  # ⚠️  CHANGE THIS
countryService:
  image:
    repository: YOUR_DOCKER_REGISTRY/country-service  # ⚠️  CHANGE THIS
```

## 🔧 **What to Replace With:**

### 🌐 **Git Repository URLs**
Replace `https://github.com/malikalaja/slashTEC.git` with:
```bash
# If using HTTPS:
https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# If using SSH:  
git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git
```

### 🐳 **Docker Registry**
Replace `malikslashtec` with:
```bash
# Docker Hub:
your-dockerhub-username

# AWS ECR:
123456789012.dkr.ecr.us-west-2.amazonaws.com

# Google GCR:
gcr.io/your-project-id

# Azure ACR:
yourregistry.azurecr.io
```

### 🎯 **ArgoCD Server URL**
Replace `https://argocd.slashtec.local` with:
```bash
# Local ArgoCD:
http://localhost:8080

# Kubernetes NodePort:
http://YOUR_NODE_IP:30080  

# LoadBalancer/Ingress:
https://argocd.yourdomain.com

# Port-forward:
http://localhost:8080
```

### 🏗️ **Kubernetes Cluster**
If using different cluster, update in `argo/unified-services-app.yaml`:
```yaml
destination:
  server: YOUR_KUBERNETES_CLUSTER_URL               # ⚠️  Usually keep as-is
  namespace: drone                                  # ⚠️  Or your target namespace
```

## 📋 **Step-by-Step Setup:**

### **Step 1: Update Git Repository References**
```bash
# Find and replace in all files:
find . -type f -name "*.yaml" -o -name "*-pipeline" | \
  xargs sed -i 's|https://github.com/malikalaja/slashTEC.git|YOUR_REPO_URL|g'
```

### **Step 2: Update Docker Registry**  
```bash  
# Find and replace registry:
find . -type f -name "*.yaml" -o -name "*-pipeline" | \
  xargs sed -i 's|malikslashtec|YOUR_REGISTRY|g'
```

### **Step 3: Update ArgoCD Server URL**
```bash
# Edit Jenkins pipeline files:
sed -i 's|https://argocd.slashtec.local|YOUR_ARGOCD_URL|g' jenkins/*-pipeline
```

### **Step 4: Deploy ArgoCD Applications**
```bash
# Apply ArgoCD configurations:
kubectl apply -f argo/argocd-project.yaml
kubectl apply -f argo/unified-services-app.yaml
```

### **Step 5: Verify Connections**
```bash
# Check ArgoCD applications:
kubectl get applications -n argocd

# Check if ArgoCD can access your repo:
argocd repo list

# Verify Docker registry access:
docker login YOUR_REGISTRY
```

## 🔐 **Required Credentials Setup:**

### **Jenkins Credentials** (Manage Jenkins → Credentials)
1. **`git-credentials`** → Your Git username/token
2. **`dockerhub-credentials`** → Your Docker registry username/password  
3. **`slack-webhook`** → Your Slack webhook URL (optional)

### **ArgoCD Repository Access**
```bash
# Add your repository to ArgoCD:
argocd repo add YOUR_REPO_URL --username YOUR_USERNAME --password YOUR_TOKEN
```

## ✅ **Verification Checklist:**

- [ ] Git repository URLs updated in all files
- [ ] Docker registry references updated
- [ ] ArgoCD server URL configured in Jenkins
- [ ] Jenkins credentials configured
- [ ] ArgoCD project and application deployed
- [ ] Repository access verified in ArgoCD UI
- [ ] Test pipeline run successful
- [ ] ArgoCD sync working after Jenkins commit

## 🚨 **Common Issues & Solutions:**

### **ArgoCD Can't Access Repository**
```bash
# Solution: Add repository with credentials
argocd repo add YOUR_REPO --username USER --password TOKEN
```

### **Jenkins Can't Push to Git**
```bash
# Solution: Check git-credentials in Jenkins
# Use personal access token, not password
```

### **Docker Push Fails**
```bash
# Solution: Verify Docker registry credentials
docker login YOUR_REGISTRY
```

### **ArgoCD Not Syncing**
```bash
# Solution: Check application status
kubectl describe application slashtec-airport-services -n argocd
```

---

## 🎯 **Quick Start Example:**

If using GitHub + Docker Hub + Local ArgoCD:

```bash
# 1. Replace git URLs
sed -i 's|malikalaja/slashTEC|yourusername/yourrepo|g' argo/*.yaml jenkins/*-pipeline

# 2. Replace Docker registry
sed -i 's|malikslashtec|yourdockerhub|g' argo/*.yaml jenkins/*-pipeline helm-unified/values.yaml

# 3. Update ArgoCD URL  
sed -i 's|https://argocd.slashtec.local|http://localhost:8080|g' jenkins/*-pipeline

# 4. Deploy to ArgoCD
kubectl apply -f argo/
```

**🎉 That's it! Your Jenkins pipelines are now properly linked with ArgoCD!**
