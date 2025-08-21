# ☁️ Cloud Jenkins - Quick Reference

## 🚀 Pipeline URLs & Paths
```
GitHub Repo: https://github.com/malikalaja/slashTEC.git
Airport Pipeline: jenkins/airport-service-pipeline  
Country Pipeline: jenkins/country-service-pipeline
<<<<<<< HEAD
ECR Registry: ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com
=======
ECR Registry: amazonId.dkr.ecr.regin.amazonaws.com
>>>>>>> 8121d196c7e00c19e383bafff676088fe47d7c5e
ArgoCD App: preprod-airport-services
```

## 🔑 Required Credentials
```
Jenkins Credential ID: aws-ecr-credentials
<<<<<<< HEAD
AWS Account ID: ${AWS_ACCOUNT_ID}
=======
AWS Account ID: ##########
>>>>>>> 8121d196c7e00c19e383bafff676088fe47d7c5e
AWS Region: ap-south-1  
ECR Repositories: airport-service, country-service
```

## 🏗️ Pipeline Configuration Summary

### Airport Service Pipeline
```groovy
Name: airport-service-pipeline
Script Path: jenkins/airport-service-pipeline
Service Name: airport-service
<<<<<<< HEAD
Docker Image: ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/airport-service
=======
Docker Image: amazonId.dkr.ecr.regin.amazonaws.com/airport-service
>>>>>>> 8121d196c7e00c19e383bafff676088fe47d7c5e
```

### Country Service Pipeline  
```groovy
Name: country-service-pipeline
Script Path: jenkins/country-service-pipeline
Service Name: country-service
<<<<<<< HEAD
Docker Image: ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/country-service
=======
Docker Image: amazonId.dkr.ecr.regin.amazonaws.com/country-service
>>>>>>> 8121d196c7e00c19e383bafff676088fe47d7c5e
```

## 📋 Build Parameters
```
BranchName: main (default)
Tag: latest (default)
```

## ✅ Success Indicators
1. **Jenkins Console**: All stages GREEN ✅
2. **ECR**: New image with tag `preprod-{BUILD_NUMBER}`
3. **GitHub**: helm-unified/values.yaml updated automatically
4. **ArgoCD**: Application shows "Synced" + "Healthy"
5. **Kubernetes**: Pods running in `preprod` namespace

## 🔍 Quick Commands for Verification
```bash
# Check ECR images
aws ecr list-images --repository-name airport-service --region ap-south-1

# Check Kubernetes pods
kubectl get pods -n preprod

# Check ArgoCD sync status  
kubectl get application preprod-airport-services -n argocd
```

## 🚨 First Build Checklist
- [ ] AWS credentials configured in Jenkins
- [ ] ECR repositories exist (airport-service, country-service)
- [ ] GitHub repo accessible from Jenkins
- [ ] Pipeline parameters configured
- [ ] ArgoCD application deployed
- [ ] Kubernetes namespace `preprod` exists

---
*Generated for SlashTEC CI/CD Pipeline*
