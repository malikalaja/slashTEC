#!/bin/bash

# Quick Jenkins Test for http://13.203.7.135/
# This tests your specific Jenkins instance

JENKINS_URL="http://13.203.7.135/"
echo "🚀 TESTING YOUR JENKINS: $JENKINS_URL"
echo "================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

echo ""

# Test 1: Basic connectivity
echo "🌐 Test 1: Basic Connectivity"
if curl -s --max-time 10 "$JENKINS_URL" > /dev/null; then
    print_status 0 "Jenkins is accessible at $JENKINS_URL"
else
    print_status 1 "Cannot reach Jenkins at $JENKINS_URL"
    echo "   Check:"
    echo "   - Network connectivity"
    echo "   - VPN requirements"
    echo "   - Security groups/firewall"
    exit 1
fi

echo ""

# Test 2: Check if it's really Jenkins
echo "🔍 Test 2: Jenkins Verification"
RESPONSE=$(curl -s --max-time 10 -I "$JENKINS_URL")
if echo "$RESPONSE" | grep -i "X-Jenkins" > /dev/null; then
    JENKINS_VERSION=$(echo "$RESPONSE" | grep -i "X-Jenkins:" | cut -d' ' -f2 | tr -d '\r')
    print_status 0 "Confirmed Jenkins server (Version: $JENKINS_VERSION)"
elif echo "$RESPONSE" | grep -i "jenkins" > /dev/null; then
    print_status 0 "Confirmed Jenkins server"
else
    print_status 1 "Response doesn't look like Jenkins"
    echo "   First few lines of response:"
    echo "$RESPONSE" | head -3
fi

echo ""

# Test 3: API endpoint
echo "🔌 Test 3: Jenkins API"
API_RESPONSE=$(curl -s --max-time 10 "${JENKINS_URL}api/json" -w "%{http_code}")
HTTP_CODE=${API_RESPONSE: -3}

if [ "$HTTP_CODE" = "200" ]; then
    print_status 0 "Jenkins API is working (HTTP 200)"
    # Extract Jenkins info
    API_DATA=${API_RESPONSE%???}  # Remove HTTP code
    if command -v jq >/dev/null 2>&1; then
        echo "   Jenkins Mode: $(echo "$API_DATA" | jq -r '.mode // "unknown"')"
        echo "   Node Name: $(echo "$API_DATA" | jq -r '.nodeName // "unknown"')"
    fi
elif [ "$HTTP_CODE" = "403" ]; then
    print_status 0 "Jenkins API accessible but requires authentication (HTTP 403)"
elif [ "$HTTP_CODE" = "401" ]; then
    print_info "Jenkins API requires authentication (HTTP 401)"
    echo "   You'll need username and API token to use Jenkins"
else
    print_status 1 "Jenkins API issue (HTTP $HTTP_CODE)"
fi

echo ""

# Test 4: Pipeline compatibility
echo "🏗️  Test 4: Pipeline Compatibility Check"
if [ -f "jenkins/airport-service-pipeline" ] && [ -f "jenkins/country-service-pipeline" ]; then
    print_status 0 "Your pipeline files exist"
    print_info "Airport pipeline: $(wc -l < jenkins/airport-service-pipeline) lines"
    print_info "Country pipeline: $(wc -l < jenkins/country-service-pipeline) lines"
else
    print_status 1 "Pipeline files missing"
fi

echo ""

# Test 5: AWS connectivity (for ECR)
echo "☁️  Test 5: AWS/ECR Connectivity"
if command -v aws >/dev/null 2>&1; then
    print_status 0 "AWS CLI is installed"
    if aws sts get-caller-identity >/dev/null 2>&1; then
        print_status 0 "AWS credentials are configured"
    else
        print_info "AWS credentials may need configuration"
    fi
else
    print_info "AWS CLI not installed (needed for ECR access)"
fi

echo ""
echo "🏁 JENKINS TEST COMPLETE"
echo ""

if curl -s --max-time 5 "$JENKINS_URL" > /dev/null; then
    echo "🎉 SUCCESS! Your Jenkins is accessible!"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "1. Open Jenkins in browser: $JENKINS_URL"
    echo "2. Login with your credentials"
    echo "3. Create new pipeline jobs:"
    echo "   - airport-service-pipeline"
    echo "   - country-service-pipeline"
    echo "4. Copy content from jenkins/ directory"
    echo "5. Configure credentials (AWS, Git, Slack, etc.)"
    echo ""
    echo "📚 HELPFUL COMMANDS:"
    echo "# Test with credentials:"
    echo "./JENKINS-HEALTH-CHECK.sh $JENKINS_URL username token"
    echo ""
    echo "# Full system test:"
    echo "./QUICK-SYSTEM-TEST.sh"
else
    echo "❌ Jenkins is not accessible"
    echo ""
    echo "🔧 TROUBLESHOOTING:"
    echo "1. Check network/VPN connection"
    echo "2. Verify Jenkins is running on server"
    echo "3. Check firewall/security groups"
    echo "4. Try accessing in browser: $JENKINS_URL"
fi

echo ""
echo "📖 Documentation:"
echo "- README.md"
echo "- CLOUD-JENKINS-REFERENCE.md"
echo "- CLOUD-JENKINS-TROUBLESHOOTING.md"
