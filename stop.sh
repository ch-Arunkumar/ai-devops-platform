#!/bin/bash

# ============================================================
#  AI DevOps Platform — Stop Everything
#  Usage: bash stop.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     🛑 Stopping AI DevOps Platform              ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}==> Stopping port forwards...${NC}"
pkill -f "kubectl port-forward" 2>/dev/null && \
    echo -e "${GREEN}✅ Port forwards stopped${NC}" || \
    echo -e "${GREEN}✅ No port forwards running${NC}"

echo -e "${CYAN}==> Stopping frontend server...${NC}"
pkill -f "http.server 8081" 2>/dev/null && \
    echo -e "${GREEN}✅ Frontend stopped${NC}" || \
    echo -e "${GREEN}✅ Frontend was not running${NC}"

echo -e "${CYAN}==> Stopping Cloudflare tunnel...${NC}"
pkill -f "cloudflared" 2>/dev/null && \
    echo -e "${GREEN}✅ Cloudflare tunnel stopped${NC}" || \
    echo -e "${GREEN}✅ No tunnel running${NC}"

echo -e "${CYAN}==> Stopping Minikube...${NC}"
minikube stop && \
    echo -e "${GREEN}✅ Minikube stopped${NC}"

echo ""
echo -e "${GREEN}  ✅ Everything stopped! Your laptop is free now.${NC}"
echo -e "${CYAN}  To start again: bash start.sh${NC}"
echo ""
