# 📝 My ArgoCD Configuration Template

## ✏️ **Fill in YOUR actual values here, then use them to update the files:**

### 🌐 **Your Git Repository**
```bash
# Replace: https://github.com/malikalaja/slashTEC.git
# With:    (fill in below)

MY_GIT_REPO="https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"

# Examples:
# MY_GIT_REPO="https://github.com/john/airport-project.git"
# MY_GIT_REPO="git@github.com:company/slashtec.git"
```

### 🐳 **Your Docker Registry**
```bash  
# Replace: malikslashtec
# With:    (fill in below)

MY_DOCKER_REGISTRY="your-registry-name"

# Examples:
# MY_DOCKER_REGISTRY="johndoe"           # Docker Hub
# MY_DOCKER_REGISTRY="123456.dkr.ecr.us-east-1.amazonaws.com"  # AWS ECR
# MY_DOCKER_REGISTRY="gcr.io/my-project" # Google Container Registry
```

### 🎯 **Your ArgoCD Server URL**
```bash
# Replace: https://argocd.slashtec.local  
# With:    (fill in below)

MY_ARGOCD_URL="your-argocd-server-url"

# Examples:
# MY_ARGOCD_URL="http://localhost:8080"              # Local port-forward
# MY_ARGOCD_URL="http://192.168.1.100:30080"        # NodePort
# MY_ARGOCD_URL="https://argocd.mycompany.com"      # Ingress/LoadBalancer
```

### 🏷️ **Your Kubernetes Namespace** (Optional)
```bash
# Current: drone
# Change to: (fill in if different)

MY_NAMESPACE="drone"  # or "production", "staging", etc.
```

---

## 🚀 **Quick Setup Steps:**

### **Step 1: Edit Values Above ⬆️**
Fill in your actual values in the sections above.

### **Step 2: Run Auto-Update Script**
```bash  
# Edit the script with your values:
nano QUICK-EDIT-COMMANDS.sh

# Update the variables at the top:
YOUR_GIT_REPO="your-actual-repo-url"
YOUR_DOCKER_REGISTRY="your-docker-username"
YOUR_ARGOCD_URL="your-argocd-url"

# Run the script:
./QUICK-EDIT-COMMANDS.sh
```

### **Step 3: Manual Verification**
Check a few key files to make sure values were updated:
```bash
# Check Jenkins pipeline:
head -15 jenkins/airport-service-pipeline

# Check ArgoCD config:
head -20 argo/unified-services-app.yaml

# Check Helm values:
head -15 helm-unified/values.yaml
```

### **Step 4: Deploy to ArgoCD**
```bash
# Apply the ArgoCD configurations:
kubectl apply -f argo/argocd-project.yaml
kubectl apply -f argo/unified-services-app.yaml

# Check if applications are created:
kubectl get applications -n argocd
```

### **Step 5: Test Connection**
```bash
# Test if ArgoCD can reach your repo:
argocd repo list

# Check application status:
argocd app get slashtec-airport-services
```

---

## 🔧 **Jenkins Credentials Setup**

You'll also need to configure these in Jenkins (Manage Jenkins → Credentials):

### **1. Git Credentials** (`git-credentials`)
```
Kind: Username with password
Username: your-github-username
Password: your-personal-access-token  # NOT your GitHub password!
```

### **2. Docker Credentials** (`dockerhub-credentials`)
```
Kind: Username with password  
Username: your-docker-registry-username
Password: your-docker-registry-password/token
```

### **3. Slack Webhook** (`slack-webhook`) - Optional
```
Kind: Secret text
Secret: your-slack-webhook-url
```

---

## ✅ **Verification Checklist**

- [ ] Git repository URLs updated in all files
- [ ] Docker registry name updated in all files  
- [ ] ArgoCD server URL updated in Jenkins pipelines
- [ ] ArgoCD project and application deployed successfully
- [ ] Jenkins credentials configured
- [ ] Test Jenkins pipeline run (should push image and update Helm)
- [ ] ArgoCD sync triggered automatically after Jenkins commit
- [ ] Services deployed to Kubernetes cluster

---

## 🐛 **Troubleshooting**

### **ArgoCD shows "Repository not accessible"**
```bash
# Add your repository with credentials:
argocd repo add YOUR_REPO_URL --username YOUR_USER --password YOUR_TOKEN
```

### **Jenkins can't push to Git**  
```bash  
# Make sure you're using a Personal Access Token, not password
# GitHub → Settings → Developer settings → Personal access tokens
```

### **Docker push fails**
```bash
# Test Docker registry login:
echo "YOUR_DOCKER_PASSWORD" | docker login --username YOUR_USER --password-stdin
```

**🎯 Once you fill in your values and run the updates, everything will be connected!**
