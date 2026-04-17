---
id: UAT-KAI-DOCS
title: UAT - Kai Docs Page (Proxy HTTP)
owner: qa@team
status: final
version: 0.1
last_reviewed: 2025-09-15
---

## Preconditions
- A Flexy container has a Docs app listening at 8080 (internal).

## Test Cases
- Load `/flexy/:id/docs` → iframe renders Docs UI.
- Deep link path `/flexy/:id/docs/path/to/page` loads correctly.
- Missing Docs app → 404 page with Back action.
- Security (if enabled): unauthenticated access blocked.
