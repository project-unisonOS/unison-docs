# Project Unison – Feature Matrix

## Overview
Project Unison’s value lies in how its modular architecture translates into natural, adaptive experiences for people.  
This document connects what people experience to the services and subsystems that make it possible.

## Summary Table

| Feature | Person’s experience | Backing subsystems |
|----------|--------------------|--------------------|
| **Conversational onboarding** | On first startup, Unison introduces itself, explains what it can do, and helps connect components through natural conversation. | Orchestrator, Context, Policy, I/O layer |
| **Natural multimodal interaction** | People can speak, show, type, or gesture—Unison understands and responds across media. | I/O layer, Orchestrator, Policy |
| **Context-aware assistance** | Unison remembers preferences, environment, and prior exchanges to respond with increasing relevance. | Context, Storage, Orchestrator |
| **Adaptive output surface** | Responses appear in the form that suits the situation—spoken, visual, haptic, or text—automatically adjusting to ability and environment. | Orchestrator, Context, I/O renderers |
| **Safe action execution** | Before any significant action, Unison describes what will happen, requests consent if needed, or declines unsafe requests. | Policy, Orchestrator, Storage |
| **Local-first privacy** | Personal information and memories remain on the device. Cloud use is optional and person-controlled. | Storage, Context, Local inference engines, Orchestrator |
| **Orchestrated reasoning** | Unison performs multi-step tasks autonomously (“Find a pharmacy, check inventory, guide me there”). | Orchestrator, Policy, Context, External APIs |
| **Extensible capabilities** | New abilities can be added dynamically—no app installs. | Orchestrator, Policy, EventEnvelope spec |
| **Cloud or local model choice** | People choose whether Unison uses local inference accelerators or external AI APIs for generation. | Orchestrator, Context, External inference services |
| **Self-introspection** | Unison can describe its own configuration—connected I/O, available skills, and model options—and guide people through setup or troubleshooting. | Orchestrator, Policy, I/O registry, Context |

---

## Narrative Detail

### Conversational onboarding
At first startup, Unison behaves like meeting a capable friend. It speaks naturally, describes its abilities, and begins gathering context.  
> “If you connect a camera, I can recognize you automatically.”  
> “Would you like me to remember this device for next time?”  
Each interaction builds comfort and trust while maintaining transparency about what data is stored and why.

### Natural multimodal interaction
Unison interprets speech, text, gestures, and images as equally valid inputs.  
This multimodality dissolves the barrier between talking to technology and operating it.

### Context-aware assistance
Unison keeps relevant details—preferences, tasks in progress, and accessibility settings—within its local context store. It uses this knowledge to adapt tone, brevity, and modality automatically.

### Adaptive output surface
Instead of fixed UI components, Unison’s Orchestrator and I/O renderers generate interfaces dynamically, producing accessible responses in the best-suited format for the current state.

### Safe action execution
All high-impact requests are evaluated by the Policy service.  
Unison can explain what it is about to do, request confirmation, or decline based on consent rules or safety policy.  
This protects privacy, security, and human intent.

### Local-first privacy
Unison prioritizes on-device computation. Context and storage remain partitioned and encrypted locally.  
Cloud augmentation is optional and transparent—people always know when data leaves the device and can choose alternative local inference paths.

### Orchestrated reasoning
The Orchestrator decomposes complex intents into actionable steps, calling context and external APIs as needed.  
Each step is policy-checked before execution, maintaining continuity and compliance.

### Extensible capabilities
Capabilities—such as navigation, accessibility services, or creative tools—are modular plug-ins bound to EventEnvelope contracts.  
This creates an ecosystem where contributors can extend functionality without reengineering the system core.

### Cloud or local model choice
People can decide whether to use high-performance local inference or external AI APIs, balancing privacy, speed, and accuracy.  
This makes Unison adaptable from offline edge devices to cloud-augmented environments.

### Self-introspection
Every Unison instance is aware of its own configuration. It can describe connected peripherals, available I/O modes, and skill registry status.  
This enables conversational setup:  
> “I see your microphone is active, but your camera isn’t connected. Would you like to enable it?”  
Self-awareness improves transparency, reduces technical friction, and reinforces trust.
