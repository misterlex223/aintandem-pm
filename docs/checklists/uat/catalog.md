---
id: UAT-KAI-CATALOG
title: UAT - Kai Catalog (List/Create/Delete/Create-Container)
owner: qa@team
status: final
version: 0.1
last_reviewed: 2025-09-15
---

## Preconditions
- Kai backend running. OpenAPI reachable.

## Test Cases
- List
  - Open Catalog page → shows loading then list or empty state.
  - Error path: simulate 500 → error message and retry.
- Create Catalog Item
  - Click New → fill name + hostPath (use DirectoryPicker). Submit → 201 and item appears.
  - Invalid hostPath → 400 with field error.
  - Duplicate → 409 conflict toast.
- Delete Catalog Item
  - Click delete → confirm → 204 and item removed.
  - Non-existent id → 404 handled gracefully.
- Create Container from Catalog
  - Click Create Container on an item → verify `folderMapping = <hostPath>:/workspace` used.
  - On success provide links to Shell `/flexy/:id/shell` and Docs `/flexy/:id/docs`.
