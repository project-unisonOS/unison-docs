#!/usr/bin/env python3
"""
Welcome to Unison - Interactive Setup Assistant
"""

import os
import sys
import subprocess
import time
import webbrowser
from pathlib import Path

def print_banner():
    """Print welcome banner"""
    print("""
🚀 Welcome to Unison!
🌟 The Future of Human-Computer Interaction

Where technology adapts to you, not the other way around.
""")

def check_prerequisites():
    """Check if required tools are installed"""
    print("🔍 Checking prerequisites...")
    
    # Check Docker
    try:
        result = subprocess.run(['docker', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Docker is installed")
            docker_ok = True
        else:
            print("❌ Docker is not installed")
            docker_ok = False
    except FileNotFoundError:
        print("❌ Docker is not found")
        docker_ok = False
    
    # Check Docker Compose
    try:
        result = subprocess.run(['docker-compose', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Docker Compose is installed")
            compose_ok = True
        else:
            print("❌ Docker Compose is not installed")
            compose_ok = False
    except FileNotFoundError:
        print("❌ Docker Compose is not found")
        compose_ok = False
    
    # Check Git
    try:
        result = subprocess.run(['git', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Git is installed")
            git_ok = True
        else:
            print("❌ Git is not installed")
            git_ok = False
    except FileNotFoundError:
        print("❌ Git is not found")
        git_ok = False
    
    return docker_ok and compose_ok and git_ok

def install_prerequisites():
    """Guide user through installing prerequisites"""
    print("\n📦 Installing prerequisites...")
    print("Please install the following tools:")
    print()
    print("1. Docker Desktop:")
    print("   - Mac: https://docs.docker.com/docker-for-mac/install/")
    print("   - Windows: https://docs.docker.com/docker-for-windows/install/")
    print("   - Linux: https://docs.docker.com/engine/install/")
    print()
    print("2. Git:")
    print("   - Mac: brew install git")
    print("   - Windows: https://git-scm.com/download/win")
    print("   - Linux: sudo apt-get install git")
    print()
    input("Press Enter after you've installed these tools...")

def clone_repository():
    """Clone the Unison repository"""
    print("\n📥 Getting Unison...")
    
    if os.path.exists('unison'):
        print("📁 Unison directory already exists")
        response = input("Would you like to remove it and clone fresh? (y/N): ")
        if response.lower() == 'y':
            import shutil
            shutil.rmtree('unison')
        else:
            print("Using existing unison directory")
            return True
    
    try:
        result = subprocess.run([
            'git', 'clone', 
            'https://github.com/unison-platform/unison.git'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Repository cloned successfully")
            return True
        else:
            print(f"❌ Failed to clone repository: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Error cloning repository: {e}")
        return False

def start_platform():
    """Start the Unison platform"""
    print("\n🚀 Starting Unison platform...")
    print("This will take 2-3 minutes to start all services...")
    
    try:
        # Change to unison directory
        os.chdir('unison')
        
        # Start the platform
        print("Running: make up")
        process = subprocess.Popen(['make', 'up'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        
        # Show progress
        startup_complete = False
        start_time = time.time()
        timeout = 300  # 5 minutes timeout
        
        while not startup_complete and (time.time() - start_time) < timeout:
            output = process.stdout.readline()
            if output:
                print(output.strip())
                if "All services are healthy" in output or "✅ All services are healthy" in output:
                    startup_complete = True
                    break
            time.sleep(1)
        
        if startup_complete:
            print("✅ Unison platform is ready!")
            return True
        else:
            print("⚠️ Startup taking longer than expected...")
            print("You can check the status manually:")
            print("  cd unison && make health")
            return False
            
    except KeyboardInterrupt:
        print("\n⚠️ Startup interrupted by user")
        return False
    except Exception as e:
        print(f"❌ Error starting platform: {e}")
        return False

def open_browser():
    """Open browser to Unison interface"""
    print("\n🌐 Opening Unison in your browser...")
    try:
        webbrowser.open('http://localhost:3000')
        print("✅ Browser opened to http://localhost:3000")
        return True
    except Exception as e:
        print(f"❌ Could not open browser: {e}")
        print("Please manually open: http://localhost:3000")
        return False

def show_first_steps():
    """Show first steps for using Unison"""
    print("""
🎯 Your First Steps with Unison:

1. 💬 Try the Chat Interface:
   - Type: "Hello Unison, what can you do?"
   - Try: "Help me plan my day"
   - Ask: "What's my current context?"

2. 🔧 Explore Settings:
   - Click the gear icon ⚙️
   - Set your name and preferences
   - Configure notification settings

3. 🌟 Try Scenarios:
   - Click "Scenarios" in the interface
   - Try "Morning Assistant" or "Focus Mode"
   - Experience context-aware interactions

4. 📚 Learn More:
   - Read the documentation: https://docs.unisonos.org
   - Join the community: https://discord.gg/unison
   - Watch tutorials: https://youtube.com/c/unisonplatform

🎉 Welcome to the future of adaptive technology!
""")

def show_troubleshooting():
    """Show troubleshooting tips"""
    print("""
🔧 Troubleshooting Tips:

If something doesn't work:

1. Check Service Health:
   cd unison && make health

2. View Logs:
   cd unison && make logs

3. Restart Services:
   cd unison && make down && make up

4. Get Help:
   - Discord: https://discord.gg/unison
   - GitHub Issues: https://github.com/unison-platform/unison/issues
   - Email: support@unisonos.org

Common Issues:
- Port 3000 in use: Kill process with `lsof -ti:3000 | xargs kill -9`
- Docker issues: Restart Docker Desktop
- Memory issues: Increase Docker memory to 8GB+
""")

def main():
    """Main setup flow"""
    print_banner()
    
    # Check prerequisites
    if not check_prerequisites():
        install_prerequisites()
        if not check_prerequisites():
            print("❌ Prerequisites not met. Please install Docker, Docker Compose, and Git.")
            sys.exit(1)
    
    # Clone repository
    if not clone_repository():
        print("❌ Failed to set up repository.")
        sys.exit(1)
    
    # Start platform
    if not start_platform():
        print("⚠️ Platform startup had issues, but you can continue...")
    
    # Open browser
    open_browser()
    
    # Show next steps
    show_first_steps()
    show_troubleshooting()
    
    print("""
🎉 Setup Complete!

You now have Unison running locally. The platform includes:
- 15+ microservices working together
- Real-time context understanding
- Natural language processing
- Dynamic experience generation

Next: Open your browser to http://localhost:3000 and start exploring!

🌟 Welcome to the Unison community!
""")

if __name__ == "__main__":
    main()
