# Kai Standalone Electron App - Implementation Plan

## Overview

This document outlines the plan to convert Kai from a docker-compose-based application into a standalone Electron desktop application with embedded container runtime support.

## Architecture Overview

### 1. Dual-Mode Container Runtime

- **Developer Mode**: Docker Desktop Engine (if detected)
- **End-User Mode (Default)**: Embedded containerd runtime
- Auto-detection with fallback mechanism

### 2. Service Architecture

**Local (Managed by Electron App)**:
- Backend service (bundled image)
- Code-server (on-demand download)
- Qdrant vector DB (on-demand download)
- Neo4j graph DB (on-demand download)
- Flexy dev sandboxes (user-managed via app: start/stop/delete/recreate)

**Cloud (Separate Deployment)**:
- Frontend UI (deployed separately, accessed via browser)

### 3. Electron App Structure

```
kai-desktop/
├── electron/           # Main/renderer processes
│   ├── main.ts        # Container runtime bridge
│   ├── preload.ts     # IPC API
│   └── services/
│       ├── container-manager.ts    # Unified runtime interface
│       ├── docker-adapter.ts       # Docker Desktop mode
│       ├── containerd-adapter.ts   # containerd mode
│       └── image-manager.ts        # Download/cache images
├── ui/                # Configuration UI (React + shadcn/ui)
│   ├── setup-wizard.tsx
│   ├── settings-panel.tsx
│   ├── status-dashboard.tsx
│   └── sandbox-manager.tsx    # Sandbox CRUD UI
├── bundled/           # Bundled backend image only
└── config/            # Default configs
```

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

**Tasks**:
1. Create Electron project scaffold with TypeScript + Vite
2. Implement container runtime abstraction layer
   - `IContainerRuntime` interface
   - Docker Desktop adapter
   - Containerd adapter with platform-specific binaries (macOS/Windows/Linux)
3. Build image manager for on-demand downloads (requires internet)
4. Create setup wizard UI for first launch

### Phase 2: Configuration System (Week 3)

**Tasks**:
1. Build settings UI with shadcn/ui components:
   - KAI_BASE_ROOT directory picker
   - Neo4j password generator/input
   - Code-server password input
   - Cloud frontend URL configuration
   - Advanced environment variables editor
2. Implement config persistence (electron-store)
3. Add config validation logic
4. Create "Reset to Defaults" functionality

### Phase 3: Container Orchestration (Week 4-5)

**Tasks**:
1. Port docker-compose.yml logic to Node.js
2. Implement service dependency management (healthchecks)
3. Create service lifecycle management:
   - Start/stop individual services
   - Start all / Stop all
   - Auto-restart on failure
4. Add volume management for data persistence
5. Implement network creation (kai-net)
6. **Sandbox management API** (start/stop/delete/recreate flexy containers)

### Phase 4: UI Dashboard (Week 5-6)

**Tasks**:
1. Build status dashboard:
   - Service health indicators (backend, code-server, qdrant, neo4j)
   - Resource usage (CPU, memory, disk)
   - Service logs viewer with tail/search
2. **Build sandbox manager UI**:
   - List all sandboxes with status
   - Create new sandbox (project selection)
   - Start/Stop/Delete/Recreate actions
   - Quick access to sandbox shell/docs via cloud frontend
3. Add system tray integration with status icons
4. Implement notifications for critical events

### Phase 5: Distribution & Updates (Week 7-8)

**Tasks**:
1. Setup electron-builder for multi-platform builds:
   - macOS: DMG + auto-update (Intel + Apple Silicon universal binary)
   - Windows: NSIS installer + auto-update (requires internet)
   - Linux: AppImage + auto-update (requires internet)
2. Implement electron-updater:
   - App binary updates
   - Container image version checks
   - Automatic download of updated images
3. Bundle backend image in installer (~200-300MB)
4. Create GitHub Releases workflow with auto-publishing
5. Add crash reporter (Sentry/BugSnag optional)

### Phase 6: Testing & Polish (Week 9)

**Tasks**:
1. E2E testing with Playwright:
   - Setup wizard → service startup
   - Sandbox lifecycle (create → start → stop → delete)
   - Runtime mode switching
2. Cross-platform testing (macOS/Windows/Linux)
3. Performance optimization (app startup time, memory usage)
4. Documentation (user guide, troubleshooting)

## Key Technical Decisions

### Container Runtime Bridge

```typescript
interface IContainerRuntime {
  // Lifecycle
  startContainer(config: ContainerConfig): Promise<string>
  stopContainer(id: string): Promise<void>
  removeContainer(id: string): Promise<void>
  restartContainer(id: string): Promise<void>

  // Images
  pullImage(name: string, onProgress: (pct: number) => void): Promise<void>
  listImages(): Promise<Image[]>

  // Networks & Volumes
  createNetwork(name: string): Promise<void>
  createVolume(name: string): Promise<void>

  // Health & Info
  inspectContainer(id: string): Promise<ContainerInfo>
  listContainers(filters?: object): Promise<Container[]>
}
```

### Configuration UI Components

1. **Setup Wizard** (first launch):
   - Welcome screen
   - Runtime mode detection/selection
   - Base directory picker (KAI_BASE_ROOT)
   - Password configuration (Neo4j, code-server)
   - Cloud frontend URL input
   - Initial download progress (Qdrant, Neo4j, code-server images)

2. **Settings Panel**:
   - General: Base paths, runtime mode, cloud frontend URL
   - Services: Individual service configs
   - Advanced: All env vars from docker-compose.yml
   - About: Version, check for updates, view logs

3. **Main Dashboard**:
   - **Services Tab**: Backend, code-server, Qdrant, Neo4j status cards
   - **Sandboxes Tab**: Full sandbox management UI
     - List view with status badges
     - Actions: Create, Start, Stop, Delete, Recreate
     - Quick links to open in cloud frontend
   - System resource meters
   - Recent logs panel

### Sandbox Manager Features

- Create sandbox from organization/workspace/project hierarchy
- Real-time status updates (running/stopped/failed)
- Bulk actions (start all, stop all)
- Confirm dialogs for destructive actions (delete)
- Recreate = delete + create with same config
- Integration with cloud frontend (open shell/docs buttons)

## Migration Path

1. Current docker-compose.yml remains working (no breaking changes for developers)
2. Electron app initially uses Docker Desktop in dev mode
3. Gradually add containerd support for end-user mode
4. Backend API remains unchanged (Electron app uses same REST API)

## Dependencies

- **Electron**: ^28.0.0
- **Container Runtimes**:
  - Docker Desktop (external, user-installed for dev mode)
  - containerd binaries (bundled for end-user mode, platform-specific)
- **UI**: React 18 + Vite + shadcn/ui (reuse existing Kai UI components)
- **IPC**: electron-ipc-cat or typed-ipc for type-safe IPC
- **Updates**: electron-updater + electron-builder
- **Storage**: electron-store for config persistence

## Estimated Timeline

- **Total**: 9 weeks (1 full-time developer)
- **MVP** (Phases 1-4): 6 weeks
- **Production Release**: 9 weeks

## Bundle Sizes

- **Installer**: ~400-500MB (includes backend image + Electron)
- **First launch download**: ~800MB (Neo4j, Qdrant, code-server images)
- **Per sandbox**: ~200MB (flexy-dev-sandbox image, downloaded on first sandbox creation)

## Requirements

- **No air-gapped installs**: Internet required for initial setup and image downloads
- **No CLI interface**: GUI only
- **Sandbox management**: Full CRUD via Electron app (not cloud frontend)

## Notes

- Frontend remains cloud-deployed (not bundled in Electron app)
- Backend bundled in installer to minimize first-launch time
- Auto-update for both app binaries and container images
- Platform support: macOS (Intel + Apple Silicon), Windows 10/11, Linux (Ubuntu/Debian)
