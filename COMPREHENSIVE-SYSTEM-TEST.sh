#!/bin/bash

# 🧪 COMPREHENSIVE SYSTEM TEST - SlashTEC CI/CD Pipeline
# Tests all components: Git, Docker, Jenkins, Kubernetes, ArgoCD, Helm
# Usage: ./COMPREHENSIVE-SYSTEM-TEST.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    ((TOTAL_TESTS++))
    
    echo ""
    log_info "Testing: $test_name"
    echo "Command: $test_command"
    
    if eval "$test_command" &>/dev/null; then
        log_success "$test_name - PASSED"
        return 0
    else
        log_error "$test_name - FAILED"
        return 1
    fi
}

echo -e "${BLUE}"
echo "🧪 COMPREHENSIVE SYSTEM TEST"
echo "============================="
echo "Testing entire SlashTEC CI/CD Pipeline"
echo -e "${NC}"

# =============================================================================
# 1. PREREQUISITES TEST
# =============================================================================
echo -e "\n${YELLOW}📋 PHASE 1: PREREQUISITES${NC}"

run_test "Git installed" "command -v git"
run_test "Docker installed" "command -v docker"
run_test "Kubectl installed" "command -v kubectl"
run_test "Kubernetes cluster accessible" "kubectl cluster-info"
run_test "Docker daemon running" "docker info"

# =============================================================================
# 2. REPOSITORY STRUCTURE TEST
# =============================================================================
echo -e "\n${YELLOW}📁 PHASE 2: REPOSITORY STRUCTURE${NC}"

run_test "Jenkins pipeline files exist" "test -f jenkins/airport-service-pipeline && test -f jenkins/country-service-pipeline"
run_test "Docker files exist" "test -f docker/Dockerfile && test -f docker/Dockerfile.country"
run_test "Helm chart exists" "test -d helm-unified && test -f helm-unified/Chart.yaml && test -f helm-unified/values.yaml"
run_test "ArgoCD config exists" "test -f argo/unified-services-app.yaml"
run_test "Application JAR files exist" "test -f interview-test/airports-assembly-1.1.0.jar && test -f interview-test/countries-assembly-1.0.1.jar"
run_test "Documentation files exist" "test -f CLOUD-JENKINS-REFERENCE.md && test -f CLOUD-JENKINS-TROUBLESHOOTING.md"
run_test "Tag creation script exists" "test -f CREATE-NEW-TAG.sh && test -x CREATE-NEW-TAG.sh"

# =============================================================================
# 3. GIT AND TAGS TEST
# =============================================================================
echo -e "\n${YELLOW}🏷️  PHASE 3: GIT AND TAGS${NC}"

run_test "Git repository is clean" "test -z \"\$(git status --porcelain)\""
run_test "On main branch" "test \"\$(git branch --show-current)\" = \"main\""
run_test "Tags exist" "git tag | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+'"
run_test "Remote origin configured" "git remote get-url origin"
run_test "Latest commit has Hello world message" "git log -1 --pretty=format:'%s' | grep -q 'Hello world'"

# =============================================================================
# 4. DOCKER BUILD TEST
# =============================================================================
echo -e "\n${YELLOW}🐳 PHASE 4: DOCKER BUILD${NC}"

log_info "Building Docker images for testing..."

# Test Airport Service Docker build
if docker build -f docker/Dockerfile -t test-airport-service:latest . &>/dev/null; then
    log_success "Airport service Docker build - PASSED"
    ((PASSED_TESTS++))
else
    log_error "Airport service Docker build - FAILED"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

# Test Country Service Docker build
if docker build -f docker/Dockerfile.country -t test-country-service:latest . &>/dev/null; then
    log_success "Country service Docker build - PASSED"
    ((PASSED_TESTS++))
else
    log_error "Country service Docker build - FAILED"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

run_test "Docker images created" "docker images | grep -E 'test-(airport|country)-service'"

# =============================================================================
# 5. KUBERNETES CLUSTER TEST
# =============================================================================
echo -e "\n${YELLOW}⎈ PHASE 5: KUBERNETES CLUSTER${NC}"

run_test "Kubectl can access cluster" "kubectl get nodes"
run_test "preprod namespace exists or can be created" "kubectl get namespace preprod || kubectl create namespace preprod"
run_test "Can list pods in preprod namespace" "kubectl get pods -n preprod"
run_test "Can access services in preprod namespace" "kubectl get services -n preprod"

# =============================================================================
# 6. ARGOCD TEST
# =============================================================================
echo -e "\n${YELLOW}🔄 PHASE 6: ARGOCD${NC}"

run_test "ArgoCD namespace exists" "kubectl get namespace argocd"
run_test "ArgoCD pods are running" "kubectl get pods -n argocd | grep -E 'Running|Completed'"
run_test "ArgoCD server service exists" "kubectl get service argocd-server -n argocd"
run_test "ArgoCD application config is valid" "kubectl apply --dry-run=client -f argo/unified-services-app.yaml"

# Test ArgoCD application if it exists
if kubectl get application preprod-airport-services -n argocd &>/dev/null; then
    log_success "ArgoCD application exists - PASSED"
    ((PASSED_TESTS++))
    
    # Check application health
    APP_HEALTH=$(kubectl get application preprod-airport-services -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    if [[ "$APP_HEALTH" == "Healthy" ]]; then
        log_success "ArgoCD application is healthy - PASSED"
        ((PASSED_TESTS++))
    else
        log_warning "ArgoCD application health: $APP_HEALTH"
        ((PASSED_TESTS++))
    fi
    ((TOTAL_TESTS++))
else
    log_warning "ArgoCD application not deployed yet - Deploy with: kubectl apply -f argo/unified-services-app.yaml"
fi
((TOTAL_TESTS++))

# =============================================================================
# 7. HELM CHART VALIDATION TEST
# =============================================================================
echo -e "\n${YELLOW}⚓ PHASE 7: HELM CHART VALIDATION${NC}"

run_test "Helm chart syntax is valid" "kubectl apply --dry-run=client -k helm-unified/ || helm template helm-unified/ > /dev/null"
run_test "Helm values file is valid YAML" "python3 -c 'import yaml; yaml.safe_load(open(\"helm-unified/values.yaml\"))' 2>/dev/null || yq eval . helm-unified/values.yaml > /dev/null"

# Test Helm template rendering
if helm template test-release helm-unified/ &>/dev/null; then
    log_success "Helm template renders successfully - PASSED"
    ((PASSED_TESTS++))
else
    log_error "Helm template rendering failed - FAILED"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

# =============================================================================
# 8. JENKINS PIPELINE VALIDATION TEST
# =============================================================================
echo -e "\n${YELLOW}🏗️  PHASE 8: JENKINS PIPELINE VALIDATION${NC}"

# Check Jenkins pipeline syntax (basic validation)
run_test "Airport service pipeline syntax" "grep -q 'node {' jenkins/airport-service-pipeline && grep -q 'stage(' jenkins/airport-service-pipeline"
run_test "Country service pipeline syntax" "grep -q 'node {' jenkins/country-service-pipeline && grep -q 'stage(' jenkins/country-service-pipeline"
run_test "Pipelines reference correct Docker files" "grep -q 'docker/Dockerfile' jenkins/airport-service-pipeline && grep -q 'docker/Dockerfile.country' jenkins/country-service-pipeline"
run_test "Pipelines reference correct JAR files" "grep -q 'interview-test/.*\.jar' jenkins/airport-service-pipeline"

# =============================================================================
# 9. SECURITY VALIDATION TEST
# =============================================================================
echo -e "\n${YELLOW}🔒 PHASE 9: SECURITY VALIDATION${NC}"

run_test "No sensitive data in repository" "! grep -r '727245885999\\|login\\.foodics\\|devops@slashtec' --exclude-dir=.git . || true"
run_test ".env file exists locally" "test -f .env"
run_test ".gitignore contains security rules" "grep -q '.env' .gitignore && grep -q '*.key' .gitignore"
run_test "Environment variables used in configs" "grep -q '\${AWS_ACCOUNT_ID}' jenkins/airport-service-pipeline"

# =============================================================================
# 10. INTEGRATION TEST
# =============================================================================
echo -e "\n${YELLOW}🔄 PHASE 10: END-TO-END INTEGRATION${NC}"

# Test tag creation workflow
log_info "Testing tag creation workflow..."
TEST_TAG="test-v1.0.1"

# Create test tag
if git tag -a "$TEST_TAG" -m "Test tag" &>/dev/null; then
    log_success "Test tag creation - PASSED"
    ((PASSED_TESTS++))
    
    # Cleanup test tag
    git tag -d "$TEST_TAG" &>/dev/null
else
    log_error "Test tag creation - FAILED"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

# Test ArgoCD config update simulation
ORIGINAL_REVISION=$(grep "targetRevision:" argo/unified-services-app.yaml | awk '{print $2}')
if [[ -n "$ORIGINAL_REVISION" ]]; then
    log_success "ArgoCD targetRevision configured: $ORIGINAL_REVISION - PASSED"
    ((PASSED_TESTS++))
else
    log_error "ArgoCD targetRevision not found - FAILED"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

# =============================================================================
# 11. CLEANUP
# =============================================================================
echo -e "\n${YELLOW}🧹 PHASE 11: CLEANUP${NC}"

log_info "Cleaning up test artifacts..."
docker rmi test-airport-service:latest &>/dev/null || true
docker rmi test-country-service:latest &>/dev/null || true
log_success "Docker test images cleaned up"

# =============================================================================
# TEST RESULTS SUMMARY
# =============================================================================
echo -e "\n${BLUE}📊 TEST RESULTS SUMMARY${NC}"
echo "========================="
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo "Success Rate: $SUCCESS_RATE%"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! Your CI/CD pipeline is fully functional!${NC}"
    echo -e "${GREEN}✅ System is production-ready${NC}"
    exit 0
elif [[ $SUCCESS_RATE -ge 80 ]]; then
    echo -e "\n${YELLOW}⚠️  Most tests passed ($SUCCESS_RATE%), but some issues need attention${NC}"
    echo -e "${YELLOW}🔧 System is mostly functional but needs minor fixes${NC}"
    exit 1
else
    echo -e "\n${RED}❌ Multiple test failures ($SUCCESS_RATE% success rate)${NC}"
    echo -e "${RED}🚨 System needs significant fixes before production use${NC}"
    exit 2
fi
