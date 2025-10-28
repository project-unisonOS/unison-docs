# User Journey 04 – Onboarding and Self-Awareness: “First-Time Startup Experience”

## Scenario Summary

A person powers on a device running Unison for the first time.  
Within seconds, Unison greets them using clear audio, subtle LED patterns, and on-screen text in the person’s preferred language.  
It detects available input/output components, confirms what it can currently do, and invites the person to personalize preferences — all without forms or menus.

---

## Step-by-Step Experience

1. **Power-on acknowledgment**
   - The device emits a gentle chime and a pulse of white light across its LED ring, signaling readiness.  
   - A calm voice begins:  
     > “Hello. I’m Unison. I’m running for the first time on this device. Let’s get to know each other.”  

2. **Automatic language detection**
   - Unison samples a few seconds of background speech or uses region settings to infer the local language.  
   - It responds accordingly, adjusting both spoken and displayed language dynamically.  
     > “It sounds like you prefer English. Would you like me to continue in English, or switch to another language?”  

3. **Hardware self-check**
   - Unison queries all connected I/O modules: microphone, speaker, display, camera, sensors, and network interfaces.  
   - LED flashes briefly as each component is confirmed.  
   - Then Unison summarizes:  
     > “I can see your display and hear through this microphone. I don’t detect a camera yet, but you can connect one anytime.”  

4. **Privacy introduction**
   - Unison explains its privacy defaults and partitioned local storage:  
     > “Your data stays on this device by default. I’ll ask before sending anything to the cloud. You can review or delete your data at any time.”  

5. **Context profile creation**
   - Unison begins forming the person’s first context profile — assigning a unique local identifier, default memory partition, and language preference.  
   - Example acknowledgment:  
     > “I’ve set up your workspace and will learn from what you share. You can name this device if you’d like.”  

6. **Optional component setup**
   - Unison offers to enable or connect additional peripherals:  
     > “If you connect a camera, I’ll be able to recognize you automatically. If you pair your headset, I can guide you privately.”  

7. **Completion and confirmation**
   - LED glows steady white.  
   - Voice output:  
     > “Setup is complete. You can start by asking me to do something—like summarize a document or describe what’s on your screen.”  

---

## System Flow (EventEnvelope Trace)

| Stage | Intent | Source → Destination | Payload Summary | Notes |
|--------|---------|----------------------|-----------------|-------|
| 1 | `system.boot_detect` | Hardware Sensors → Orchestrator | Power-on event | Initiates startup sequence |
| 2 | `system.language_detect` | Audio Input / Region Data → Orchestrator | Speech sample, locale | Determines language |
| 3 | `io.self_check` | Orchestrator → I/O Registry | Component inventory | Identifies available interfaces |
| 4 | `policy.initialize` | Orchestrator → Policy | Load default privacy and consent policies | Security baseline |
| 5 | `context.initialize` | Orchestrator → Context | Create default user partition | Persistent memory setup |
| 6 | `io.notify_status` | Orchestrator → I/O Renderer | LED and chime sequence | Multimodal feedback |
| 7 | `onboarding.complete` | Orchestrator → Context / Policy | Store onboarding completion | Enables normal operation |

---

## Design Notes

- **Helpful colleague tone:** Language is conversational but professional — informative, never overly familiar.  
- **Multimodal onboarding:** LED and chime cues supplement voice and text for accessibility and reliability.  
- **Immediate language adaptation:** Unison detects local language and responds appropriately before setup continues.  
- **Transparency from the start:** People learn what Unison can see, hear, and store before giving commands.  
- **Self-awareness:** Unison knows its capabilities and can describe them clearly, guiding setup interactively.  
- **Privacy by design:** Data partitioning and explicit consent policy are introduced during onboarding, not after.  
- **Accessibility alignment:** The same information is available audibly, visually, and tactilely from the start-up phase.
