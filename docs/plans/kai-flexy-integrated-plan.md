---
description: Kai + Flexy integrated blueprint and development plan (Human co-work with AI)
---

# Kai + Flexy Integrated Plan

## 1) Goals
- Provide a web-based orchestrator (Kai) to manage multiple Flexy AI agent containers.
- Allow safe, non-exposed access to each Flexy’s web terminal (ttyd) via Kai reverse proxy.
- Enable Human × AI co-work inside Flexy using Gemini CLI and shared folders mapped from the host.
- Optionally mount a Markdown Docs app inside Flexy and access it via Kai proxy (no direct port exposure).

## 2) Scope & Components
- Kai (Frontend: React/Vite; Backend: Node/Express)
  - UI for Flexy lifecycle: list, create, start, stop, delete, open shell/docs.
  - Reverse proxy to Flexy ttyd (WebSocket) and optional Docs app HTTP.
  - Host directory picker (home dir scoped) for folder mapping.
  - Persistent catalog of Flexy projects (name + hostPath [+ optional containerId])
- Flexy Container (Base image + runtime)
  - ttyd at 9681 (Web terminal into tmux shared session).
  - Gemini CLI preinstalled for AI coding activities.
  - Optional Docs app (Markdown indexer/editor) at 8080.
  - No direct port mapping on host; reachable via Kai proxy inside docker network.

## 3) Target Architecture
```
[ Browser ]
    |
    v
[Kai Web (React)] <--> [Kai API (Node/Express + Proxy)]
                                 |
                                 v
                        [Docker Engine / API]
                                 |
              ---------------------------------------
              |                 |                   |
       [Flexy A]           [Flexy B]            [Flexy ...]
       (ttyd:9681)         (ttyd:9681)          (ttyd:9681)
       (docs:8080 opt)     (docs:8080 opt)      (docs:8080 opt)
              ^                 ^                     ^
              |                 |                     |
              --------------- Kai Proxy ---------------
```

- Network: single user-defined bridge `kai-net` for Kai backend and any Flexy.
- Image: base Flexy built/tagged as `flexy-dev-sandbox:latest` (configurable).

## 4) API Contract (Kai Backend)
Aligns with `docs/specs/SRS.md` and existing handlers in `backend/src/routes/containers.ts`, plus new proxy routes.

- Containers
  - GET `/api/flexy` → list Flexy containers (id, name, status, folderMapping, createdAt).
  - POST `/api/flexy` → create new Flexy. Body: `{ name: string, folderMapping?: string }`.
  - POST `/api/flexy/:id/start` → start container.
  - POST `/api/flexy/:id/stop` → stop container.
  - DELETE `/api/flexy/:id` → delete container.
- Host directory browse
  - POST `/api/host/directories` → list subdirs for a given path (scoped to home dir).
- Reverse proxy (NEW)
  - GET `/flexy/:id/shell` (and WebSocket upgrade) → proxy to `http://<flexy-container>:9681/`.
  - GET `/flexy/:id/docs/*` (optional) → proxy to `http://<flexy-container>:8080/*`.
 - Catalog (NEW)
  - GET `/api/catalog/flexy` → list persisted projects
  - POST `/api/catalog/flexy` → register `{ name, hostPath }`
  - DELETE `/api/catalog/flexy/{id}` → remove catalog entry (no implicit container deletion)

Notes:
- `:id` accepts container short ID or name; implementation resolves to the real container.
- WebSocket proxy must support `ttyd` upgrade and sticky tmux session.

## 5) Data Model (Kai)
Persistent catalog is required. Docker remains runtime source of truth for container state.
- `FlexyContainer` (derived): `{ id, name, status, folderMapping, createdAt }`.
- `FlexyCatalogItem` (persistent): `{ id, name, hostPath, containerId?, createdAt }`.
- Storage: pluggable. Default to lightweight local JSON or SQLite (either acceptable). Provide an abstraction to allow future DB swap.

## 6) Security
- Local default: no auth. For team use: JWT session with role `admin` for lifecycle ops.
- No container ports exposed to host. Only Kai’s HTTP(S) exposed.
- Proxy requires authenticated session; tokens not forwarded to Flexy.
- Path traversal checks in host directory browsing and Flexy docs proxy.

## 7) UX/Flows (Frontend)
- Container Dashboard (`/`)
  - List all Flexy with actions: Open Shell, Open Docs (optional), Start/Stop, Delete.
  - “New Flexy” modal with folder mapping helper (host dir picker posts to `/api/host/directories`).
- Shell Page (`/flexy/:id/shell`)
  - `iframe` points to Kai proxy; title shows project name.
- Docs Page (optional) (`/flexy/:id/docs`)
  - `iframe` loads proxied Docs app (8080). Used to browse/edit project Markdown.
- AI Co-work Pattern
  - User opens shell → runs Gemini CLI (`gemini ...`) inside `/workspace` (mapped from host).
  - Outputs visible in terminal; files written back to mapped folder for immediate local use.

## 8) Deployment
- Compose (`docker-compose.yml`)
  - Services: `frontend` (4173/80), `backend` (3000). Both in `kai-net`.
  - Mount `/var/run/docker.sock` to backend (already present) for Docker Engine access.
  - Do NOT publish Flexy ports; backend creates containers attached to `kai-net` without port bindings.
- Flexy Image
  - Build from `flexy/flexy-docker/Dockerfile`: `docker build -t flexy-dev-sandbox:latest flexy/flexy-docker`.
  - Configure Kai backend `IMAGE_NAME=flexy-dev-sandbox:latest`, `DOCKER_NETWORK=kai-net`.
  - Flexy default project config file: `/workspace/.flexy/config.json`. When Kai creates a container, it maps the host project folder to `/workspace` so the Docs service works out-of-the-box.

## 9) Gaps vs Current Codebase
- Backend `backend/src/services/docker.ts`
  - Hardcoded `IMAGE_NAME = 'flexy-dev-sandbox:latest'` → make configurable via env.
  - Uses `NetworkingConfig.EndpointsConfig['kai_kai-net']` → wrong; use env `DOCKER_NETWORK=kai-net`.
  - Sets `HostConfig.PortBindings['9681/tcp']` → remove; we must not expose ports.
  - After create: renames container to `flexy-<shortId>-<sanitizedName>` (ok). Ensure name resolvable via Docker DNS.
- Backend proxy
  - Missing `/flexy/:id/shell` WebSocket proxy and `/flexy/:id/docs/*` HTTP proxy. Add with `http-proxy-middleware` (WS=true) or `http-proxy`.
- Frontend
  - `frontend/src/pages/shell-page.tsx` uses `VITE_API_URL`; architecture doc uses `VITE_API_BASE_URL`. Unify on `VITE_API_BASE_URL`.
  - Add “Open Docs” action if we enable Flexy Docs.
  - Add “New Flexy” modal to capture `name` and `folderMapping` and call `POST /api/flexy`.
- Compose
  - Ensure `kai-net` is the network name referenced by backend env.
- Flexy Docs app (optional)
  - Flexy backend (`flexy/backend/src/index.ts`) currently mocks file ops. If we want it inside Flexy, run it on 8080 and bake into image or start via entrypoint script.

## 10) Implementation Plan & Milestones
- M1: Backend baseline
  - Fix Docker service (env-config, no port binding, correct network).
  - Implement proxy routes for ttyd WS and docs HTTP.
  - Health check `/api/health` already exists.
  - UAT: Create a Flexy, open shell, confirm WS works without exposing port.
- M2: Frontend UX
  - Container dashboard list and actions, New Flexy modal, shell page completed.
  - UAT: Create/start/stop/delete flows; shell opens via proxy.
- M3: Catalog persistence & Flexy Docs integration
  - Implement catalog endpoints and local storage (JSON or SQLite) with basic validation.
  - Integrate frontend with catalog for listing/creating/removing entries.
  - Build `flexy-image:local` with Gemini CLI and Docs app on 8080.
  - Add “Open Docs” proxy path and button.
  - UAT: Map host folder, edit `.md` via Docs app, changes persist to host.
- M4: Auth & Hardening
  - Optional JWT session; protect lifecycle & proxy routes.
  - Path and rate limits; structured logs.
- M5: Polishing
  - Filters/search on list; tags; persisted metadata; CI workflow; release.

## 11) Verification
- Backend: `/check-the-backend-api` workflow, plus E2E for proxy WS.
- Frontend: `/check-the-frontend-app` workflow using MCP Puppeteer with `docs/ux` flows.
- Manual: run `docker build` for Flexy, `docker compose up`, create Flexy, open shell, run `gemini --help`. Create catalog entry, restart Kai, verify catalog persists and maps to hostPath; create container from catalog item and verify mapping to `/workspace`.

## 12) Ops Notes
- If proxying WS: ensure `server.on('upgrade', ...)` wired or use middleware with `ws: true`.
- Keep Flexy name stable; proxy by container name (`http://<name>:9681`) resolves in docker network.
- In case of multiple Flexy versions, tag images (`flexy-image:gemini-2.5`, etc.).
