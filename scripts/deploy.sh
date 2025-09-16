#!/bin/bash

# Project Swar Deployment Script
set -e

echo "🚀 Starting Project Swar deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-"development"}
DOCKER_COMPOSE_FILE="docker-compose.yml"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "Dependencies check passed ✓"
}

# Build and start services
deploy_local() {
    print_status "Deploying locally with Docker Compose..."
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose down --remove-orphans
    
    # Build and start containers
    print_status "Building and starting containers..."
    docker-compose up --build -d
    
    # Wait for services to be healthy
    print_status "Waiting for services to be healthy..."
    sleep 30
    
    # Check service health
    check_health
}

# Deploy to production with additional nginx proxy
deploy_production() {
    print_status "Deploying to production environment..."
    
    # Use production profile
    docker-compose --profile production down --remove-orphans
    docker-compose --profile production up --build -d
    
    print_status "Production deployment started with nginx proxy"
    
    # Wait for services to be healthy
    sleep 45
    check_health
}

# Check service health
check_health() {
    print_status "Checking service health..."
    
    # Check backend health
    backend_health=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || echo "000")
    if [ "$backend_health" = "200" ]; then
        print_status "Backend service is healthy ✓"
    else
        print_error "Backend service is not healthy (HTTP $backend_health)"
    fi
    
    # Check frontend health
    frontend_health=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
    if [ "$frontend_health" = "200" ]; then
        print_status "Frontend service is healthy ✓"
    else
        print_error "Frontend service is not healthy (HTTP $frontend_health)"
    fi
}

# Show service status
show_status() {
    print_status "Service Status:"
    docker-compose ps
    
    print_status "\nService Logs (last 10 lines):"
    echo "Backend logs:"
    docker-compose logs --tail=10 backend
    echo -e "\nFrontend logs:"
    docker-compose logs --tail=10 frontend
}

# Stop services
stop_services() {
    print_status "Stopping all services..."
    docker-compose down --remove-orphans
    print_status "Services stopped ✓"
}

# Clean up
cleanup() {
    print_status "Cleaning up Docker resources..."
    docker-compose down --remove-orphans --volumes
    docker system prune -f
    print_status "Cleanup completed ✓"
}

# Display help
show_help() {
    echo "Project Swar Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [ENVIRONMENT]"
    echo ""
    echo "Commands:"
    echo "  deploy     Deploy the application (default: development)"
    echo "  status     Show service status and logs"
    echo "  stop       Stop all services"
    echo "  cleanup    Stop services and clean up resources"
    echo "  health     Check service health"
    echo "  help       Show this help message"
    echo ""
    echo "Environments:"
    echo "  development  Deploy locally (default)"
    echo "  production   Deploy with production configuration"
    echo ""
    echo "Examples:"
    echo "  $0 deploy development"
    echo "  $0 deploy production"
    echo "  $0 status"
    echo "  $0 stop"
}

# Main execution
main() {
    local command=${1:-"deploy"}
    
    case $command in
        deploy)
            check_dependencies
            if [ "$ENVIRONMENT" = "production" ]; then
                deploy_production
            else
                deploy_local
            fi
            print_status "Deployment completed! 🎉"
            print_status "Frontend: http://localhost:3000"
            print_status "Backend API: http://localhost:8000"
            print_status "API Docs: http://localhost:8000/docs"
            ;;
        status)
            show_status
            ;;
        stop)
            stop_services
            ;;
        cleanup)
            cleanup
            ;;
        health)
            check_health
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