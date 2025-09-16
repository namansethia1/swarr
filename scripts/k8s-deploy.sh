#!/bin/bash

# Kubernetes deployment script for Project Swar
set -e

echo "🚀 Deploying Project Swar to Kubernetes..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_status "kubectl check passed ✓"
}

# Deploy to Kubernetes
deploy_k8s() {
    print_status "Deploying to Kubernetes cluster..."
    
    # Apply backend deployment
    kubectl apply -f k8s/backend-deployment.yaml
    
    # Apply frontend deployment
    kubectl apply -f k8s/frontend-deployment.yaml
    
    print_status "Kubernetes deployments applied"
    
    # Wait for deployments to be ready
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/swar-backend
    kubectl wait --for=condition=available --timeout=300s deployment/swar-frontend
    
    print_status "Deployments are ready ✓"
}

# Show deployment status
show_k8s_status() {
    print_status "Kubernetes Deployment Status:"
    echo ""
    
    print_status "Deployments:"
    kubectl get deployments -l app=swar-backend -o wide
    kubectl get deployments -l app=swar-frontend -o wide
    
    echo ""
    print_status "Pods:"
    kubectl get pods -l app=swar-backend
    kubectl get pods -l app=swar-frontend
    
    echo ""
    print_status "Services:"
    kubectl get services -l app=swar-backend
    kubectl get services -l app=swar-frontend
    
    # Get external IP if available
    frontend_ip=$(kubectl get service swar-frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    if [ "$frontend_ip" != "pending" ] && [ "$frontend_ip" != "" ]; then
        print_status "Frontend accessible at: http://$frontend_ip:3000"
    else
        print_warning "Frontend LoadBalancer IP is still pending. Use 'kubectl get services' to check status."
    fi
}

# Clean up Kubernetes resources
cleanup_k8s() {
    print_status "Cleaning up Kubernetes resources..."
    
    kubectl delete -f k8s/backend-deployment.yaml --ignore-not-found=true
    kubectl delete -f k8s/frontend-deployment.yaml --ignore-not-found=true
    
    print_status "Kubernetes resources cleaned up ✓"
}

# Port forward for local access
port_forward() {
    print_status "Setting up port forwarding for local access..."
    
    # Kill any existing port-forward processes
    pkill -f "kubectl port-forward" || true
    
    # Port forward backend
    kubectl port-forward service/swar-backend-service 8000:8000 &
    backend_pid=$!
    
    # Port forward frontend
    kubectl port-forward service/swar-frontend-service 3000:3000 &
    frontend_pid=$!
    
    print_status "Port forwarding established:"
    print_status "Frontend: http://localhost:3000"
    print_status "Backend: http://localhost:8000"
    print_status "API Docs: http://localhost:8000/docs"
    
    echo ""
    print_warning "Press Ctrl+C to stop port forwarding"
    
    # Wait for user interrupt
    trap "kill $backend_pid $frontend_pid 2>/dev/null; exit 0" INT
    wait
}

# Display help
show_help() {
    echo "Project Swar Kubernetes Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy       Deploy to Kubernetes cluster"
    echo "  status       Show deployment status"
    echo "  cleanup      Remove all Kubernetes resources"
    echo "  port-forward Setup port forwarding for local access"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 status"
    echo "  $0 port-forward"
}

# Main execution
main() {
    local command=${1:-"deploy"}
    
    case $command in
        deploy)
            check_kubectl
            deploy_k8s
            show_k8s_status
            print_status "Deployment completed! 🎉"
            ;;
        status)
            check_kubectl
            show_k8s_status
            ;;
        cleanup)
            check_kubectl
            cleanup_k8s
            ;;
        port-forward)
            check_kubectl
            port_forward
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"