# CoSpec AI - Kai Context Sync Mechanism

## Overview

This document explains how CoSpec AI (the Markdown editor in Flexy containers) synchronizes markdown files with Kai's context system. The sync mechanism enables seamless knowledge capture from documentation directly into the project's context memory.

**Last Updated**: 2025-10-24
**Version**: Phase 1 Complete

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                            │
│  (CoSpec AI Frontend - React)                                   │
│                                                                   │
│  FileTree Component                                             │
│  └─> Right-click context menu on file                           │
│      └─> "Sync to Context" / "Unsync from Context"             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              CoSpec AI Backend (Express)                         │
│              Running in Flexy Container                          │
│                                                                   │
│  Routes (server/index.js):                                      │
│  POST /api/files/:path/sync-to-context                         │
│  DELETE /api/files/:path/sync-to-context                       │
│  GET /api/files/:path/sync-status                              │
│                                                                   │
│  ┌───────────────────────┐    ┌──────────────────────┐         │
│  │  fileSyncManager.js   │    │ kaiContextClient.js  │         │
│  │  ────────────────────  │    │ ──────────────────── │         │
│  │  • Track synced files │───▶│  • HTTP client       │         │
│  │  • Auto-sync patterns │    │  • Create/update     │         │
│  │  • Debouncing         │    │  • Search by path    │         │
│  │  • Frontmatter update │    │  • Delete memory     │         │
│  └───────────────────────┘    └──────────────────────┘         │
│                                         │                        │
└─────────────────────────────────────────┼────────────────────────┘
                                          │
                              HTTP Request │
                              (via host.docker.internal:9900)
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Kai Backend (Express)                           │
│                  Running on Host                                 │
│                                                                   │
│  Context API Routes:                                            │
│  POST   /api/context/memories        - Create memory           │
│  PUT    /api/context/memories/:id    - Update memory           │
│  POST   /api/context/search          - Search memories         │
│  DELETE /api/context/memories/:id    - Delete memory           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Context System (backend/src/services/)                │    │
│  │  • context-persistence.ts  - JSON storage             │    │
│  │  • context-embedding.ts    - Text embeddings          │    │
│  │  • context-search.ts       - Qdrant vector search     │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. FileSyncManager (CoSpec Backend)

**Location**: `Flexy/cospec-ai/server/fileSyncManager.js`

**Responsibilities**:
- Track which files are synced to Kai's context system
- Manage auto-sync patterns and manual sync triggers
- Debounce file changes to prevent excessive API calls
- Update markdown frontmatter with sync metadata
- Handle file deletion events

**Key Data Structures**:

```javascript
// In-memory tracking
this.syncedFiles = new Map();
// Structure: filePath → { memoryId, lastSync, status }

// Example:
{
  '網站構想.md': {
    memoryId: '66759249-fe19-4ea9-b322-d10d2173e3fb',
    lastSync: '2025-10-24T19:20:00.000Z',
    status: 'synced'
  }
}
```

**Auto-Sync Patterns**:

Files matching these patterns are automatically synced when edited:

```javascript
const DEFAULT_SYNC_PATTERNS = [
  /^specs\//i,              // specs/feature.md
  /^requirements\//i,       // requirements/api.md
  /^docs\/specs\//i,        // docs/specs/design.md
  /\.spec\.md$/i,           // feature.spec.md
  /^SPEC\.md$/i,            // SPEC.md
  /^REQUIREMENTS\.md$/i,    // REQUIREMENTS.md
];
```

**Debouncing**:
- Default delay: 3 seconds
- Prevents excessive API calls during rapid editing
- Configurable via `this.debounceDelay`

### 2. KaiContextClient (CoSpec Backend)

**Location**: `Flexy/cospec-ai/server/kaiContextClient.js`

**Responsibilities**:
- HTTP client for Kai's context API
- Create or update memories in Kai
- Search for existing memories by file path
- Delete memories when files are unsynced
- Health check for Kai backend connectivity

**Configuration**:

Initialized via environment variables passed to Flexy container:

```javascript
this.kaiBackendUrl = process.env.KAI_BACKEND_URL;
this.projectId = process.env.KAI_PROJECT_ID;
```

**Key Methods**:

```javascript
// Create or update memory
async createOrUpdateMemory(filePath, content, metadata)

// Find memory by file path
async getMemoryByFilePath(filePath)

// Delete memory
async deleteMemory(filePath)

// Check backend health
async healthCheck()
```

### 3. Context API Routes (CoSpec Backend)

**Location**: `Flexy/cospec-ai/server/index.js:448-523`

**Critical Route Ordering**:

Routes MUST be defined in this order to prevent wildcard matching conflicts:

```javascript
// ✅ CORRECT ORDER (Specific before General)
// 1. Specific context sync routes
POST   /api/files/:path(*)/sync-to-context
DELETE /api/files/:path(*)/sync-to-context
GET    /api/files/:path(*)/sync-status
GET    /api/context-config

// 2. General file CRUD routes (wildcard)
POST   /api/files/:path(*)
GET    /api/files/:path(*)
DELETE /api/files/:path(*)
```

**Why ordering matters**: Express matches routes in definition order. If wildcard routes come first, they intercept specific routes.

---

## Sync Flow

### Manual Sync (Primary Method)

**Step 1: User Trigger**
```
User right-clicks file in CoSpec AI FileTree
  └─> Selects "Sync to Context"
      └─> Frontend dispatches: syncFileToContext(filePath)
          └─> API call: POST /api/files/{path}/sync-to-context
```

**Step 2: CoSpec Backend Processing**
```javascript
// server/index.js
app.post('/api/files/:path(*)/sync-to-context', async (req, res) => {
  const filePath = sanitizePath(req.params.path);
  const fullPath = path.join(MARKDOWN_DIR, filePath);

  // Read file content
  const content = await fs.readFile(fullPath, 'utf-8');

  // Sync to context
  const result = await fileSyncManager.markForSync(filePath, content);
  res.json(result);
});
```

**Step 3: Extract Metadata**
```javascript
// fileSyncManager.js
async extractMetadata(filePath, content) {
  const parsed = matter(content); // Parse YAML frontmatter
  return {
    title: parsed.data.title || path.basename(filePath, '.md'),
    tags: parsed.data.tags || [],
    keyEntities: parsed.data.entities || [],
    contextSynced: parsed.data.context_synced || false,
    contextMemoryId: parsed.data.context_memory_id,
  };
}
```

**Step 4: Send to Kai Context API**
```javascript
// kaiContextClient.js
async createOrUpdateMemory(filePath, content, metadata) {
  const memoryData = {
    content,
    type: 'specification',
    scope: 'project',
    scopeId: this.projectId,
    metadata: {
      source: 'cospec-ai',
      filePath,
      summary: metadata.title || filePath,
      tags: metadata.tags || [],
      keyEntities: metadata.keyEntities || [],
      visibility: 'workspace',
      ...metadata,
    },
  };

  // Check if memory exists
  const existingMemory = await this.getMemoryByFilePath(filePath);

  if (existingMemory) {
    // Update existing memory
    const response = await this.client.put(
      `/api/context/memories/${existingMemory.id}`,
      memoryData
    );
  } else {
    // Create new memory
    const response = await this.client.post(
      '/api/context/memories',
      memoryData
    );
  }
}
```

**Step 5: Update Tracking**
```javascript
// fileSyncManager.js
this.syncedFiles.set(filePath, {
  memoryId: memory.id,
  lastSync: new Date().toISOString(),
  status: 'synced',
});

// Update file frontmatter
await this.updateFrontmatter(filePath, memory.id);
```

**Step 6: Return Success**
```javascript
{
  success: true,
  memoryId: '66759249-fe19-4ea9-b322-d10d2173e3fb'
}
```

### Auto-Sync (Pattern-Based)

**Trigger**: File save event for files matching auto-sync patterns

**Process**:
```javascript
// fileSyncManager.js
handleFileChange(filePath, content) {
  // Check if should sync
  const shouldSync = this.shouldAutoSync(filePath) || this.syncedFiles.has(filePath);

  if (!shouldSync) {
    return;
  }

  // Clear pending sync if exists
  if (this.pendingSync.has(filePath)) {
    clearTimeout(this.pendingSync.get(filePath));
  }

  // Schedule new sync with debouncing
  const timeoutHandle = setTimeout(() => {
    this.syncFile(filePath, content)
      .then(() => console.log(`Auto-synced ${filePath}`))
      .catch(err => console.error(`Auto-sync failed:`, err));

    this.pendingSync.delete(filePath);
  }, this.debounceDelay); // 3 seconds

  this.pendingSync.set(filePath, timeoutHandle);
}
```

---

## Sync Status Tracking

CoSpec AI tracks sync status through three mechanisms:

### 1. In-Memory Map (Fast, Transient)

**Storage**: JavaScript Map in `fileSyncManager.js`

**Lifetime**: Active only while container is running

**Purpose**: Quick status lookup for UI

**Data**:
```javascript
Map {
  'docs/design.md' => {
    memoryId: 'abc-123',
    lastSync: '2025-10-24T10:30:00Z',
    status: 'synced'
  }
}
```

### 2. File Frontmatter (Persistent, User-Editable)

**Storage**: YAML frontmatter in markdown files

**Lifetime**: Persists across container restarts

**Purpose**: Track sync metadata alongside content

**Before Sync**:
```markdown
# Website Ideas

This is my website concept...
```

**After Sync**:
```markdown
---
context_synced: true
context_memory_id: 66759249-fe19-4ea9-b322-d10d2173e3fb
last_synced: 2025-10-24T19:20:00.000Z
title: Website Design Specifications
tags: [design, frontend, ui/ux]
---

# Website Ideas

This is my website concept...
```

### 3. Kai Backend Search (Source of Truth)

**Method**: Search by metadata.filePath

**Purpose**: Authoritative status check

**Implementation**:
```javascript
// kaiContextClient.js
async getMemoryByFilePath(filePath) {
  const response = await this.client.post('/api/context/search', {
    query: filePath,
    scope: { type: 'project', id: this.projectId },
    types: ['specification'],
  });

  // Find exact match by metadata.filePath
  const matches = response.data.results || [];
  return matches.find(r => r.memory.metadata.filePath === filePath)?.memory || null;
}
```

**Why search instead of storing ID?**
- Container restarts lose in-memory state
- Users can edit/remove frontmatter
- FilePath is immutable identifier (until rename)

---

## Network Configuration

### Docker Host Access

**Challenge**: Flexy containers need to reach Kai backend running on host machine

**Solution**: `host.docker.internal` DNS name

**Container Environment**:
```javascript
// Set by Kai when creating container
KAI_BACKEND_URL=http://host.docker.internal:9900
KAI_PROJECT_ID=<project-uuid>
```

**Backend Binding**:
```javascript
// backend/src/index.ts:315
server.listen(port, '0.0.0.0', () => {
  console.log(`Kai backend server listening on 0.0.0.0:${port}`);
});
```

**Why `0.0.0.0`?**
- Binds to all network interfaces (IPv4)
- Allows access from Docker containers via `host.docker.internal`
- Without it, containers can't reach the backend

### Route Ordering Bug Fix

**Problem**: Express was matching general routes before specific context sync routes

**Original (Broken)**:
```javascript
// General route defined first
app.post('/api/files/:path(*)', ...) // Line 449

// Specific route defined later (never matched!)
app.post('/api/files/:path(*)/sync-to-context', ...) // Line 644
```

**Fixed**:
```javascript
// Specific routes BEFORE general routes
app.post('/api/files/:path(*)/sync-to-context', ...) // Line 448
app.delete('/api/files/:path(*)/sync-to-context', ...)
app.get('/api/files/:path(*)/sync-status', ...)

// General routes AFTER specific routes
app.post('/api/files/:path(*)', ...) // Line 530
```

**Commit**: `3795776` in CoSpec AI repository

---

## Memory Structure in Kai

When CoSpec syncs a file, it creates/updates a memory with this structure:

```javascript
{
  id: '66759249-fe19-4ea9-b322-d10d2173e3fb',
  content: '# Website Ideas\n\nThis is my website concept...',
  type: 'specification',
  scope: 'project',
  scopeId: 'demo-project-id',
  metadata: {
    source: 'cospec-ai',
    filePath: 'docs/網站構想.md',
    summary: 'Website Design Specifications',
    tags: ['design', 'frontend', 'ui/ux'],
    keyEntities: ['HomePage', 'UserProfile', 'Navigation'],
    visibility: 'workspace',
    sourceType: 'cospec-ai',
  },
  embedding: [-0.0098, 0.0015, ...], // 1536-dimensional vector
  createdAt: '2025-10-24T19:20:00.000Z',
  updatedAt: '2025-10-24T19:25:00.000Z'
}
```

**Key Fields**:
- `metadata.source`: Always `'cospec-ai'` for synced files
- `metadata.filePath`: Unique identifier for finding/updating
- `metadata.visibility`: Default `'workspace'` for shared specs
- `type`: Always `'specification'` for markdown docs
- `scope`: Always `'project'` (file belongs to project)

---

## Error Handling

### Network Errors

**Scenario**: Kai backend unreachable

**Handling**:
```javascript
// kaiContextClient.js
catch (error) {
  console.error(`Failed to sync ${filePath}:`, error.message);
  if (error.response) {
    console.error(`Response status: ${error.response.status}`);
    console.error(`Response data:`, error.response.data);
  }
  throw error;
}
```

**Result**: Error logged, status tracked as 'error'

### Failed Sync Tracking

**Implementation**:
```javascript
// fileSyncManager.js
this.syncedFiles.set(filePath, {
  lastSync: new Date().toISOString(),
  status: 'error',
  error: error.message,
});
```

**UI Indication**: File shows error status in CoSpec UI

### File Not Found

**Scenario**: User tries to sync deleted file

**Handling**:
```javascript
// server/index.js
try {
  await fs.access(fullPath);
} catch (error) {
  return res.status(404).json({ error: `File not found: ${filePath}` });
}
```

---

## Testing the Integration

### Prerequisites

1. Kai backend running on host: `cd backend && pnpm dev`
2. Flexy container created for a project
3. Backend bound to `0.0.0.0:9900`

### Test Steps

**1. Access CoSpec AI**
```
Navigate to: http://localhost:5173/sandbox/{container-id}?tab=docs
```

**2. Create/Edit Markdown File**
```markdown
---
title: Test Specification
tags: [test, sync]
---

# Test Document

This is a test for CoSpec-Kai sync.
```

**3. Sync to Context**
- Right-click file in FileTree
- Select "Sync to Context"
- Verify success notification

**4. Verify in Kai Context**
```
Navigate to: http://localhost:5173/context
Filter by: source='cospec-ai'
```

**Expected Result**:
- Memory appears with correct content
- Metadata includes filePath, tags, source
- Visibility set to 'workspace'

**5. Verify Frontmatter Update**

File should now have:
```markdown
---
title: Test Specification
tags: [test, sync]
context_synced: true
context_memory_id: <uuid>
last_synced: <timestamp>
---

# Test Document

This is a test for CoSpec-Kai sync.
```

### Debugging

**Check Container Logs**:
```bash
docker exec {container-id} cat /home/flexy/cospec-api.log | tail -50
```

**Test Backend Connectivity from Container**:
```bash
docker exec {container-id} curl http://host.docker.internal:9900/api/context/health
```

**Expected**: `{"status":"healthy","qdrant":true,"embedding":true}`

**Test Memory Creation**:
```bash
docker exec {container-id} curl -X POST \
  http://host.docker.internal:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "test",
    "type": "specification",
    "scope": "project",
    "scopeId": "test-id",
    "metadata": {
      "source": "cospec-ai",
      "filePath": "test.md",
      "visibility": "workspace"
    }
  }'
```

---

## Configuration

### Environment Variables

**Flexy Container** (set by Kai when creating container):
```bash
KAI_BACKEND_URL=http://host.docker.internal:9900
KAI_PROJECT_ID=<project-uuid>
MARKDOWN_DIR=/base-root/{org}/{workspace}/{project}
```

**Kai Backend** (`.env.local`):
```bash
PORT=9900
CONTEXT_ENABLED=true
QDRANT_URL=http://localhost:6333
```

### Auto-Sync Patterns

To modify which files auto-sync, edit:

**File**: `Flexy/cospec-ai/server/fileSyncManager.js:16-23`

```javascript
const DEFAULT_SYNC_PATTERNS = [
  /^specs\//i,
  /^requirements\//i,
  /^docs\/specs\//i,
  /\.spec\.md$/i,
  /^SPEC\.md$/i,
  /^REQUIREMENTS\.md$/i,
  // Add custom patterns here
];
```

Then rebuild Flexy image:
```bash
docker build --no-cache -t flexy-dev-sandbox:latest Flexy
```

---

## Key Design Decisions

### 1. Create vs Update Logic

**Decision**: Use semantic search to find existing memories

**Rationale**:
- Container restarts lose in-memory tracking
- Frontmatter can be edited/removed by users
- FilePath in metadata is source of truth

**Implementation**:
```javascript
const existingMemory = await this.getMemoryByFilePath(filePath);
if (existingMemory) {
  // Update existing
} else {
  // Create new
}
```

### 2. Debouncing for Auto-Sync

**Decision**: 3-second delay after last edit

**Rationale**:
- Prevents API spam during rapid typing
- Balances freshness vs performance
- Gives user time to finish thought

**Configurable**: `fileSyncManager.debounceDelay`

### 3. Workspace Visibility Default

**Decision**: Default visibility is 'workspace', not 'private'

**Rationale**:
- Specifications are collaborative by nature
- Aligns with project workflow expectations
- Can be overridden in frontmatter

**Code**:
```javascript
metadata: {
  visibility: 'workspace', // Specs are usually shared
}
```

### 4. Frontmatter Persistence

**Decision**: Write sync metadata to file frontmatter

**Rationale**:
- Survives container restarts
- Visible to users (transparency)
- Works with version control (Git)
- Portable across environments

**Trade-offs**:
- User can edit/remove (not enforced)
- Adds metadata to committed files
- Requires frontmatter parsing

---

## Future Enhancements

### Phase 2 Possibilities

1. **Bi-directional Sync**
   - Edit memory in Kai → Update CoSpec file
   - Requires file watching in Kai

2. **Conflict Resolution**
   - Detect divergence between file and memory
   - Allow user to choose version
   - Three-way merge interface

3. **Batch Sync**
   - Sync entire directories at once
   - Background sync queue
   - Progress indicators

4. **Sync History**
   - Track all sync events
   - Show diff between versions
   - Rollback capability

5. **Selective Sync**
   - Choose which sections to sync
   - Exclude private notes
   - Multiple memories per file

6. **Offline Queue**
   - Queue sync requests when Kai offline
   - Retry with exponential backoff
   - Sync on reconnection

---

## Related Documentation

- [Context System Architecture](./context-system.md)
- [CoSpec-Context Integration](./cospec-context-integration.md)
- [Backend Architecture](./backend.md)
- [Context System Phase 1 Complete](./context-system-phase1-complete.md)

---

## Commit History

Key commits implementing this mechanism:

**Kai Repository**:
- `eefb18b` - fix: Bind backend to 0.0.0.0 for Docker access
- `99fd9e0` - fix: Use host.docker.internal for dev mode
- `e286052` - fix: Handle missing visibility field
- `099e1cd` - fix: Handle missing visibility/tags in editor
- `3764f8d` - fix: Add missing /api prefix to endpoints
- `354a2e9` - fix: Add validation for required fields
- `891eaca` - fix: Change default visibility to 'workspace'
- `d7158f6` - fix: Improve error message for missing scope

**CoSpec AI Repository** (submodule):
- `3795776` - fix: Correct route ordering
- `7b0ef32` - fix: Add detailed logging for debugging
- `02fa2a1` - feat: Add Kai context system integration (frontend)

---

## Authors

- Initial implementation: Phase 1 development team
- Documentation: Claude Code (AI Assistant)
- Last updated: 2025-10-24
