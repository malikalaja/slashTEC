#!/bin/bash

# Jenkins Health Check Script
# Usage: ./JENKINS-HEALTH-CHECK.sh [JENKINS_URL] [USERNAME] [TOKEN]

echo "🔍 JENKINS HEALTH CHECK"
echo "======================="

# Configuration
JENKINS_URL=${1:-"http://localhost:8080"}
JENKINS_USER=${2:-""}
JENKINS_TOKEN=${3:-""}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
echo "📋 Testing Jenkins at: $JENKINS_URL"
echo ""

# Test 1: Basic connectivity
echo "🌐 Test 1: Basic connectivity"
if curl -s --max-time 10 "$JENKINS_URL" > /dev/null; then
    print_status 0 "Jenkins URL is accessible"
else
    print_status 1 "Jenkins URL is NOT accessible"
    echo "   Possible causes:"
    echo "   - Jenkins is not running"
    echo "   - Wrong URL"
    echo "   - Network issues"
    echo "   - Firewall blocking access"
fi

echo ""

# Test 2: Jenkins API endpoint
echo "🔌 Test 2: API endpoint"
API_RESPONSE=$(curl -s --max-time 10 "$JENKINS_URL/api/json" -w "%{http_code}")
HTTP_CODE=${API_RESPONSE: -3}

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "403" ]; then
    print_status 0 "Jenkins API is responding (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "401" ]; then
    print_warning "Jenkins API requires authentication (HTTP $HTTP_CODE)"
else
    print_status 1 "Jenkins API not responding properly (HTTP $HTTP_CODE)"
fi

echo ""

# Test 3: Authentication (if credentials provided)
if [ -n "$JENKINS_USER" ] && [ -n "$JENKINS_TOKEN" ]; then
    echo "🔐 Test 3: Authentication"
    AUTH_RESPONSE=$(curl -s --max-time 10 -u "$JENKINS_USER:$JENKINS_TOKEN" "$JENKINS_URL/api/json" -w "%{http_code}")
    AUTH_HTTP_CODE=${AUTH_RESPONSE: -3}
    
    if [ "$AUTH_HTTP_CODE" = "200" ]; then
        print_status 0 "Authentication successful"
    else
        print_status 1 "Authentication failed (HTTP $AUTH_HTTP_CODE)"
    fi
    echo ""
fi

# Test 4: Local Jenkins service (Linux/systemd)
echo "🖥️  Test 4: Local Jenkins service (if applicable)"
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet jenkins 2>/dev/null; then
        print_status 0 "Jenkins systemd service is active"
    else
        print_status 1 "Jenkins systemd service is not active (or not installed)"
    fi
else
    print_warning "systemctl not available - skipping service check"
fi

echo ""

# Test 5: Java process check
echo "☕ Test 5: Java process check"
if pgrep -f jenkins >/dev/null; then
    print_status 0 "Jenkins Java process is running"
    echo "   Process details:"
    ps aux | grep jenkins | grep -v grep | head -1 | awk '{print "   PID: " $2 ", CPU: " $3 "%, Memory: " $4 "%"}'
else
    print_status 1 "No Jenkins Java process found"
fi

echo ""

# Test 6: Port availability
echo "🔌 Test 6: Port availability"
if command -v netstat >/dev/null 2>&1; then
    if netstat -tlnp 2>/dev/null | grep :8080 >/dev/null; then
        print_status 0 "Port 8080 is in use (likely Jenkins)"
        netstat -tlnp 2>/dev/null | grep :8080 | head -1
    else
        print_status 1 "Port 8080 is not in use"
    fi
else
    print_warning "netstat not available - skipping port check"
fi

echo ""

# Test 7: Jenkins version
echo "🏷️  Test 7: Jenkins version"
if command -v curl >/dev/null 2>&1; then
    JENKINS_VERSION=$(curl -s --max-time 5 -I "$JENKINS_URL" 2>/dev/null | grep -i "X-Jenkins:" | cut -d' ' -f2 | tr -d '\r')
    if [ -n "$JENKINS_VERSION" ]; then
        print_status 0 "Jenkins version: $JENKINS_VERSION"
    else
        print_warning "Could not determine Jenkins version"
    fi
fi

echo ""
echo "🏁 JENKINS HEALTH CHECK COMPLETE"
echo ""

# Recommendations
echo "📝 RECOMMENDATIONS:"
echo ""

if curl -s --max-time 5 "$JENKINS_URL" > /dev/null; then
    echo "✅ Jenkins appears to be accessible!"
    echo "   Next steps:"
    echo "   1. Open Jenkins in browser: $JENKINS_URL"
    echo "   2. Login with your credentials"
    echo "   3. Import your pipeline jobs from jenkins/ directory"
    echo "   4. Test pipeline execution"
else
    echo "❌ Jenkins is not accessible. Try:"
    echo "   1. Start Jenkins service: sudo systemctl start jenkins"
    echo "   2. Check firewall settings"
    echo "   3. Verify correct URL/port"
    echo "   4. Check Jenkins logs: sudo journalctl -u jenkins"
fi

echo ""
echo "📖 For more help, check:"
echo "   - CLOUD-JENKINS-REFERENCE.md"
echo "   - CLOUD-JENKINS-TROUBLESHOOTING.md"
echo "   - README.md"
