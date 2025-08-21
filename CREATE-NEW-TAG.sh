#!/bin/bash

# 🏷️ CREATE NEW TAG SCRIPT FOR GITOPS
# Usage: ./CREATE-NEW-TAG.sh [version] [description]
# Example: ./CREATE-NEW-TAG.sh v1.1.0 "Added new feature"

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
VERSION=${1:-"v1.0.1"}
DESCRIPTION=${2:-"Hello world :) - New update"}

echo -e "${BLUE}🏷️ CREATING NEW GITOPS TAG${NC}"
echo "=================================="

# Check if we have uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes. Please commit them first.${NC}"
    git status --short
    exit 1
fi

# Create the tag
echo -e "${BLUE}📋 Creating tag: ${VERSION}${NC}"
git tag -a "${VERSION}" -m "${DESCRIPTION}"

# Push to GitHub
echo -e "${BLUE}🚀 Pushing tag to GitHub...${NC}"
git push origin "${VERSION}"

# Update ArgoCD to use this tag
echo -e "${BLUE}⚙️  Updating ArgoCD configuration...${NC}"
sed -i "s/targetRevision: .*/targetRevision: ${VERSION}/" argo/unified-services-app.yaml

# Commit ArgoCD update
git add argo/unified-services-app.yaml
git commit -m "Hello world :) - Update ArgoCD to ${VERSION}"
git push origin main

echo -e "${GREEN}✅ SUCCESS!${NC}"
echo "=================================="
echo -e "🏷️  Tag created: ${VERSION}"
echo -e "📝  Description: ${DESCRIPTION}"
echo -e "🔄  ArgoCD updated to use: ${VERSION}"
echo -e "🚀  Changes pushed to GitHub"
echo ""
echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
echo "1. ArgoCD will detect the configuration change"
echo "2. ArgoCD will sync to the new tagged version"
echo "3. Your services will be deployed with the tagged version"
echo ""
echo -e "${BLUE}🔍 Check ArgoCD UI to see the deployment progress!${NC}"
