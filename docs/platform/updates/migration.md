---
title: Migration Plan
nav_order: 6
---

# Migration plan (existing installs)

This describes how to migrate existing UnisonOS installations to the local Update Service update system.

## 1) Install and enable the Update Service

- Install the `unison-updates` service alongside other Unison services.
- Ensure it has a persistent state directory at `/var/lib/unison/updates`.

Native Ubuntu (systemd):

- Install `unison-platform/systemd/unison-updates.service` to `/etc/systemd/system/`
- `systemctl daemon-reload`
- `systemctl enable --now unison-updates`

Docker dev stack:

- The platform compose stack includes an `updates` service (port `8094` on host).

## 2) Point the orchestrator at the Update Service

Set the orchestrator environment:

```bash
UNISON_UPDATES_URL=http://localhost:8094
```

## 3) Ship public keys (signature verification)

Production expects signatures enabled.

Install public keys on the device image:

- Unison plane: `/etc/unison/keys/updates/unison/*.pub`
- Model plane: `/etc/unison/keys/updates/models/*.pub`

Key rotation:

- Add new `.pub` files alongside existing.
- Start signing new artifacts with the new key.
- After a retention window, remove the old key from images.

## 4) Model pack layout + signing changes

Model packs must now be side-by-side and signed:

- Payload files live under `packs/<pack_id>/<pack_version>/...`
- Each pack includes:
  - `models.manifest.json`
  - `models.manifest.sig.json` (Ed25519 signature over canonical JSON)

If you have older packs that don’t match this layout:

- Rebuild them using the updated pack builder (or repackage into the new layout).
- As a temporary migration escape hatch only, you can set:

```bash
UNISON_MODEL_PACK_REQUIRE_SIGNATURE=false
```

Disable this again once packs are republished with signatures.

## 5) Configure update sources

To enable real update discovery:

- Configure the Unison release index URL: `UNISON_UPDATES_UNISON_INDEX_URL`
- Configure the model pack index URL: `UNISON_UPDATES_MODEL_INDEX_URL`

These index documents are expected to be signed envelopes and should reference signed manifests and hashed payloads.

