---
id: UAT-FLEXY-SETTINGS
title: UAT - Flexy Settings (Config API)
owner: qa@team
status: final
version: 0.1
last_reviewed: 2025-09-15
---

## Preconditions
- Flexy backend running (inside container), Config API enabled.

## Test Cases
- Load Settings → GET `/api/config` returns existing file or default `{ projects: [{ id: "workspace", ... }] }`.
- Add a project row and Save → PUT `/api/config` returns updated config; UI shows Saved.
- Validation: bad input triggers 400 with inline field errors.
- Reverse proxy: settings page functions when proxied (relative URLs only).
