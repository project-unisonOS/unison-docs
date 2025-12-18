# Unified Messaging Protocol (UMP) Specification

## Version 1.0

### Overview

The Unified Messaging Protocol (UMP) is a core component of Unison's intent orchestration environment that revolutionizes communication by focusing on intent rather than channels. UMP coordinates intent-driven communication across multiple channels, dynamically selecting optimal delivery methods based on recipient context, consent, and preferences.

### Purpose

- **Intent Resolution**: Analyzes communication intent and requirements
- **Dynamic Channel Selection**: Chooses optimal delivery channels based on context
- **Transport Abstraction**: Handles email, chat, voice, and modern protocols seamlessly
- **Delivery Confirmation**: Tracks and confirms intent fulfillment
- **Consent Management**: Ensures privacy-aware communication

### Implementation surface (current)

- Normalized message shape (channel-agnostic):
  - `channel`, `participants[] {address, role}`, `subject`, `body`, `thread_id`, `message_id`, `context_tags`, `metadata`.
- Comms actions are exposed by `unison-comms`, but **planners MUST execute them via the Capability Resolver** (`unison-capability`) as manifest-declared capabilities (planner contract).
  - `unison-comms` may retain a legacy HTTP surface (`/comms/*`) for compatibility, but direct planner → comms execution is not the target architecture.
  - Connectors/adapters remain edge-first; secrets are stored outside manifests and referenced by handles.

## Core Concepts

### Intent Types

UMP recognizes and processes four primary communication intents:

#### 1. Inform Intent
**Purpose**: Share information without requiring action
**Examples**:
- "Inform the team about the project status"
- "Let Sarah know the meeting is rescheduled"
- "Notify everyone about the system update"

#### 2. Request Intent  
**Purpose**: Ask for information, action, or response
**Examples**:
- "Request approval for the budget proposal"
- "Ask the team for their availability"
- "Get feedback on the presentation draft"

#### 3. Invite Intent
**Purpose**: Invite participation in events or activities
**Examples**:
- "Invite stakeholders to the review meeting"
- "Invite the team to the planning session"
- "Invite Sarah to collaborate on the document"

#### 4. Coordinate Intent
**Purpose**: Organize and align multiple people or activities
**Examples**:
- "Coordinate the product launch timeline"
- "Align with marketing on the campaign strategy"
- "Coordinate with development on the release schedule"

### Delivery Channels

UMP supports multiple delivery channels with automatic selection:

#### Primary Channels
- **Email**: Traditional email with rich formatting
- **Chat**: Real-time messaging (Slack, Teams, Matrix)
- **Workspace**: Collaborative workspace updates
- **Voice**: Audio messages and voice calls
- **SMS**: Text messages for urgent communications

#### Modern Protocols
- **Matrix**: Decentralized secure messaging
- **ActivityPub**: Federated social communication
- **WebSocket**: Real-time web communication
- **Webhook**: Programmatic delivery to systems

#### Fallback Transports
- **SMTP**: Standard email protocol
- **SMS Gateway**: Text message delivery
- **Push Notifications**: Mobile device notifications
- **Postal Mail**: Physical mail for critical communications

## Protocol Specification

### Message Structure

#### UMP Message Format
```json
{
  "ump_version": "1.0",
  "message_id": "ump-msg-uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "sender": {
    "person_id": "person-123",
    "name": "Alex Chen",
    "role": "project_manager",
    "authentication": {
      "method": "jwt",
      "token": "jwt-token-hash",
      "scope": "communication"
    }
  },
  "intent": {
    "type": "coordinate",
    "description": "Coordinate with the team about the project deadline",
    "priority": "high",
    "urgency": "time_sensitive",
    "expected_response": "confirmation"
  },
  "recipients": [
    {
      "person_id": "person-456",
      "name": "Sarah Johnson",
      "context": {
        "current_location": "office",
        "device_available": "desktop",
        "attention_state": "available",
        "communication_preferences": {
          "preferred_channels": ["workspace", "email"],
          "response_expectation": "same_day",
          "interruption_tolerance": "work_hours"
        }
      },
      "consent": {
        "marketing_communications": false,
        "work_communications": true,
        "urgent_communications": true,
        "after_hours": "emergency_only"
      }
    }
  ],
  "content": {
    "subject": "Project Deadline Coordination",
    "body": {
      "summary": "We need to coordinate the project deadline for the client deliverable due next week.",
      "details": "The client has requested the deliverable by Friday, but we need to ensure all team members can meet this timeline. Please review your current workload and availability.",
      "action_items": [
        "Review current task assignments",
        "Confirm availability for deadline",
        "Report any blocking issues"
      ],
      "attachments": [
        {
          "type": "document",
          "name": "project_timeline.pdf",
          "url": "https://unison.example.com/docs/timeline.pdf"
        }
      ]
    },
    "formatting": {
      "style": "professional",
      "length": "concise",
      "visual_elements": true,
      "language": "en"
    }
  },
  "delivery_strategy": {
    "primary_channel": "workspace",
    "secondary_channels": ["email"],
    "fallback_channels": ["sms"],
    "timing": {
      "delivery_time": "2024-01-01T12:00:00Z",
      "follow_up_time": "2024-01-01T16:00:00Z",
      "expiry_time": "2024-01-03T12:00:00Z"
    },
    "confirmation_required": true
  },
  "tracking": {
    "delivery_status": "pending",
    "read_status": "pending",
    "response_status": "pending",
    "delivery_attempts": 0,
    "last_attempt": null
  }
}
```

### API Endpoints

#### Send Message
```http
POST /api/v1/messages/send
Content-Type: application/json
Authorization: Bearer {jwt-token}

{
  "message": { /* UMP Message Format */ }
}
```

**Response**:
```json
{
  "message_id": "ump-msg-uuid-v4",
  "status": "queued",
  "estimated_delivery": "2024-01-01T12:01:00Z",
  "delivery_plan": {
    "primary_channel": "workspace",
    "backup_channels": ["email"],
    "delivery_schedule": [
      {
        "channel": "workspace",
        "attempt_time": "2024-01-01T12:00:00Z"
      },
      {
        "channel": "email", 
        "attempt_time": "2024-01-01T12:30:00Z"
      }
    ]
  }
}
```

#### Get Message Status
```http
GET /api/v1/messages/{message_id}/status
Authorization: Bearer {jwt-token}
```

**Response**:
```json
{
  "message_id": "ump-msg-uuid-v4",
  "status": "delivered",
  "delivery_details": [
    {
      "recipient_id": "person-456",
      "channel": "workspace",
      "status": "delivered",
      "delivered_at": "2024-01-01T12:00:45Z",
      "read_at": "2024-01-01T12:05:30Z",
      "response_received": "2024-01-01T14:30:00Z"
    }
  ],
  "confirmation_status": "complete"
}
```

#### Update Consent Preferences
```http
PUT /api/v1/people/{person_id}/consent
Content-Type: application/json
Authorization: Bearer {jwt-token}

{
  "consent_preferences": {
    "work_communications": true,
    "marketing_communications": false,
    "urgent_communications": true,
    "after_hours": "emergency_only",
    "preferred_channels": ["workspace", "email"],
    "blocked_senders": [],
    "quiet_hours": {
      "start": "18:00",
      "end": "08:00",
      "timezone": "America/Los_Angeles"
    }
  }
}
```

## Channel Selection Algorithm

### Decision Matrix
```python
class ChannelSelector:
    def select_optimal_channel(self, recipient, intent, content):
        # 1. Evaluate recipient context and preferences
        context_score = self.evaluate_context(recipient)
        
        # 2. Check consent compliance
        consent_check = self.verify_consent(recipient, intent)
        
        # 3. Score available channels
        channel_scores = {}
        for channel in self.get_available_channels(recipient):
            score = self.score_channel(
                channel, 
                recipient, 
                intent, 
                content
            )
            channel_scores[channel] = score
        
        # 4. Apply timing and urgency factors
        adjusted_scores = self.apply_timing_factors(
            channel_scores, 
            intent.urgency
        )
        
        # 5. Select primary and backup channels
        return self.select_channels(adjusted_scores)
    
    def score_channel(self, channel, recipient, intent, content):
        base_score = 0.0
        
        # Context appropriateness (40% weight)
        if channel in recipient.preferred_channels:
            base_score += 0.4
        elif channel in recipient.acceptable_channels:
            base_score += 0.2
            
        # Intent compatibility (30% weight)
        if self.intent_supports_channel(intent, channel):
            base_score += 0.3
            
        # Content suitability (20% weight)
        if self.content_fits_channel(content, channel):
            base_score += 0.2
            
        # Availability (10% weight)
        if self.is_channel_available(recipient, channel):
            base_score += 0.1
            
        return base_score
```

### Channel Selection Rules

#### Inform Intent
- **Primary**: Workspace, Email
- **Secondary**: Chat, SMS
- **Factors**: Content length, attachment requirements, recipient preferences

#### Request Intent
- **Primary**: Workspace, Chat
- **Secondary**: Email, Voice
- **Factors**: Urgency, response expectation, real-time requirements

#### Invite Intent
- **Primary**: Email, Workspace
- **Secondary**: Chat, Calendar integration
- **Factors**: Formality level, advance notice, RSVP requirements

#### Coordinate Intent
- **Primary**: Workspace, Email
- **Secondary**: Chat, Voice
- **Factors**: Number of recipients, complexity, real-time coordination needs

## Transport Implementations

### Email Transport
```python
class EmailTransport:
    def deliver(self, message, recipient):
        # 1. Format message for email
        email_content = self.format_for_email(message.content)
        
        # 2. Apply email-specific styling
        styled_email = self.apply_email_styling(email_content)
        
        # 3. Send via SMTP or API
        delivery_result = self.send_email(
            recipient.email_address,
            styled_email
        )
        
        # 4. Track delivery status
        return self.track_delivery(delivery_result)
```

### Chat Transport
```python
class ChatTransport:
    def deliver(self, message, recipient, platform):
        # 1. Adapt message for chat platform
        chat_content = self.format_for_chat(message.content, platform)
        
        # 2. Add interactive elements if supported
        enhanced_content = self.add_interactive_elements(
            chat_content, 
            platform
        )
        
        # 3. Send via platform API
        delivery_result = self.send_via_platform(
            recipient.platform_id,
            enhanced_content,
            platform
        )
        
        # 4. Monitor for read receipts
        return self.monitor_chat_delivery(delivery_result)
```

### Voice Transport
```python
class VoiceTransport:
    def deliver(self, message, recipient):
        # 1. Convert text to speech
        audio_content = self.text_to_speech(message.content.body)
        
        # 2. Optimize for voice delivery
        optimized_audio = self.optimize_for_voice(audio_content)
        
        # 3. Deliver via phone call or voice message
        delivery_result = self.deliver_voice_call(
            recipient.phone_number,
            optimized_audio
        )
        
        # 4. Track call completion
        return self.track_call_status(delivery_result)
```

## Consent Management

### Consent Model
```json
{
  "person_id": "person-456",
  "consent_profile": {
    "communication_types": {
      "work_communications": {
        "allowed": true,
        "channels": ["workspace", "email", "chat"],
        "hours": {
          "start": "08:00",
          "end": "18:00",
          "timezone": "America/Los_Angeles",
          "weekends": false
        }
      },
      "marketing_communications": {
        "allowed": false,
        "channels": [],
        "hours": {}
      },
      "urgent_communications": {
        "allowed": true,
        "channels": ["sms", "phone", "push"],
        "hours": "24/7"
      }
    },
    "sender_preferences": {
      "blocked_senders": [],
      "preferred_senders": ["manager", "team_lead"],
      "require_approval": ["external", "unknown"]
    },
    "content_preferences": {
      "max_length": "medium",
      "visual_elements": true,
      "attachments": "work_related_only",
      "language": "en"
    },
    "privacy_settings": {
      "read_receipts": true,
      "delivery_confirmation": true,
      "analytics_sharing": false,
      "data_retention": "30_days"
    }
  }
}
```

### Consent Validation
```python
class ConsentValidator:
    def validate_communication(self, message, recipient):
        # 1. Check communication type consent
        if not self.has_type_consent(recipient, message.intent):
            return ConsentResult.DENIED
        
        # 2. Verify time window compliance
        if not self.is_within_allowed_hours(recipient, message):
            return ConsentResult.DELAYED
        
        # 3. Check sender permissions
        if not self.is_sender_allowed(recipient, message.sender):
            return ConsentResult.REQUIRES_APPROVAL
        
        # 4. Validate content preferences
        if not self.is_content_compliant(recipient, message.content):
            return ConsentResult.MODIFIED
        
        return ConsentResult.ALLOWED
```

## Delivery Confirmation

### Confirmation Types
- **Delivery Confirmation**: Message successfully delivered to channel
- **Read Confirmation**: Recipient has opened/read the message
- **Response Confirmation**: Recipient has responded as expected
- **Intent Fulfillment**: Communication intent has been achieved

### Confirmation Tracking
```json
{
  "message_id": "ump-msg-uuid-v4",
  "confirmation_tracking": {
    "delivery_confirmations": [
      {
        "recipient_id": "person-456",
        "channel": "workspace",
        "delivered_at": "2024-01-01T12:00:45Z",
        "delivery_method": "api_push",
        "status": "success"
      }
    ],
    "read_confirmations": [
      {
        "recipient_id": "person-456",
        "read_at": "2024-01-01T12:05:30Z",
        "read_duration": "45s",
        "device": "desktop"
      }
    ],
    "response_confirmations": [
      {
        "recipient_id": "person-456",
        "response_type": "confirmation",
        "responded_at": "2024-01-01T14:30:00Z",
        "response_content": "Confirmed availability for deadline"
      }
    ],
    "intent_fulfillment": {
      "status": "achieved",
      "achieved_at": "2024-01-01T16:45:00Z",
      "outcome": "team_coordinated_deadline_successfully"
    }
  }
}
```

## Security and Privacy

### Message Security
- **End-to-End Encryption**: Messages encrypted in transit and at rest
- **Digital Signatures**: Sender authentication and message integrity
- **Access Controls**: Role-based access to messaging capabilities
- **Audit Logging**: Complete audit trail for compliance

### Privacy Protection
- **Data Minimization**: Only collect necessary communication data
- **Consent Enforcement**: Strict adherence to consent preferences
- **Anonymization**: Analytics data anonymized for privacy
- **Right to Deletion**: Complete data removal on request

### Compliance Standards
- **GDPR**: Full compliance with EU data protection regulations
- **CCPA**: Compliance with California privacy laws
- **HIPAA**: Available for healthcare communications (optional)
- **SOC 2**: Security and compliance certifications

## Performance and Scalability

### Throughput Targets
- **Message Processing**: 10,000 messages/second
- **Delivery Latency**: < 5 seconds for primary channels
- **Confirmation Tracking**: < 1 second for status updates
- **Consent Validation**: < 100ms per request

### Scaling Architecture
```yaml
deployment:
  message_processors:
    replicas: 10
    cpu_limit: "2"
    memory_limit: "4Gi"
    
  delivery_workers:
    replicas: 20
    cpu_limit: "1"
    memory_limit: "2Gi"
    
  tracking_service:
    replicas: 5
    cpu_limit: "500m"
    memory_limit: "1Gi"
    
  consent_service:
    replicas: 3
    cpu_limit: "500m"
    memory_limit: "1Gi"
```

## Integration with Unison Services

### Intent Graph Service
- Receives communication intent requirements
- Provides goal context for message prioritization
- Updates intent status based on communication outcomes

### Context Graph Service
- Supplies recipient context for channel selection
- Provides environmental constraints for delivery timing
- Offers preference data for message personalization

### Orchestrator Service
- Coordinates multi-channel delivery strategies
- Handles communication workflow orchestration
- Manages escalation and fallback procedures

### Experience Rendering Engine
- Receives communication status for experience updates
- Provides delivery confirmation interfaces
- Coordinates communication with broader experience flows

## Implementation Guidelines

### Service Configuration
```bash
# UMP Service Configuration
UMP_SERVICE_PORT=8084
UMP_SERVICE_HOST=0.0.0.0

# Transport Configuration
SMTP_SERVER=smtp.example.com:587
CHAT_API_KEYS_SLACK=xoxb-your-slack-token
CHAT_API_KEYS_TEAMS=your-teams-token
SMS_PROVIDER=twilio
VOICE_PROVIDER=twilio

# Security Configuration
JWT_SECRET=your-jwt-secret
ENCRYPTION_KEY=your-encryption-key
CONSENT_DB_URL=postgresql://user:pass@postgres:5432/ump_consent

# External Services
INTENT_GRAPH_URL=http://unison-intent-graph:8080
CONTEXT_GRAPH_URL=http://unison-context-graph:8081
ORCHESTRATOR_URL=http://unison-orchestrator:8080
```

### Monitoring and Observability
- **Message Metrics**: Volume, delivery rates, response times
- **Channel Performance**: Success rates by channel and recipient type
- **Consent Compliance**: Consent validation success and violations
- **Security Events**: Authentication failures, unauthorized access attempts

---

The Unified Messaging Protocol transforms communication from channel-centric to intent-centric, ensuring that every message reaches its audience through the optimal path while respecting privacy, consent, and individual preferences.
