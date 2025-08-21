# 🔧 Cloud Jenkins Troubleshooting Guide

## 🚨 Common Issues & Solutions

### 1. AWS ECR Login Failed
```
ERROR: Error response from daemon: login attempt failed
```
**Solutions:**
- ✅ Verify AWS credentials in Jenkins → Credentials  
- ✅ Check AWS account ID: ``
- ✅ Confirm region: `region`
- ✅ Test AWS CLI: `aws ecr get-login-password --region ""`

### 2. ECR Repository Not Found
```
ERROR: repository does not exist
```
**Solutions:**
```bash
# Create missing repositories
aws ecr create-repository --repository-name airport-service --region ap-south-1
aws ecr create-repository --repository-name country-service --region ap-south-1
```

### 3. GitHub Repository Access Denied
```
ERROR: Couldn't find any revision to build
```
**Solutions:**
- ✅ Verify repo URL: `https://github.com/malikalaja/slashTEC.git`
- ✅ Check branch name: `main` (not `master`)
- ✅ Add GitHub token to Jenkins credentials (if private repo)

### 4. Pipeline Script Not Found
```
ERROR: Script path jenkins/airport-service-pipeline not found
```  
**Solutions:**
- ✅ Verify exact path: `jenkins/airport-service-pipeline` (no .groovy extension)
- ✅ Check file exists in GitHub repo
- ✅ Confirm branch is `main`

### 5. Docker Build Failed
```
ERROR: unable to prepare context: unable to evaluate symlinks
```
**Solutions:**
- ✅ Check JAR file exists: `interview-test/airports-assembly-1.1.0.jar`
- ✅ Verify Dockerfile path: `docker/Dockerfile`
- ✅ Ensure workspace cleanup worked

### 6. Helm Values Update Failed
```
ERROR: yq: command not found
```
**Solutions:**
- ✅ Install yq on Jenkins agent:
```bash
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
```

### 7. ArgoCD Not Syncing
```
Application stuck in "OutOfSync" status
```
**Solutions:**
- ✅ Check ArgoCD application exists: `preprod-airport-services`
- ✅ Verify source path: `helm-unified`
- ✅ Confirm namespace exists: `preprod`
- ✅ Manual sync in ArgoCD UI

### 8. AppConfig Access Denied
```
ERROR: aws appconfig get-configuration failed
```
**Solutions:**
- ✅ This stage may fail if AppConfig not set up (it's optional)
- ✅ Comment out AppConfig stage if not using AWS AppConfig
- ✅ Or set up AppConfig application: `airport-services`

## 📞 Debug Commands

### Check Jenkins Workspace
```groovy
// Add to pipeline for debugging
sh "pwd"
sh "ls -la"
sh "find . -name '*.jar'"
```

### Verify AWS Access
```groovy
// Add to pipeline
sh "aws sts get-caller-identity"
sh "aws ecr describe-repositories --region ap-south-1"
```

### Check Docker
```groovy  
// Add to pipeline
sh "docker --version"
sh "docker images"
```

## 🎯 Step-by-Step Debug Process

1. **First, check Console Output** in Jenkins build
2. **Identify the failing stage** (red X)
3. **Look for ERROR messages** in logs
4. **Apply solution from above**
5. **Re-run build**
6. **If still failing, add debug commands**

## ⚡ Quick Fixes

### Reset Build
- Delete failed build
- Clean workspace: Build → Workspace → Wipe Out Workspace
- Re-run

### Emergency Pipeline Test
```groovy
// Minimal test pipeline
node {
    stage('Test') {
        sh "echo 'Jenkins is working!'"
        sh "aws --version"
        sh "docker --version"
        checkout scm
        sh "ls -la"
    }
}
```

---
*🔧 Keep this guide handy during your first Jenkins runs!*
