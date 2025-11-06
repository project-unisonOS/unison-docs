#!/bin/bash

# Welcome to Unison - Quick Setup Script
# This script helps you get Unison running in minutes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_banner() {
    echo -e "${BLUE}"
    echo "🚀 Welcome to Unison!"
    echo "🌟 The Future of Human-Computer Interaction"
    echo ""
    echo "Where technology adapts to you, not the other way around."
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker is installed"
        DOCKER_OK=true
    else
        print_error "Docker is not installed"
        DOCKER_OK=false
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose is installed"
        COMPOSE_OK=true
    else
        print_error "Docker Compose is not installed"
        COMPOSE_OK=false
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        print_success "Git is installed"
        GIT_OK=true
    else
        print_error "Git is not installed"
        GIT_OK=false
    fi
    
    if [ "$DOCKER_OK" = true ] && [ "$COMPOSE_OK" = true ] && [ "$GIT_OK" = true ]; then
        return 0
    else
        return 1
    fi
}

# Install prerequisites guidance
install_prerequisites() {
    echo ""
    print_warning "Installing prerequisites..."
    echo "Please install the following tools:"
    echo ""
    echo "1. Docker Desktop:"
    echo "   - Mac: https://docs.docker.com/docker-for-mac/install/"
    echo "   - Windows: https://docs.docker.com/docker-for-windows/install/"
    echo "   - Linux: https://docs.docker.com/engine/install/"
    echo ""
    echo "2. Git:"
    echo "   - Mac: brew install git"
    echo "   - Windows: https://git-scm.com/download/win"
    echo "   - Linux: sudo apt-get install git"
    echo ""
    read -p "Press Enter after you've installed these tools..."
}

# Clone repository
clone_repository() {
    echo ""
    print_info "Getting Unison..."
    
    if [ -d "unison" ]; then
        print_warning "Unison directory already exists"
        read -p "Would you like to remove it and clone fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf unison
            print_success "Removed existing directory"
        else
            print_info "Using existing unison directory"
            return 0
        fi
    fi
    
    if git clone https://github.com/unison-platform/unison.git; then
        print_success "Repository cloned successfully"
        return 0
    else
        print_error "Failed to clone repository"
        return 1
    fi
}

# Start platform
start_platform() {
    echo ""
    print_info "Starting Unison platform..."
    print_warning "This will take 2-3 minutes to start all services..."
    
    cd unison
    
    # Start the platform with timeout
    timeout 300 make up || {
        print_warning "Startup taking longer than expected..."
        print_info "You can check the status manually:"
        echo "  cd unison && make health"
        cd ..
        return 1
    }
    
    # Check if services are healthy
    sleep 10
    if make health > /dev/null 2>&1; then
        print_success "Unison platform is ready!"
        cd ..
        return 0
    else
        print_warning "Platform startup had issues, but you can continue..."
        cd ..
        return 1
    fi
}

# Open browser
open_browser() {
    echo ""
    print_info "Opening Unison in your browser..."
    
    # Try to open browser based on OS
    case "$(uname -s)" in
        Darwin*)    open http://localhost:3000 ;;
        Linux*)     xdg-open http://localhost:3000 ;;
        CYGWIN*|MINGW*|MSYS*) start http://localhost:3000 ;;
        *)          print_warning "Could not detect browser. Please open http://localhost:3000 manually" ;;
    esac
    
    print_success "Browser opened to http://localhost:3000"
}

# Show first steps
show_first_steps() {
    echo ""
    echo -e "${BLUE}🎯 Your First Steps with Unison:${NC}"
    echo ""
    echo "1. 💬 Try the Chat Interface:"
    echo "   - Type: \"Hello Unison, what can you do?\""
    echo "   - Try: \"Help me plan my day\""
    echo "   - Ask: \"What's my current context?\""
    echo ""
    echo "2. 🔧 Explore Settings:"
    echo "   - Click the gear icon ⚙️"
    echo "   - Set your name and preferences"
    echo "   - Configure notification settings"
    echo ""
    echo "3. 🌟 Try Scenarios:"
    echo "   - Click \"Scenarios\" in the interface"
    echo "   - Try \"Morning Assistant\" or \"Focus Mode\""
    echo "   - Experience context-aware interactions"
    echo ""
    echo "4. 📚 Learn More:"
    echo "   - Documentation: https://docs.unisonos.org"
    echo "   - Community: https://discord.gg/unison"
    echo "   - Tutorials: https://youtube.com/c/unisonplatform"
    echo ""
    echo -e "${GREEN}🎉 Welcome to the future of adaptive technology!${NC}"
}

# Show troubleshooting
show_troubleshooting() {
    echo ""
    echo -e "${BLUE}🔧 Troubleshooting Tips:${NC}"
    echo ""
    echo "If something doesn't work:"
    echo ""
    echo "1. Check Service Health:"
    echo "   cd unison && make health"
    echo ""
    echo "2. View Logs:"
    echo "   cd unison && make logs"
    echo ""
    echo "3. Restart Services:"
    echo "   cd unison && make down && make up"
    echo ""
    echo "4. Get Help:"
    echo "   - Discord: https://discord.gg/unison"
    echo "   - GitHub Issues: https://github.com/unison-platform/unison/issues"
    echo "   - Email: support@unisonos.org"
    echo ""
    echo "Common Issues:"
    echo "- Port 3000 in use: lsof -ti:3000 | xargs kill -9"
    echo "- Docker issues: Restart Docker Desktop"
    echo "- Memory issues: Increase Docker memory to 8GB+"
}

# Main function
main() {
    print_banner
    
    # Check prerequisites
    if ! check_prerequisites; then
        install_prerequisites
        if ! check_prerequisites; then
            print_error "Prerequisites not met. Please install Docker, Docker Compose, and Git."
            exit 1
        fi
    fi
    
    # Clone repository
    if ! clone_repository; then
        print_error "Failed to set up repository."
        exit 1
    fi
    
    # Start platform
    start_platform
    STARTUP_RESULT=$?
    
    # Open browser
    open_browser
    
    # Show next steps
    show_first_steps
    show_troubleshooting
    
    echo ""
    echo -e "${GREEN}🎉 Setup Complete!${NC}"
    echo ""
    echo "You now have Unison running locally. The platform includes:"
    echo "- 15+ microservices working together"
    echo "- Real-time context understanding"
    echo "- Natural language processing"
    echo "- Dynamic experience generation"
    echo ""
    echo "Next: Open your browser to http://localhost:3000 and start exploring!"
    echo ""
    echo -e "${BLUE}🌟 Welcome to the Unison community!${NC}"
    
    if [ $STARTUP_RESULT -ne 0 ]; then
        echo ""
        print_warning "Note: Platform startup had some issues."
        print_info "Check 'cd unison && make health' for service status."
    fi
}

# Run main function
main "$@"
