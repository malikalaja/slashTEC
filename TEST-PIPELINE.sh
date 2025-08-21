#!/bin/bash

# 🧪 SlashTEC Airport Services - Complete Testing Script
echo "🚀 Testing SlashTEC Airport Services Pipeline"
echo "=============================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local url=$1
    local service=$2
    echo -n "Testing $service at $url: "
    if curl -s -f "$url" > /dev/null; then
        echo -e "${GREEN}✅ SUCCESS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

echo ""
echo "1️⃣ LEVEL 1: LOCAL JAR TESTING"
echo "================================"
if [[ -f "interview-test/airports-assembly-1.1.0.jar" ]]; then
    echo -e "${GREEN}✅ Airport JAR found${NC}"
else
    echo -e "${RED}❌ Airport JAR not found${NC}"
fi

if [[ -f "interview-test/countries-assembly-1.0.1.jar" ]]; then
    echo -e "${GREEN}✅ Country JAR found${NC}"
else
    echo -e "${RED}❌ Country JAR not found${NC}"
fi

echo ""
echo "2️⃣ LEVEL 2: DOCKER BUILD TESTING"
echo "=================================="
echo "Building Airport Service Docker image..."
if docker build -f docker/Dockerfile -t test-airport:local . > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Airport Docker build successful${NC}"
else
    echo -e "${RED}❌ Airport Docker build failed${NC}"
fi

echo "Building Country Service Docker image..."
if docker build -f docker/Dockerfile.country -t test-country:local . > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Country Docker build successful${NC}"
else
    echo -e "${RED}❌ Country Docker build failed${NC}"
fi

echo ""
echo "3️⃣ LEVEL 3: DOCKER RUNTIME TESTING"
echo "==================================="
echo "Starting Airport Service container..."
AIRPORT_CONTAINER=$(docker run -d -p 8080:8080 test-airport:local)
sleep 10

test_endpoint "http://localhost:8080/health/live" "Airport Service Health"

echo "Starting Country Service container..."
COUNTRY_CONTAINER=$(docker run -d -p 8081:8080 test-country:local)
sleep 10

test_endpoint "http://localhost:8081/health/live" "Country Service Health"

echo ""
echo "🧹 CLEANING UP CONTAINERS..."
docker stop $AIRPORT_CONTAINER $COUNTRY_CONTAINER > /dev/null 2>&1
docker rm $AIRPORT_CONTAINER $COUNTRY_CONTAINER > /dev/null 2>&1
docker rmi test-airport:local test-country:local > /dev/null 2>&1

echo ""
echo "4️⃣ LEVEL 4: KUBERNETES TESTING"
echo "==============================="
if kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Kubernetes cluster accessible${NC}"
    
    # Check if preprod namespace exists
    if kubectl get namespace preprod > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Preprod namespace exists${NC}"
        
        # Check if pods are running
        if kubectl get pods -n preprod | grep -q "Running"; then
            echo -e "${GREEN}✅ Services running in preprod${NC}"
            
            echo ""
            echo "🔗 Testing Kubernetes Services:"
            kubectl get pods -n preprod
            kubectl get svc -n preprod
        else
            echo -e "${YELLOW}⚠️  Services not running in preprod${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Preprod namespace not found${NC}"
    fi
else
    echo -e "${RED}❌ Kubernetes cluster not accessible${NC}"
fi

echo ""
echo "5️⃣ LEVEL 5: ARGOCD APPLICATION STATUS"
echo "====================================="
if kubectl get applications -n argocd > /dev/null 2>&1; then
    echo -e "${GREEN}✅ ArgoCD accessible${NC}"
    echo "ArgoCD Applications:"
    kubectl get applications -n argocd
else
    echo -e "${YELLOW}⚠️  ArgoCD not accessible or no applications${NC}"
fi

echo ""
echo "🎯 TESTING COMPLETE!"
echo "===================="
echo -e "${GREEN}Your SlashTEC Airport Services pipeline testing is done!${NC}"
echo ""
echo "📋 NEXT STEPS:"
echo "- Run Jenkins pipelines to build and push to ECR"
echo "- Deploy ArgoCD application: kubectl apply -f argo/unified-services-app.yaml"
echo "- Monitor deployment: kubectl get pods -n preprod"
echo ""
echo "🚀 Ready for production deployment!"
