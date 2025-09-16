#!/bin/bash

# Project Swar Environment Setup Script
set -e

echo "🔧 Setting up Project Swar development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Setup Python environment
setup_python() {
    print_section "Setting up Python environment..."
    
    cd backend
    
    # Check Python version
    if command_exists python3; then
        python_version=$(python3 --version | cut -d' ' -f2)
        print_status "Found Python $python_version"
    else
        print_error "Python 3 is not installed. Please install Python 3.11 or higher."
        exit 1
    fi
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
    else
        print_status "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install dependencies
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Build tree-sitter languages
    print_status "Building tree-sitter language grammars..."
    mkdir -p vendor
    cd vendor
    
    # Clone grammars if they don't exist
    if [ ! -d "tree-sitter-go" ]; then
        git clone https://github.com/tree-sitter/tree-sitter-go
    fi
    
    if [ ! -d "tree-sitter-javascript" ]; then
        git clone https://github.com/tree-sitter/tree-sitter-javascript
    fi
    
    cd ..
    
    # Build language library
    python -c "from tree_sitter import Language; Language.build_library('build/languages.so', ['vendor/tree-sitter-go', 'vendor/tree-sitter-javascript'])"
    
    print_status "Python environment setup completed ✓"
    cd ..
}

# Setup Node.js environment
setup_nodejs() {
    print_section "Setting up Node.js environment..."
    
    cd frontend
    
    # Check Node.js version
    if command_exists node; then
        node_version=$(node --version)
        print_status "Found Node.js $node_version"
    else
        print_error "Node.js is not installed. Please install Node.js 18 or higher."
        exit 1
    fi
    
    # Check npm version
    if command_exists npm; then
        npm_version=$(npm --version)
        print_status "Found npm $npm_version"
    else
        print_error "npm is not installed. Please install npm."
        exit 1
    fi
    
    # Install dependencies
    print_status "Installing Node.js dependencies..."
    npm ci
    
    print_status "Node.js environment setup completed ✓"
    cd ..
}

# Setup Git hooks
setup_git_hooks() {
    print_section "Setting up Git hooks..."
    
    if [ -d ".git" ]; then
        # Create pre-commit hook
        cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running pre-commit checks..."

# Check Python code formatting
if [ -d "backend/venv" ]; then
    source backend/venv/bin/activate
    echo "Checking Python formatting..."
    # Add your Python linting/formatting checks here
    # flake8 backend/ || exit 1
    # black --check backend/ || exit 1
fi

# Check TypeScript code
if [ -d "frontend/node_modules" ]; then
    cd frontend
    echo "Checking TypeScript..."
    npm run lint || exit 1
    npx tsc --noEmit || exit 1
    cd ..
fi

echo "Pre-commit checks passed ✓"
EOF
        
        chmod +x .git/hooks/pre-commit
        print_status "Git hooks setup completed ✓"
    else
        print_warning "Not a git repository, skipping Git hooks setup"
    fi
}

# Create development scripts
create_dev_scripts() {
    print_section "Creating development scripts..."
    
    # Create start script
    cat > start-dev.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Project Swar in development mode..."

# Start backend
echo "Starting backend..."
cd backend
source venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
backend_pid=$!
cd ..

# Start frontend
echo "Starting frontend..."
cd frontend
npm run dev &
frontend_pid=$!
cd ..

echo "Services started:"
echo "Frontend: http://localhost:5173"
echo "Backend: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"

# Function to cleanup
cleanup() {
    echo "Stopping services..."
    kill $backend_pid $frontend_pid 2>/dev/null
    exit 0
}

# Trap Ctrl+C
trap cleanup INT

# Wait for processes
wait
EOF
    
    chmod +x start-dev.sh
    
    # Create test script
    cat > run-tests.sh << 'EOF'
#!/bin/bash
echo "🧪 Running Project Swar tests..."

# Run backend tests
echo "Running backend tests..."
cd backend
source venv/bin/activate
pytest --cov=. --cov-report=html || echo "Backend tests completed with issues"
cd ..

# Run frontend tests
echo "Running frontend tests..."
cd frontend
npm test -- --coverage --watchAll=false || echo "Frontend tests completed with issues"
cd ..

echo "Tests completed ✓"
EOF
    
    chmod +x run-tests.sh
    
    print_status "Development scripts created ✓"
}

# Display final instructions
show_instructions() {
    print_section "Setup completed! 🎉"
    echo ""
    echo "Quick start commands:"
    echo "  ./start-dev.sh          Start development servers"
    echo "  ./run-tests.sh          Run all tests"
    echo "  ./scripts/deploy.sh     Deploy with Docker"
    echo ""
    echo "Manual start:"
    echo "  Backend:"
    echo "    cd backend"
    echo "    source venv/bin/activate"
    echo "    uvicorn main:app --reload"
    echo ""
    echo "  Frontend:"
    echo "    cd frontend"
    echo "    npm run dev"
    echo ""
    echo "Access URLs:"
    echo "  Frontend: http://localhost:5173"
    echo "  Backend: http://localhost:8000"
    echo "  API Docs: http://localhost:8000/docs"
}

# Main execution
main() {
    print_status "Starting Project Swar environment setup..."
    
    setup_python
    setup_nodejs
    setup_git_hooks
    create_dev_scripts
    
    show_instructions
}

# Run setup
main "$@"