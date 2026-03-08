#!/bin/bash

# ============================================================
#  AI DevOps Platform — Check Status of Everything
#  Usage: bash status.sh
# ============================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

check_url() {
    local name=$1
    local url=$2
    if curl -s --max-time 3 "$url" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $name${NC} → $url"
    else
        echo -e "  ${RED}❌ $name${NC} → $url (not responding)"
    fi
}

clear
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     📊 AI DevOps Platform — Status Check        ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}  Kubernetes Pods:${NC}"
kubectl get pods 2>/dev/null || echo -e "${RED}  Minikube not running${NC}"

echo ""
echo -e "${CYAN}  Service Health:${NC}"
check_url "Frontend App"      "http://localhost:8081"
check_url "User Service"      "http://localhost:5000/health"
check_url "Product Service"   "http://localhost:5001/health"
check_url "Order Service"     "http://localhost:5002/health"
check_url "AI Healer"         "http://localhost:5010/health"
check_url "Grafana"           "http://localhost:3001"
check_url "ArgoCD"            "https://localhost:8080"

echo ""
echo -e "${CYAN}  Quick Links:${NC}"
echo -e "  🍕 App      → http://localhost:8081"
echo -e "  📊 Grafana  → http://localhost:3001  (admin/admin123)"
echo -e "  🔄 ArgoCD   → https://localhost:8080 (admin)"
echo ""
