#!/bin/bash

# 🚀 Script to switch from Docker Hub to your existing AWS ECR
# Replace YOUR_AWS_ACCOUNT_ID and YOUR_ECR_REPOSITORIES with your actual values

echo "🔧 Switching SlashTEC Airport Services to your existing AWS ECR..."

AWS_ACCOUNT_ID="727245885999"
AWS_REGION="ap-south-1"

# Your existing ECR repository names (update these)
AIRPORT_ECR_REPO="YOUR_EXISTING_AIRPORT_REPO"  # e.g., "my-airport-service" 
COUNTRY_ECR_REPO="YOUR_EXISTING_COUNTRY_REPO"  # e.g., "my-country-service"

# Backup current files
cp jenkins/airport-service-pipeline jenkins/airport-service-pipeline.dockerhub.backup
cp jenkins/country-service-pipeline jenkins/country-service-pipeline.dockerhub.backup
cp argo/unified-services-app.yaml argo/unified-services-app.yaml.dockerhub.backup

echo "✅ Backed up current Docker Hub configuration"

# Update Jenkins pipelines to use ECR
sed -i "s/registryId     = \"malikslashtec\"/registryId     = \"${AWS_ACCOUNT_ID}\"/" jenkins/airport-service-pipeline
sed -i "s/ecrUrl         = \"index.docker.io\/v1\/\"/ecrUrl         = \"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com\"/" jenkins/airport-service-pipeline

sed -i "s/registryId     = \"malikslashtec\"/registryId     = \"${AWS_ACCOUNT_ID}\"/" jenkins/country-service-pipeline
sed -i "s/ecrUrl         = \"index.docker.io\/v1\/\"/ecrUrl         = \"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com\"/" jenkins/country-service-pipeline

echo "✅ Updated Jenkins pipelines for ECR"

# Update Helm values to use your existing ECR repositories
sed -i "s/repository: malikslashtec\/airport-service/repository: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com\/${AIRPORT_ECR_REPO}/" helm-unified/values.yaml
sed -i "s/repository: malikslashtec\/country-service/repository: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com\/${COUNTRY_ECR_REPO}/" helm-unified/values.yaml

echo "✅ Updated ArgoCD application to use your existing ECR repositories"

echo ""
echo "🎯 NEXT STEPS TO USE YOUR EXISTING ECR:"
echo "1. Edit this script and replace:"
echo "   - YOUR_AWS_ACCOUNT_ID with your actual AWS account ID"
echo "   - YOUR_EXISTING_AIRPORT_REPO with your airport service ECR repo name"
echo "   - YOUR_EXISTING_COUNTRY_REPO with your country service ECR repo name"
echo "2. Run: ./SWITCH-TO-ECR.sh"
echo "3. Optional - Create EKS cluster if needed:"
echo "   eksctl create cluster --name slashtec-cluster --region ${AWS_REGION}"
echo "4. Deploy with Jenkins → Your ECR → EKS!"
echo ""
echo "✅ Using your existing ECR - no new repositories needed!"
echo "🚀 No more minikube volume issues with EKS!"
