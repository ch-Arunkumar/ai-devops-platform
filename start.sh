#!/bin/bash

# ============================================================
#  AI DevOps Platform — Master Startup Script
#  Run this ONE script to start EVERYTHING
#  Usage: bash start.sh
# ============================================================

# ── Colors for pretty output ────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Helper functions ─────────────────────────────────────────
print_step()    { echo -e "\n${BLUE}==>${NC} ${CYAN}$1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${PURPLE}ℹ️  $1${NC}"; }

wait_for_pods() {
    local namespace=${1:-default}
    local max_wait=120
    local waited=0

    echo -ne "${YELLOW}   Waiting for pods"
    while true; do
        not_ready=$(kubectl get pods -n "$namespace" 2>/dev/null \
            | grep -v "Running\|Completed\|NAME" | wc -l)

        if [ "$not_ready" -eq 0 ]; then
            echo -e "${NC}"
            return 0
        fi

        if [ $waited -ge $max_wait ]; then
            echo -e "${NC}"
            print_warning "Timeout waiting — continuing anyway"
            return 1
        fi

        echo -ne "."
        sleep 3
        waited=$((waited + 3))
    done
}

# ============================================================
#  BANNER
# ============================================================
clear
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     🤖 AI DevOps Platform — Master Startup      ║"
echo "  ║     Built by Arun Kumar                         ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
#  STEP 1 — CHECK DOCKER IS RUNNING
# ============================================================
print_step "STEP 1 — Checking Docker Desktop..."

if ! docker info > /dev/null 2>&1; then
    print_error "Docker Desktop is not running!"
    print_info "Please open Docker Desktop and wait for green Engine Running status"
    print_info "Then run this script again"
    exit 1
fi

print_success "Docker Desktop is running"

# ============================================================
#  STEP 2 — START MINIKUBE
# ============================================================
print_step "STEP 2 — Starting Minikube (Kubernetes)..."

minikube_status=$(minikube status 2>/dev/null | grep "host:" | awk '{print $2}')

if [ "$minikube_status" = "Running" ]; then
    print_success "Minikube already running — skipping"
else
    print_info "Starting Minikube for the first time..."
    minikube start --driver=docker
    if [ $? -ne 0 ]; then
        print_error "Minikube failed to start!"
        exit 1
    fi
    print_success "Minikube started successfully"
fi

# ============================================================
#  STEP 3 — DEPLOY SERVICES TO KUBERNETES
# ============================================================
print_step "STEP 3 — Deploying services to Kubernetes..."

# Check if services already deployed
existing=$(kubectl get deployments 2>/dev/null | grep -c "service" || true)

if [ "$existing" -gt 0 ]; then
    print_success "Services already deployed — skipping"
else
    print_info "Applying Kubernetes manifests..."

    if [ -d "k8s" ]; then
        kubectl apply -f k8s/user-service.yaml
        kubectl apply -f k8s/product-service.yaml
        kubectl apply -f k8s/order-service.yaml

        # Deploy ai-healer only if secrets exist
        if kubectl get secret ai-healer-secrets > /dev/null 2>&1; then
            kubectl apply -f k8s/ai-healer.yaml
            print_success "AI Healer deployed"
        else
            print_warning "AI Healer secrets not found — skipping ai-healer"
            print_info "Run: kubectl create secret generic ai-healer-secrets --from-literal=OPENAI_API_KEY=YOUR_KEY --from-literal=SLACK_WEBHOOK_URL=YOUR_URL"
        fi
    else
        print_error "k8s folder not found! Make sure you are in the project folder"
        exit 1
    fi
fi

# ============================================================
#  STEP 4 — WAIT FOR PODS TO BE READY
# ============================================================
print_step "STEP 4 — Waiting for all pods to be ready..."
wait_for_pods default
kubectl get pods
print_success "All pods are running"

# ============================================================
#  STEP 5 — INSTALL MONITORING IF NOT INSTALLED
# ============================================================
print_step "STEP 5 — Checking Prometheus and Grafana..."

monitoring_exists=$(kubectl get pods -n monitoring 2>/dev/null | grep -c "Running" || true)

if [ "$monitoring_exists" -gt 0 ]; then
    print_success "Monitoring stack already running — skipping"
else
    print_info "Installing Prometheus and Grafana..."
    helm repo add prometheus-community \
        https://prometheus-community.github.io/helm-charts 2>/dev/null
    helm repo update 2>/dev/null
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set grafana.adminPassword=admin123 \
        --wait --timeout 5m
    print_success "Monitoring stack installed"
fi

# ============================================================
#  STEP 6 — INSTALL ARGOCD IF NOT INSTALLED
# ============================================================
print_step "STEP 6 — Checking ArgoCD..."

argocd_exists=$(kubectl get pods -n argocd 2>/dev/null | grep -c "Running" || true)

if [ "$argocd_exists" -gt 0 ]; then
    print_success "ArgoCD already running — skipping"
else
    print_info "Installing ArgoCD..."
    kubectl create namespace argocd 2>/dev/null || true
    kubectl apply -n argocd -f \
        https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    print_info "Waiting for ArgoCD pods..."
    wait_for_pods argocd
    print_success "ArgoCD installed"
fi

# ============================================================
#  STEP 7 — START ALL PORT FORWARDS
# ============================================================
print_step "STEP 7 — Starting port forwards for all services..."

# Kill any existing port forwards
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# Start all port forwards in background
kubectl port-forward service/ai-healer 5010:5010 > /dev/null 2>&1 &
kubectl port-forward service/ai-healer 5010:5010 &
kubectl port-forward service/user-service    5000:5000 > /dev/null 2>&1 &
kubectl port-forward service/product-service 5001:5001 > /dev/null 2>&1 &
kubectl port-forward service/order-service   5002:5002 > /dev/null 2>&1 &
kubectl port-forward svc/prometheus-grafana  3001:80 -n monitoring > /dev/null 2>&1 &
kubectl port-forward svc/argocd-server       8080:443 -n argocd > /dev/null 2>&1 &

# Start AI Healer port forward if running
if kubectl get service ai-healer > /dev/null 2>&1; then
    kubectl port-forward service/ai-healer 5010:5010 > /dev/null 2>&1 &
fi

sleep 3
print_success "All port forwards started"

# ============================================================
#  STEP 8 — START FRONTEND
# ============================================================
print_step "STEP 8 — Starting Frontend..."

if [ -d "frontend" ]; then
    cd frontend
    python -m http.server 8081 > /dev/null 2>&1 &
    cd ..
    print_success "Frontend started on port 8081"
else
    print_warning "Frontend folder not found — skipping"
fi

# ============================================================
#  STEP 9 — START CLOUDFLARE TUNNEL
# ============================================================
print_step "STEP 9 — Starting Cloudflare public URL..."

if command -v cloudflared &> /dev/null; then
    cloudflared tunnel --url http://localhost:8081 > /tmp/cloudflare.log 2>&1 &
    sleep 5

    tunnel_url=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' \
        /tmp/cloudflare.log 2>/dev/null | head -1)

    if [ -n "$tunnel_url" ]; then
        print_success "Public URL created: $tunnel_url"
    else
        print_warning "Cloudflare tunnel starting — check /tmp/cloudflare.log for URL"
    fi
else
    print_warning "cloudflared not installed — skipping public URL"
    print_info "Download from: https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
fi

# ============================================================
#  DONE — PRINT SUMMARY
# ============================================================
echo ""
echo -e "${GREEN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║           🎉 PLATFORM IS LIVE!                  ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}  Local URLs:${NC}"
echo -e "  🍕 Frontend App  →  ${GREEN}http://localhost:8081${NC}"
echo -e "  👥 User Service  →  ${GREEN}http://localhost:5000/users${NC}"
echo -e "  🍔 Products      →  ${GREEN}http://localhost:5001/products${NC}"
echo -e "  📦 Orders        →  ${GREEN}http://localhost:5002/orders${NC}"
echo -e "  📊 Grafana       →  ${GREEN}http://localhost:3001${NC}  (admin/admin123)"
echo -e "  🔄 ArgoCD        →  ${GREEN}https://localhost:8080${NC}  (admin)"
echo ""
echo -e "${CYAN}  ArgoCD Password:${NC}"
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d
echo ""
echo ""
echo -e "${CYAN}  Kubernetes Pods:${NC}"
kubectl get pods
echo ""
echo -e "${YELLOW}  To stop everything:   bash stop.sh${NC}"
echo -e "${YELLOW}  To share publicly:    cloudflared tunnel --url http://localhost:8081${NC}"
echo ""
