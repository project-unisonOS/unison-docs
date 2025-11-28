# System Architecture

## Overview
Unison is a local-first adaptive computing environment. The system renders experiences in real time instead of launching traditional apps.

## Core modules
1. `unison-context` - Tracks live user state, preferences, environment signals, and session memory. Exposes a query and subscription API.
2. `unison-orchestrator` - Decision layer. Interprets intent, routes work to skills, requests generation, and maintains task flow.
3. `unison-io-*` - Interfaces to the human and physical world.
4. `unison-gen` - Local inference and generation. Text, vision, audio, UI synthesis.
5. `unison-skills` - Deterministic capability modules.
6. `unison-policy` - Trust, consent, safety, privacy, and audit.
7. `unison-storage` - Working memory, long-term memory, secure vault.
8. `unison-hal` - Hardware abstraction.
9. `unison-os` - Base runtime image and boot flow.
