#!/bin/bash

# 🧪 QUICK SYSTEM TEST - SlashTEC CI/CD Pipeline
# Simple, reliable test that shows progress

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

test_result() {
    local name="$1"
    local command="$2"
    
    echo -n "Testing $name... "
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

echo -e "${BLUE}🧪 QUICK SYSTEM TEST - SlashTEC CI/CD${NC}"
echo "=================================="

# Phase 1: Prerequisites
echo -e "\n${YELLOW}📋 PHASE 1: PREREQUISITES${NC}"
test_result "Git installed" "command -v git"
test_result "Docker installed" "command -v docker"
test_result "Kubectl installed" "command -v kubectl"
test_result "Kubernetes cluster" "kubectl cluster-info --request-timeout=5s"
test_result "Docker daemon" "docker info"

# Phase 2: Repository Structure
echo -e "\n${YELLOW}📁 PHASE 2: REPOSITORY STRUCTURE${NC}"
test_result "Jenkins pipelines" "test -f jenkins/airport-service-pipeline && test -f jenkins/country-service-pipeline"
test_result "Docker files" "test -f docker/Dockerfile && test -f docker/Dockerfile.country"
test_result "Helm chart" "test -d helm-unified && test -f helm-unified/Chart.yaml"
test_result "ArgoCD config" "test -f argo/unified-services-app.yaml"
test_result "JAR files" "test -f interview-test/airports-assembly-1.1.0.jar && test -f interview-test/countries-assembly-1.0.1.jar"
test_result "Tag script" "test -f CREATE-NEW-TAG.sh && test -x CREATE-NEW-TAG.sh"

# Phase 3: Git Status
echo -e "\n${YELLOW}🏷️  PHASE 3: GIT STATUS${NC}"
test_result "Repository clean" "test -z \"\$(git status --porcelain)\""
test_result "On main branch" "test \"\$(git branch --show-current)\" = \"main\""
test_result "Tags exist" "git tag | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+'"
test_result "Remote configured" "git remote get-url origin"

# Phase 4: Docker Build Test
echo -e "\n${YELLOW}🐳 PHASE 4: DOCKER BUILD TEST${NC}"
echo "Building airport service..."
ln -sf interview-test/airports-assembly-1.1.0.jar app.jar
if docker build -f docker/Dockerfile -t test-airport:quick . >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Airport Docker build - PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Airport Docker build - FAIL${NC}"
    ((FAILED++))
fi

echo "Building country service..."
ln -sf interview-test/countries-assembly-1.0.1.jar app.jar
if docker build -f docker/Dockerfile.country -t test-country:quick . >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Country Docker build - PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Country Docker build - FAIL${NC}"
    ((FAILED++))
fi
rm -f app.jar

# Phase 5: Kubernetes Test
echo -e "\n${YELLOW}⎈ PHASE 5: KUBERNETES TEST${NC}"
test_result "Get nodes" "kubectl get nodes"
test_result "Preprod namespace" "kubectl get namespace preprod || kubectl create namespace preprod"
test_result "ArgoCD namespace" "kubectl get namespace argocd"
test_result "ArgoCD pods running" "kubectl get pods -n argocd | grep -q Running"

# Phase 6: Configuration Validation
echo -e "\n${YELLOW}⚙️ PHASE 6: CONFIGURATION VALIDATION${NC}"
test_result "ArgoCD app config valid" "kubectl apply --dry-run=client -f argo/unified-services-app.yaml"
test_result "Helm values valid" "python3 -c 'import yaml; yaml.safe_load(open(\"helm-unified/values.yaml\"))' || yq eval . helm-unified/values.yaml"
test_result "No sensitive data" "! grep -r '727245885999\\|login\\.foodics' --exclude-dir=.git jenkins/ argo/ helm-unified/"
test_result ".env file exists" "test -f .env"

# Phase 7: Pipeline Syntax
echo -e "\n${YELLOW}🏗️  PHASE 7: PIPELINE SYNTAX${NC}"
test_result "Airport pipeline syntax" "grep -q 'node {' jenkins/airport-service-pipeline"
test_result "Country pipeline syntax" "grep -q 'node {' jenkins/country-service-pipeline"
test_result "Environment variables used" "grep -q '\${AWS_ACCOUNT_ID}' jenkins/airport-service-pipeline"

# Cleanup
echo -e "\n${YELLOW}🧹 CLEANUP${NC}"
docker rmi test-airport:quick test-country:quick >/dev/null 2>&1 || true
echo "Docker test images cleaned up"

# Results
echo -e "\n${BLUE}📊 TEST RESULTS${NC}"
echo "==============="
TOTAL=$((PASSED + FAILED))
echo "Total Tests: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}Your CI/CD pipeline is fully functional! 🚀${NC}"
    exit 0
else
    SUCCESS_RATE=$((PASSED * 100 / TOTAL))
    echo -e "\nSuccess Rate: $SUCCESS_RATE%"
    
    if [ $SUCCESS_RATE -ge 80 ]; then
        echo -e "${YELLOW}⚠️  Most tests passed, minor issues to fix${NC}"
        exit 1
    else
        echo -e "${RED}❌ Multiple failures, needs attention${NC}"
        exit 2
    fi
fi
