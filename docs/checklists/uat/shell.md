---
id: UAT-KAI-SHELL
title: UAT - Kai Shell Page (Proxy WS)
owner: qa@team
status: final
version: 0.1
last_reviewed: 2025-09-15
---

## Preconditions
- A Flexy container exists and is running with ttyd at 9681 (internal).

## Test Cases
- Load `/flexy/:id/shell` → iframe connects; WS upgrade works; terminal renders.
- Disconnect/reconnect: network blip causes reconnect UI; clicking Retry reloads iframe.
- Error: invalid id → 404 page with Back action.
- Security (if enabled): unauthenticated access blocked; after login, shell loads.
