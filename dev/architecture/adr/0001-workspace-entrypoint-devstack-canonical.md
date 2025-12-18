# ADR 0001: `unison-workspace` is the entry point; `unison-devstack` remains canonical

- Status: Accepted
- Date: 2025-12-16

## Context

UnisonOS development spans many repositories (services, platform packaging, docs, and tooling). Developers need a single, consistent way to:

- clone the correct set of repos,
- keep them in compatible revisions,
- run the local integration stack and smoke tests,
- align with CI/build pipelines that expect a particular workspace layout.

We have validated that:

- `unison-devstack` is the canonical local/e2e Docker Compose stack.
- `unison-workspace` references `unison-devstack` as a git submodule.
- Builds intentionally use the `unison-workspace` + submodules layout.

## Decision

- `unison-workspace` is the **recommended entry point** (“front door”) for contributors and evaluators.
- `unison-devstack` remains the **canonical** repo for the development compose stack and smoke/e2e tooling.
- `unison-workspace` includes `unison-devstack` (and other core repos) as **git submodules**; this is the intended repo model.

## Consequences

- Docs should direct users to clone `unison-workspace` first, then use workspace scripts to start/validate the stack.
- CI/build tooling may assume `unison-workspace/<submodule>` paths; this is not accidental.
- `unison-devstack` is not “moved into” `unison-workspace`; it must continue to function as a standalone repo and as a submodule.

## Non-goals

- Refactoring or relocating `unison-devstack` or `unison-workspace` structure.
- Replacing git submodules with a different multi-repo mechanism.

