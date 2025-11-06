# Quick Start Guide 🚀

> **Get Unison running in minutes, not hours**

---

## ⚡ 5-Minute Quick Start

### 🌐 Option 1: Try Online (Fastest)

1. **Open your browser** → [demo.unisonos.org](https://demo.unisonos.org)
2. **Type or say**: "Hello Unison, what can you do?"
3. **Explore**: Try different requests like:
   - "Help me plan my day"
   - "Show me my recent activities"
   - "Play some focus music"

**That's it!** You're experiencing Unison right now. 🎉

---

## 🏠 15-Minute Local Setup

### Prerequisites Check

```bash
# Verify you have Docker
docker --version
# Should show: Docker version 20.x.x or higher

# Verify you have Docker Compose
docker-compose --version
# Should show: docker-compose version 2.x.x or higher
```

**Don't have Docker?** [Install Docker](https://docs.docker.com/get-docker/) (5 minutes)

### One-Command Setup

```bash
# Step 1: Get the code
git clone https://github.com/unison-platform/unison.git
cd unison

# Step 2: Start the platform
make up

# Step 3: Wait for startup (2-3 minutes)
# You'll see "✅ All services are healthy" when ready

# Step 4: Open your browser
open http://localhost:3000
# or visit http://localhost:3000 manually
```

### Verify It's Working

You should see:
- ✅ **Unison Interface**: Welcome screen with chat interface
- ✅ **Health Dashboard**: All 15+ services running
- ✅ **Example Scenarios**: Ready-to-try demo scenarios

**Try these commands:**
- "What's the weather like?"
- "Show me my files"
- "Help me organize my week"

---

## 🔧 If Something Goes Wrong

### Common Issues & Quick Fixes

#### Port Already in Use
```bash
# Error: "Port 3000 is already in use"
# Fix: Kill the process or use a different port
lsof -ti:3000 | xargs kill -9
# Then run: make up again
```

#### Docker Issues
```bash
# Error: "Docker daemon not running"
# Fix: Start Docker Desktop or Docker service
# On Mac: Open Docker Desktop app
# On Linux: sudo systemctl start docker
```

#### Memory Issues
```bash
# Error: "Out of memory" or services keep restarting
# Fix: Increase Docker memory allocation
# Docker Desktop → Settings → Resources → Memory → 8GB+
```

#### Network Issues
```bash
# Error: "Services can't connect to each other"
# Fix: Reset Docker network
docker network prune
make down
make up
```

### Get Help Fast

- **📋 Check Health**: Visit http://localhost:3000/health
- **🔍 View Logs**: `make logs` or `docker-compose logs -f`
- **💬 Get Help**: [Discord Community](https://discord.gg/unison)
- **🐛 Report Issues**: [GitHub Issues](https://github.com/unison-platform/unison/issues)

---

## 🎯 Your First 10 Minutes

### Explore the Interface

1. **Chat Interface**: Main interaction point
2. **Context Panel**: Shows what Unison knows about you
3. **Skills Panel**: Available capabilities
4. **Settings**: Personalization options

### Try These Scenarios

#### 🌅 Morning Routine
```
You: "Good morning Unison"

Unison: "Good morning! I see you have a team standup at 9 AM. 
I've prepared your calendar and organized your priority emails. 
Would you like me to start your focus playlist?"
```

#### 💻 Work Mode
```
You: "I need to work on the presentation"

Unison: "I'll help you focus. I've opened your presentation files, 
silenced notifications, and set a 25-minute focus timer. 
Need any research or data for the presentation?"
```

#### 🏠 Personal Assistant
```
You: "What's my schedule today?"

Unison: "You have 3 meetings and 2 deadlines. 
I've prioritized your tasks and suggested optimal break times. 
Should I order lunch for your 12:30 break?"
```

---

## 🛠️ Customize Your Experience

### Set Your Preferences

1. **Click Settings** (gear icon)
2. **Configure**:
   - **Name**: How Unison addresses you
   - **Voice**: Preferred voice and accent
   - **Theme**: Light, dark, or auto
   - **Notifications**: When and how Unison interrupts
   - **Privacy**: What data Unison can use

### Add Your Data

1. **Connect Calendar**: Google Calendar, Outlook
2. **Connect Files**: Google Drive, OneDrive, local files
3. **Set Location**: Home, work, or auto-detect
4. **Configure Work Hours**: When you're typically working

---

## 📊 What's Running Under the Hood

When you run `make up`, you're starting:

| Service | Purpose | URL |
|---------|---------|-----|
| **Unison Core** | Main interface | http://localhost:3000 |
| **Context Graph** | Environment understanding | http://localhost:8081 |
| **Intent Graph** | Natural language processing | http://localhost:8080 |
| **Experience Renderer** | Dynamic UI generation | http://localhost:8082 |
| **Health Monitor** | System status | http://localhost:3000/health |

### Monitor Performance

```bash
# Check all services
make health

# View real-time logs
make logs

# Restart specific service
make restart service=context-graph

# Stop everything
make down
```

---

## 🚀 Next Steps

### For Exploration
- **Try Scenarios**: Click "Scenarios" in the interface
- **Test Voice**: Enable voice interaction in settings
- **Explore Skills**: Browse available capabilities

### For Development
- **Read Developer Guide**: [Development docs](../developer/getting-started.md)
- **Examine Code**: Look at the service architectures
- **Build Skills**: Create custom capabilities

### For Production
- **Security Setup**: Configure authentication and authorization
- **Scaling**: Adjust resource limits and clustering
- **Monitoring**: Set up observability and alerting

---

## 🎉 Success! You're Running Unison

### What You've Accomplished
- ✅ **Deployed 15+ microservices** working together
- ✅ **Experienced adaptive interfaces** that respond to context
- ✅ **Seen natural language understanding** in action
- ✅ **Configured personalization** and privacy settings
- ✅ **Joined the future** of human-computer interaction

### Keep Going

1. **Explore More**: Try advanced scenarios and features
2. **Join Community**: Connect with other Unison users
3. **Contribute**: Help improve the platform
4. **Deploy**: Set up Unison for your team or organization

---

## 📞 Need Help?

### Instant Help
- **📋 In-App Help**: Click the help icon in Unison
- **🔍 Health Check**: http://localhost:3000/health
- **📊 System Status**: http://localhost:3000/status

### Community Support
- **💬 Discord**: [Join 24/7 community chat](https://discord.gg/unison)
- **📧 Email**: support@unisonos.org
- **🐛 Issues**: [Report on GitHub](https://github.com/unison-platform/unison/issues)

### Resources
- **📖 Full Docs**: [Documentation hub](https://docs.unisonos.org)
- **🎓 Tutorials**: [Step-by-step guides](https://learn.unisonos.org)
- **🎬 Videos**: [Demo videos](https://youtube.com/c/unisonplatform)

---

**Welcome to the Unison community!** 🌟

*You're now part of the movement to make technology adapt to humans, not the other way around.*

---

*Quick Start Guide | Version 1.0 | Updated: January 2025*
