#!/bin/bash

# 🎯 Updated Script for malikslashtec Docker Hub Setup
# Since Docker registry is already correct, we only need to update Git repo and ArgoCD URL

echo "🎉 Great! Your Docker Hub (malikslashtec) is already set up correctly!"
echo "📦 Detected images: airport-service & country-service"
echo ""
echo "🔧 You only need to update 2 things:"
echo ""

# ⚠️  ONLY EDIT THESE 2 VARIABLES:
YOUR_GIT_REPO="https://github.com/malikalaja/slashTEC.git"  # ⚠️  CHANGE THIS TO YOUR ACTUAL REPO
YOUR_ARGOCD_URL="http://localhost:8080"                     # ⚠️  CHANGE THIS TO YOUR ACTUAL ARGOCD URL

echo "📝 Current settings that need to be updated:"
echo "Git repo: ${YOUR_GIT_REPO}"
echo "ArgoCD URL: ${YOUR_ARGOCD_URL}"
echo ""

read -p "✏️  Do you want to update these settings? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Updating Git repository URLs (keeping Docker Hub as malikslashtec)..."
    
    # Only update Git URLs if they're different
    if [[ "$YOUR_GIT_REPO" != "https://github.com/malikalaja/slashTEC.git" ]]; then
        find /home/malik/Desktop/airporttask -type f \( -name "*-pipeline" -o -name "*.yaml" \) \
          -exec sed -i "s|https://github.com/malikalaja/slashTEC.git|${YOUR_GIT_REPO}|g" {} \;
        echo "✅ Git URLs updated"
    else
        echo "ℹ️  Git URL unchanged (already correct or needs manual update)"
    fi
    
    echo "🎯 Updating ArgoCD URL..."
    sed -i "s|https://argocd.slashtec.local|${YOUR_ARGOCD_URL}|g" /home/malik/Desktop/airporttask/jenkins/*-pipeline
    echo "✅ ArgoCD URL updated"
    
    echo ""
    echo "🎊 Configuration updated successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. ✅ Docker Hub: Already working (malikslashtec)"
    echo "2. 🔧 Git repo: ${YOUR_GIT_REPO}"
    echo "3. 🎯 ArgoCD: ${YOUR_ARGOCD_URL}"
    echo "4. 🚀 Deploy ArgoCD: kubectl apply -f argo/"
    echo "5. 🔐 Configure Jenkins credentials"
    
else
    echo "⏸️  Update cancelled. Please manually edit the variables at the top of this script."
fi

echo ""
echo "🔍 Current Docker Hub images (already correct):"
echo "✅ malikslashtec/airport-service"
echo "✅ malikslashtec/country-service"
