#!/bin/bash

# 🔧 Quick Edit Commands for ArgoCD Integration
# Run these commands after updating the variables below

# ⚠️  EDIT THESE VARIABLES WITH YOUR ACTUAL VALUES:
YOUR_GIT_REPO="https://github.com/YOUR_USERNAME/YOUR_REPO.git"
YOUR_DOCKER_REGISTRY="your-dockerhub-username"  
YOUR_ARGOCD_URL="http://localhost:8080"  # or your actual ArgoCD URL

echo "🔄 Updating Git repository URLs..."
find /home/malik/Desktop/airporttask -type f \( -name "*-pipeline" -o -name "*.yaml" \) \
  -exec sed -i "s|https://github.com/malikalaja/slashTEC.git|${YOUR_GIT_REPO}|g" {} \;

echo "🐳 Updating Docker registry..."  
find /home/malik/Desktop/airporttask -type f \( -name "*-pipeline" -o -name "*.yaml" \) \
  -exec sed -i "s|malikslashtec|${YOUR_DOCKER_REGISTRY}|g" {} \;

echo "🎯 Updating ArgoCD URL..."
sed -i "s|https://argocd.slashtec.local|${YOUR_ARGOCD_URL}|g" /home/malik/Desktop/airporttask/jenkins/*-pipeline

echo "✅ All configurations updated!"

echo "📋 Next steps:"
echo "1. Push these changes to your Git repository"
echo "2. Deploy ArgoCD applications: kubectl apply -f argo/"
echo "3. Configure Jenkins credentials (git, docker, slack)"
echo "4. Test the Jenkins pipeline"

# Verification
echo "🔍 Verification - checking updated values:"
echo "Git repos:"
grep -h "github.com" /home/malik/Desktop/airporttask/jenkins/*-pipeline | head -2
echo "Docker registry:" 
grep -h "registryId" /home/malik/Desktop/airporttask/jenkins/*-pipeline | head -1
echo "ArgoCD URL:"
grep -h "ARGOCD_URL" /home/malik/Desktop/airporttask/jenkins/*-pipeline | head -1
