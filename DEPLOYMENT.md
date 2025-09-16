# Project Swar - Deployment Guide

This guide covers all deployment options for Project Swar, from local development to production deployment on various platforms.

## 🚀 Quick Start

### Local Development
```bash
# Setup development environment
chmod +x scripts/setup.sh
./scripts/setup.sh

# Start development servers
./start-dev.sh
```

### Docker Deployment
```bash
# Simple local deployment
chmod +x scripts/deploy.sh
./scripts/deploy.sh

# Production deployment with nginx
./scripts/deploy.sh deploy production
```

## 📦 Deployment Options

### 1. Local Docker Development

**Prerequisites:**
- Docker 20.10+
- Docker Compose 2.0+

**Commands:**
```bash
# Deploy locally
./scripts/deploy.sh deploy development

# Check status
./scripts/deploy.sh status

# Stop services
./scripts/deploy.sh stop

# Cleanup
./scripts/deploy.sh cleanup
```

**Access URLs:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Documentation: http://localhost:8000/docs

### 2. Production Docker with Nginx

```bash
# Deploy with production configuration
./scripts/deploy.sh deploy production
```

This includes:
- Multi-stage builds for optimization
- Security headers and GZIP compression
- Health checks and monitoring
- Non-root containers for security

### 3. Cloud Platform Deployments

#### Vercel (Frontend)
1. Connect your GitHub repository to Vercel
2. Set environment variables:
   - `REACT_APP_API_URL`: Your backend URL
   - `REACT_APP_WS_URL`: Your WebSocket URL
3. Deploy automatically on push to main

#### Railway (Full Stack)
1. Connect repository to Railway
2. Railway will auto-detect the `railway.toml` configuration
3. Services will be deployed automatically

#### Render (Full Stack)
1. Connect repository to Render
2. Import the `render.yaml` configuration
3. Set up environment variables as needed

### 4. Kubernetes Deployment

**Prerequisites:**
- kubectl configured with cluster access
- Container images built and pushed to registry

**Commands:**
```bash
# Deploy to Kubernetes
chmod +x scripts/k8s-deploy.sh
./scripts/k8s-deploy.sh deploy

# Check status
./scripts/k8s-deploy.sh status

# Port forward for local access
./scripts/k8s-deploy.sh port-forward

# Cleanup
./scripts/k8s-deploy.sh cleanup
```

## 🔧 Configuration

### Environment Variables

#### Backend
- `ENVIRONMENT`: production/development
- `LOG_LEVEL`: info/debug/warning/error
- `PORT`: Server port (default: 8000)

#### Frontend
- `REACT_APP_API_URL`: Backend API URL
- `REACT_APP_WS_URL`: WebSocket URL
- `PORT`: Server port (default: 3000)

### Build Configuration

#### Backend Dockerfile Features:
- Multi-stage build for size optimization
- Tree-sitter grammar compilation
- Non-root user for security
- Health checks
- Production-ready uvicorn configuration

#### Frontend Dockerfile Features:
- Node.js build optimization
- Nginx serving with custom configuration
- Security headers
- GZIP compression
- Health checks

## 🔄 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) provides:

### Automated Testing
- Python backend tests with pytest
- TypeScript frontend type checking
- Linting and code quality checks

### Security Scanning
- Trivy vulnerability scanning
- Dependency security checks

### Container Building
- Multi-platform builds (amd64, arm64)
- Automatic tagging and versioning
- Push to GitHub Container Registry

### Deployment Triggers
- Automatic deployment on push to main
- Manual deployment workflows available

## 📊 Monitoring and Health Checks

### Health Endpoints
- Backend: `GET /health`
- Frontend: `GET /health`

### Docker Health Checks
Both services include built-in health checks that monitor:
- Service availability
- Response time
- Resource usage

### Kubernetes Monitoring
- Liveness probes for automatic restart
- Readiness probes for load balancing
- Resource limits and requests

## 🛡️ Security Features

### Container Security
- Non-root user execution
- Minimal base images
- Security header configuration
- Dependency vulnerability scanning

### Network Security
- CORS configuration
- Security headers (CSP, XSS protection)
- HTTPS configuration options

## 🔧 Troubleshooting

### Common Issues

#### Tree-sitter Build Errors
```bash
# Ensure build tools are available
apt-get update && apt-get install -y build-essential

# Manually rebuild languages
cd backend
python -c "from tree_sitter import Language; Language.build_library('build/languages.so', ['vendor/tree-sitter-go', 'vendor/tree-sitter-javascript'])"
```

#### Docker Memory Issues
```bash
# Increase Docker memory allocation
# For Docker Desktop: Settings > Resources > Memory

# For production, adjust container limits in docker-compose.yml
```

#### Port Conflicts
```bash
# Check what's using the ports
netstat -tulpn | grep :3000
netstat -tulpn | grep :8000

# Kill conflicting processes or change ports in configuration
```

### Logs Access

#### Docker Logs
```bash
# View all service logs
docker-compose logs -f

# View specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

#### Kubernetes Logs
```bash
# View pod logs
kubectl logs -l app=swar-backend
kubectl logs -l app=swar-frontend

# Follow logs
kubectl logs -f deployment/swar-backend
```

## 📝 Deployment Checklist

### Pre-deployment
- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Security scan completed
- [ ] Documentation updated

### Post-deployment
- [ ] Health checks passing
- [ ] All services accessible
- [ ] Performance monitoring active
- [ ] Backup procedures in place

## 🆘 Support

For deployment issues:
1. Check the troubleshooting section above
2. Review service logs for error details
3. Verify environment configuration
4. Check resource availability (memory, CPU, storage)
5. Consult the main README.md for additional information

---

*Project Swar - Transforming code analysis through visualization and sound*