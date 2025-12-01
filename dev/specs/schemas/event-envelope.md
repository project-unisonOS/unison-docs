# EventEnvelope Schema v2.0 - Intent Orchestration

## Overview

The EventEnvelope v2.0 schema extends the original message format to support Unison's real-time intent orchestration environment. This enhanced schema carries intent graphs, context data, and experience generation requirements while maintaining backward compatibility with the original specification.

## Schema Definition

### Base EventEnvelope Structure

```json
{
  "schema_version": "2.0",
  "id": "uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "source": "service-name",
  "event_type": "intent.expression",
  "correlation_id": "uuid-v4",
  "causation_id": "uuid-v4"
}
```

### Capability Report Event (example)

Use the same envelope shape to report detected peripherals at startup (see `../../startup-modality.md`):

```json
{
  "schema_version": "2.0",
  "id": "uuid-v4",
  "timestamp": "2025-01-01T00:00:00Z",
  "source": "io-core",
  "event_type": "caps.report",
  "correlation_id": "uuid-v4",
  "payload": {
    "person_id": "local-user",
    "caps": {
      "audio_in": {"present": true, "confidence": 0.9},
      "audio_out": {"present": true, "confidence": 0.9},
      "display": {"present": true, "confidence": 0.8},
      "camera": {"present": false},
      "sign_adapter": {"present": false},
      "bci_adapter": {"present": false},
      "wakeword": {"present": true},
      "locale_hint": "en-US"
    }
  }
}
```

This event primes the orchestrator/intent-graph with available modalities so the initial prompt can branch to voice-only or display+voice flows.

### Intent Orchestration Extension

```json
{
  "schema_version": "2.0",
  "id": "uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "source": "speech-intent",
  "event_type": "intent.expression",
  "correlation_id": "uuid-v4",
  "causation_id": "uuid-v4",
  
  "intent": {
    "type": "user.goal.synthesis",
    "expression": "Show me the current budget status",
    "classification": {
      "primary_intent": "analytical",
      "secondary_intent": "informational",
      "confidence": 0.92,
      "model_version": "intent-classifier-v3.1"
    },
    "parameters": {
      "outcome_requested": "budget_dashboard",
      "analysis_depth": "comprehensive",
      "time_range": "current_quarter"
    },
    "priority": "normal",
    "urgency": "low"
  },
  
  "person": {
    "id": "person-123",
    "session_id": "session-456",
    "authentication": {
      "method": "jwt",
      "token_hash": "sha256-hash",
      "permissions": ["read", "analyze", "export"]
    }
  },
  
  "context": {
    "environmental": {
      "location": "office",
      "device": "desktop",
      "time_of_day": "morning",
      "activity_state": "work"
    },
    "preferences": {
      "modality": "visual",
      "data_density": "high",
      "interaction_style": "interactive"
    },
    "temporal": {
      "local_time": "09:00",
      "timezone": "America/Los_Angeles",
      "business_hours": true
    },
    "fusion_timestamp": "2024-01-01T12:00:01Z",
    "confidence_score": 0.87
  },
  
  "intent_graph": {
    "primary_goal": {
      "id": "goal-001",
      "description": "Analyze current budget status",
      "type": "analytical",
      "priority": "normal",
      "estimated_duration": "5m"
    },
    "sub_goals": [
      {
        "id": "goal-001-1",
        "description": "Collect budget data",
        "type": "data_collection",
        "dependencies": [],
        "estimated_duration": "2m"
      },
      {
        "id": "goal-001-2",
        "description": "Generate visual dashboard",
        "type": "visualization",
        "dependencies": ["goal-001-1"],
        "estimated_duration": "2m"
      },
      {
        "id": "goal-001-3",
        "description": "Provide insights and analysis",
        "type": "reasoning",
        "dependencies": ["goal-001-2"],
        "estimated_duration": "1m"
      }
    ],
    "execution_plan": {
      "strategy": "parallel_where_possible",
      "resource_requirements": {
        "skills": ["data_analysis", "visualization"],
        "inference": ["text_generation", "chart_generation"],
        "data_sources": ["financial_db", "budget_api"]
      }
    }
  },
  
  "experience_requirements": {
    "preferred_modalities": ["visual", "text"],
    "interface_type": "dashboard",
    "interaction_level": "interactive",
    "personalization": {
      "visual_style": "professional",
      "data_density": "high",
      "animation_level": "subtle"
    },
    "accessibility": {
      "screen_reader_support": true,
      "high_contrast": false,
      "font_scaling": 1.0
    }
  },
  
  "payload": {
    "raw_intent": "Show me the current budget status",
    "extracted_entities": [
      {
        "type": "financial_metric",
        "value": "budget",
        "confidence": 0.95
      },
      {
        "type": "time_reference",
        "value": "current",
        "confidence": 0.89
      }
    ],
    "semantic_analysis": {
      "sentiment": "neutral",
      "complexity": "medium",
      "domain": "finance"
    }
  },
  
  "routing": {
    "target_services": [
      "unison-intent-graph",
      "unison-context-graph",
      "unison-experience-renderer"
    ],
    "execution_order": [
      "unison-intent-graph",
      "unison-context-graph",
      "unison-experience-renderer"
    ],
    "fallback_services": [
      "unison-skills",
      "unison-inference"
    ]
  },
  
  "auth_scope": "read",
  "safety_context": {
    "content_type": "financial",
    "sensitivity_level": "confidential",
    "consent_level": "explicit",
    "policy_constraints": [
      "data_privacy",
      "financial_compliance"
    ]
  },
  
  "metadata": {
    "processing_latency_ms": 150,
    "confidence_threshold_met": true,
    "requires_human_review": false,
    "escalation_triggered": false
  }
}
```

## Event Types

### Intent Expression Events
- `intent.expression` - Natural language intent from user
- `intent.refinement` - Refined intent after clarification
- `intent.modification` - User-requested changes to intent
- `intent.cancellation` - User cancels current intent

### Goal Processing Events
- `goal.decomposed` - Intent broken down into sub-goals
- `goal.scheduled` - Goals scheduled for execution
- `goal.started` - Goal execution initiated
- `goal.completed` - Goal successfully completed
- `goal.failed` - Goal execution failed
- `goal.blocked` - Goal blocked by dependencies

### Experience Generation Events
- `experience.requested` - Experience generation initiated
- `experience.generated` - Experience successfully generated
- `experience.rendered` - Experience displayed to user
- `experience.adapted` - Experience adapted based on feedback
- `experience.completed` - User interaction with experience complete

### Context Update Events
- `context.updated` - Context information updated
- `context.changed` - Significant context change detected
- `preferences.updated` - User preferences modified
- `environment.changed` - Environmental context updated

### Communication Events
- `communication.intent` - Communication intent expressed
- `communication.sent` - Message sent via UMP
- `communication.delivered` - Message successfully delivered
- `communication.responded` - Response received from recipient

## Service-Specific Extensions

### Intent Graph Service Events
```json
{
  "event_type": "goal.decomposed",
  "intent_graph": {
    "decomposition_timestamp": "2024-01-01T12:00:05Z",
    "algorithm_version": "decomposer-v2.1",
    "confidence_score": 0.91,
    "optimization_applied": "resource_balancing"
  },
  "processing_metadata": {
    "decomposition_latency_ms": 200,
    "sub_goals_generated": 3,
    "dependencies_resolved": 2
  }
}
```

### Context Graph Service Events
```json
{
  "event_type": "context.updated",
  "context": {
    "update_timestamp": "2024-01-01T12:00:03Z",
    "fusion_algorithm": "multimodal-v1.3",
    "data_sources": ["sensors", "device_api", "calendar"],
    "change_detected": {
      "type": "activity_state",
      "old_value": "idle",
      "new_value": "work"
    }
  },
  "fusion_metadata": {
    "fusion_latency_ms": 100,
    "confidence_improvement": 0.05,
    "new_signals_processed": 3
  }
}
```

### Experience Rendering Engine Events
```json
{
  "event_type": "experience.generated",
  "experience": {
    "experience_id": "exp-001",
    "generation_timestamp": "2024-01-01T12:00:10Z",
    "rendering_engine": "webgl-v2.0",
    "components_generated": 5,
    "modality_selected": "visual"
  },
  "rendering_metadata": {
    "generation_latency_ms": 500,
    "interface_complexity": "medium",
    "personalization_applied": true
  }
}
```

### UMP Events
```json
{
  "event_type": "communication.sent",
  "communication": {
    "message_id": "ump-msg-uuid-v4",
    "intent_type": "coordinate",
    "recipients_count": 3,
    "primary_channel": "workspace",
    "sent_timestamp": "2024-01-01T12:00:15Z"
  },
  "delivery_metadata": {
    "delivery_strategy": "multi_channel",
    "consent_validated": true,
    "estimated_delivery_time": "2024-01-01T12:00:45Z"
  }
}
```

## Backward Compatibility

### v1.0 Compatibility Layer
Events using schema version "1.0" are automatically wrapped:

```json
{
  "schema_version": "2.0",
  "legacy_event": {
    "schema_version": "1.0",
    "id": "legacy-uuid",
    "timestamp": "2024-01-01T12:00:00Z",
    "source": "unison-speech",
    "intent": "user.query",
    "payload": {
      "text": "What's the weather like?",
      "language": "en"
    },
    "context": {
      "user_id": "user-123",
      "session_id": "session-456"
    },
    "auth_scope": "read",
    "safety_context": {
      "content_type": "general",
      "user_age": "adult"
    }
  },
  "migration_metadata": {
    "migrated_at": "2024-01-01T12:00:01Z",
    "migration_version": "v1-to-v2-1.0",
    "intent_inferred": "informational",
    "context_enhanced": true
  }
}
```

## Validation Rules

### Required Fields
- `schema_version` - Must be "2.0"
- `id` - Valid UUID v4
- `timestamp` - ISO 8601 timestamp
- `source` - Service identifier
- `event_type` - Valid event type
- `person.id` - Person identifier for user-facing events

### Conditional Requirements
- `intent` - Required for intent-related events
- `context` - Required for experience generation events
- `intent_graph` - Required for goal processing events
- `experience_requirements` - Required for experience events

### Validation Constraints
```json
{
  "constraints": {
    "id": {
      "type": "uuid",
      "version": "v4"
    },
    "timestamp": {
      "type": "datetime",
      "format": "iso8601",
      "max_age": "300s"  // 5 minutes
    },
    "intent.confidence": {
      "type": "float",
      "minimum": 0.0,
      "maximum": 1.0
    },
    "context.confidence_score": {
      "type": "float", 
      "minimum": 0.0,
      "maximum": 1.0
    },
    "person.session_id": {
      "type": "string",
      "min_length": 10,
      "max_length": 100
    }
  }
}
```

## Error Handling

### Error Event Structure
```json
{
  "schema_version": "2.0",
  "id": "error-uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "source": "service-name",
  "event_type": "error.occurred",
  "error": {
    "code": "INTENT_PROCESSING_FAILED",
    "message": "Unable to classify user intent",
    "severity": "error",
    "retryable": true,
    "original_event_id": "original-event-uuid",
    "stack_trace": "sanitized-stack-trace",
    "context": {
      "processing_stage": "intent_classification",
      "model_version": "intent-classifier-v3.1",
      "input_text": "unclear user input"
    }
  },
  "recovery": {
    "attempted_actions": ["retry_with_fallback_model"],
    "fallback_triggered": true,
    "escalation_required": false
  }
}
```

### Error Codes
- `INTENT_PROCESSING_FAILED` - Intent classification or processing failed
- `CONTEXT_FUSION_ERROR` - Context data fusion encountered errors
- `EXPERIENCE_GENERATION_FAILED` - Experience rendering failed
- `COMMUNICATION_DELIVERY_FAILED` - Message delivery failed
- `AUTHORIZATION_FAILED` - Authentication or authorization failed
- `RATE_LIMIT_EXCEEDED` - Service rate limits exceeded
- `DEPENDENCY_UNAVAILABLE` - Required service dependency unavailable

## Performance Considerations

### Event Size Guidelines
- **Target Size**: < 10KB per event
- **Maximum Size**: 100KB per event
- **Large Payload Handling**: Use external storage references

### Processing Targets
- **Schema Validation**: < 10ms per event
- **Migration Processing**: < 50ms for v1 to v2 conversion
- **Error Handling**: < 5ms for error event generation

### Optimization Strategies
- **Schema Caching**: Cache validation schemas for performance
- **Compression**: Use gzip for large events in transit
- **Batching**: Batch multiple events for efficiency
- **Sampling**: Sample high-volume events for monitoring

## Migration Guide

### Upgrading from v1.0
1. **Update Schema Version**: Change `"schema_version"` to `"2.0"`
2. **Add Intent Section**: Include intent classification and parameters
3. **Enhance Context**: Add environmental, preference, and temporal context
4. **Include Intent Graph**: Add goal decomposition for complex intents
5. **Add Experience Requirements**: Specify modality and interface preferences

### Backward Compatibility
- Services accepting v2.0 must handle v1.0 events
- Automatic migration wraps legacy events
- Gradual rollout supported by version detection

---

The EventEnvelope v2.0 schema provides the rich data structure needed for Unison's intent orchestration environment while maintaining compatibility with existing systems and enabling smooth migration to the new paradigm.
