# Schemas

## Locations
At runtime, schemas live in the user-owned prompt directory:
- `user/schema/identity.schema.json`
- `user/schema/priorities.schema.json`

Defaults ship with `unison-common` package resources under:
- `unison_common/schemas/prompt/`

## Identity (`identity.json`)
Stable, persistent preferences:
- Communication tone and default verbosity
- Accessibility preferences
- Privacy stance
- Anti-sycophancy challenge level
- Decision principles

## Priorities (`priorities.json`)
Mutable directives:
- Current goals
- Focus areas
- Risk tolerance
- Verbosity for current work
- Do / Don’t rules

