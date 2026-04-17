# CoSpec AI ↔ Kai Context System Integration

## Overview

This document describes the integration between CoSpec AI (the Markdown editor running in Flexy containers) and Kai's context system, enabling users to sync markdown files as specification memories.

## Design Goals

1. **Pattern-based auto-sync**: Files matching patterns (e.g., `specs/`, `requirements/`, `docs/specs/`) are automatically synced
2. **Manual UI controls**: Context menu + editor button for explicit marking/unmarking
3. **Project scope only**: All memories from Flexy CoSpec instances use project scope
4. **Seamless UX**: Sync happens in background, non-blocking, with clear status indicators
5. **Graceful degradation**: Works without Kai backend (shows warnings but doesn't block editing)

## Architecture

### Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Flexy Container                        │
│                                                             │
│  ┌──────────────────┐         ┌─────────────────────────┐  │
│  │   CoSpec AI      │         │  CoSpec AI Backend      │  │
│  │   Frontend       │────────▶│  (Express + Node.js)    │  │
│  │   (React)        │         │                         │  │
│  └──────────────────┘         │  - File Sync Manager    │  │
│         │                     │  - Kai Context Client   │  │
│         │                     │  - Pattern Matcher      │  │
│         │                     └──────────┬──────────────┘  │
│         │                                │                 │
│  ┌──────▼──────────┐                    │                 │
│  │  Markdown Files │◀───────────────────┘                 │
│  │  with Metadata  │                                      │
│  └─────────────────┘                                      │
└─────────────────────────────────────────┼──────────────────┘
                                          │ HTTP
                                          ▼
                              ┌───────────────────────┐
                              │   Kai Backend         │
                              │   (kai-backend:9900)  │
                              │                       │
                              │  /api/context/*       │
                              └───────────┬───────────┘
                                          │
                                          ▼
                              ┌───────────────────────┐
                              │  Context System       │
                              │  - Qdrant (vectors)   │
                              │  - Neo4j (graph)      │
                              │  - JSON (cache)       │
                              └───────────────────────┘
```

### Key Design Decisions

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| **Communication** | CoSpec → Kai (HTTP) | Simpler, self-contained, follows existing patterns |
| **Scope** | Project only | Flexy containers are project-scoped; org/workspace will use Kai-hosted CoSpec |
| **Sync Strategy** | Pattern-based + Manual | Balance automation with user control |
| **Metadata Storage** | YAML frontmatter | Standard, human-readable, version-control friendly |
| **Error Handling** | Graceful degradation | Editing continues even if Kai is unavailable |

## Implementation Plan

### Phase 1: Kai Backend Changes

#### 1.1 Pass Project Context to Containers

**File**: `backend/src/services/docker.ts`

Add environment variables when creating containers:

```typescript
Env: [
  'ENABLE_WEBTTY=true',
  `KAI_PROJECT_ID=${projectId}`,              // NEW: Project ID for context
  `KAI_BACKEND_URL=http://kai-backend:9900`,  // NEW: Kai backend URL
  `DOCKER_NETWORK=${DOCKER_NETWORK}`,
  // ... existing env vars
],
```

**Why**: CoSpec backend needs to know which project it belongs to and how to reach Kai's API.

#### 1.2 Update Container Routes

**File**: `backend/src/routes/containers.ts`

Ensure `projectId` is passed to `createContainer()` when creating project-based sandboxes (already implemented).

### Phase 2: CoSpec AI Backend Changes

#### 2.1 Create Kai Context Client

**File**: `Flexy/cospec-ai/server/kaiContextClient.js` (NEW)

```javascript
/**
 * HTTP client for Kai's context API
 * Handles memory creation, updates, and deletion
 */

const axios = require('axios');

class KaiContextClient {
  constructor() {
    this.kaiBackendUrl = process.env.KAI_BACKEND_URL;
    this.projectId = process.env.KAI_PROJECT_ID;
    this.enabled = !!(this.kaiBackendUrl && this.projectId);

    if (!this.enabled) {
      console.warn('[KaiContext] Disabled: missing KAI_BACKEND_URL or KAI_PROJECT_ID');
    }

    this.client = axios.create({
      baseURL: this.kaiBackendUrl,
      timeout: 10000,
    });
  }

  /**
   * Create or update a memory in Kai's context system
   */
  async createOrUpdateMemory(filePath, content, metadata = {}) {
    if (!this.enabled) return null;

    try {
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
          visibility: 'workspace', // Specs are usually shared
          ...metadata,
        },
      };

      // Check if memory exists by file path
      const existingMemory = await this.getMemoryByFilePath(filePath);

      if (existingMemory) {
        // Update existing memory
        const response = await this.client.put(
          `/api/context/memories/${existingMemory.id}`,
          memoryData
        );
        console.log(`[KaiContext] Updated memory for ${filePath}`);
        return response.data;
      } else {
        // Create new memory
        const response = await this.client.post('/api/context/memories', memoryData);
        console.log(`[KaiContext] Created memory for ${filePath}`);
        return response.data;
      }
    } catch (error) {
      console.error(`[KaiContext] Failed to sync ${filePath}:`, error.message);
      throw error;
    }
  }

  /**
   * Get memory by file path
   */
  async getMemoryByFilePath(filePath) {
    if (!this.enabled) return null;

    try {
      const response = await this.client.post('/api/context/search', {
        query: filePath,
        scope: { type: 'project', id: this.projectId },
        types: ['specification'],
      });

      // Find exact match by metadata.filePath
      const matches = response.data.results || [];
      return matches.find(r => r.memory.metadata.filePath === filePath)?.memory || null;
    } catch (error) {
      console.error(`[KaiContext] Failed to find memory for ${filePath}:`, error.message);
      return null;
    }
  }

  /**
   * Delete memory by file path
   */
  async deleteMemory(filePath) {
    if (!this.enabled) return false;

    try {
      const memory = await this.getMemoryByFilePath(filePath);
      if (memory) {
        await this.client.delete(`/api/context/memories/${memory.id}`);
        console.log(`[KaiContext] Deleted memory for ${filePath}`);
        return true;
      }
      return false;
    } catch (error) {
      console.error(`[KaiContext] Failed to delete memory for ${filePath}:`, error.message);
      throw error;
    }
  }

  /**
   * Check if Kai backend is reachable
   */
  async healthCheck() {
    if (!this.enabled) return false;

    try {
      await this.client.get('/api/context/health');
      return true;
    } catch (error) {
      console.error('[KaiContext] Health check failed:', error.message);
      return false;
    }
  }
}

module.exports = new KaiContextClient();
```

#### 2.2 Create File Sync Manager

**File**: `Flexy/cospec-ai/server/fileSyncManager.js` (NEW)

```javascript
/**
 * Manages syncing markdown files to Kai's context system
 * - Pattern-based auto-sync
 * - Manual sync control via API
 * - Frontmatter metadata extraction
 * - Debouncing for file changes
 */

const path = require('path');
const fs = require('fs').promises;
const matter = require('gray-matter'); // For YAML frontmatter parsing
const kaiContextClient = require('./kaiContextClient');

// Patterns that trigger auto-sync
const DEFAULT_SYNC_PATTERNS = [
  /^specs\//i,
  /^requirements\//i,
  /^docs\/specs\//i,
  /\.spec\.md$/i,
  /^SPEC\.md$/i,
  /^REQUIREMENTS\.md$/i,
];

class FileSyncManager {
  constructor() {
    this.syncedFiles = new Map(); // filePath → { memoryId, lastSync, status }
    this.pendingSync = new Map(); // filePath → timeout handle
    this.debounceDelay = 3000; // Wait 3 seconds after edit before syncing
  }

  /**
   * Check if file matches auto-sync patterns
   */
  shouldAutoSync(filePath) {
    return DEFAULT_SYNC_PATTERNS.some(pattern => pattern.test(filePath));
  }

  /**
   * Extract metadata from markdown frontmatter
   */
  async extractMetadata(filePath, content) {
    try {
      const parsed = matter(content);
      return {
        title: parsed.data.title || path.basename(filePath, '.md'),
        tags: parsed.data.tags || [],
        description: parsed.data.description,
        keyEntities: parsed.data.entities || [],
        contextSynced: parsed.data.context_synced || false,
        contextMemoryId: parsed.data.context_memory_id,
      };
    } catch (error) {
      console.error(`[FileSyncManager] Failed to parse frontmatter for ${filePath}:`, error);
      return {
        title: path.basename(filePath, '.md'),
        tags: [],
      };
    }
  }

  /**
   * Update frontmatter with sync status
   */
  async updateFrontmatter(filePath, memoryId) {
    try {
      const fullPath = path.join(process.env.MARKDOWN_DIR || '/markdown', filePath);
      const content = await fs.readFile(fullPath, 'utf-8');
      const parsed = matter(content);

      // Update frontmatter
      parsed.data.context_synced = true;
      parsed.data.context_memory_id = memoryId;
      parsed.data.last_synced = new Date().toISOString();

      // Write back
      const updated = matter.stringify(parsed.content, parsed.data);
      await fs.writeFile(fullPath, updated, 'utf-8');

      console.log(`[FileSyncManager] Updated frontmatter for ${filePath}`);
    } catch (error) {
      console.error(`[FileSyncManager] Failed to update frontmatter for ${filePath}:`, error);
    }
  }

  /**
   * Sync a file to Kai context system
   */
  async syncFile(filePath, content) {
    try {
      const metadata = await this.extractMetadata(filePath, content);

      // Sync to Kai
      const memory = await kaiContextClient.createOrUpdateMemory(
        filePath,
        content,
        metadata
      );

      if (memory) {
        // Update local tracking
        this.syncedFiles.set(filePath, {
          memoryId: memory.id,
          lastSync: new Date().toISOString(),
          status: 'synced',
        });

        // Update frontmatter
        await this.updateFrontmatter(filePath, memory.id);

        return { success: true, memoryId: memory.id };
      }

      return { success: false, error: 'No memory returned' };
    } catch (error) {
      this.syncedFiles.set(filePath, {
        lastSync: new Date().toISOString(),
        status: 'error',
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Handle file change with debouncing
   */
  handleFileChange(filePath, content) {
    // Check if should sync (auto-pattern or manually marked)
    const shouldSync = this.shouldAutoSync(filePath) || this.syncedFiles.has(filePath);

    if (!shouldSync) return;

    // Clear pending sync if exists
    if (this.pendingSync.has(filePath)) {
      clearTimeout(this.pendingSync.get(filePath));
    }

    // Schedule new sync
    const timeoutHandle = setTimeout(() => {
      this.syncFile(filePath, content)
        .then(() => console.log(`[FileSyncManager] Auto-synced ${filePath}`))
        .catch(err => console.error(`[FileSyncManager] Auto-sync failed for ${filePath}:`, err.message));

      this.pendingSync.delete(filePath);
    }, this.debounceDelay);

    this.pendingSync.set(filePath, timeoutHandle);
  }

  /**
   * Handle file deletion
   */
  async handleFileDelete(filePath) {
    if (this.syncedFiles.has(filePath)) {
      try {
        await kaiContextClient.deleteMemory(filePath);
        this.syncedFiles.delete(filePath);
        console.log(`[FileSyncManager] Deleted memory for ${filePath}`);
      } catch (error) {
        console.error(`[FileSyncManager] Failed to delete memory for ${filePath}:`, error.message);
      }
    }
  }

  /**
   * Manually mark file for sync
   */
  async markForSync(filePath, content) {
    return await this.syncFile(filePath, content);
  }

  /**
   * Manually unmark file from sync
   */
  async unmarkFromSync(filePath) {
    try {
      await kaiContextClient.deleteMemory(filePath);
      this.syncedFiles.delete(filePath);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Get sync status for a file
   */
  getSyncStatus(filePath) {
    if (this.syncedFiles.has(filePath)) {
      return this.syncedFiles.get(filePath);
    }
    return {
      status: this.shouldAutoSync(filePath) ? 'auto-eligible' : 'not-synced',
    };
  }

  /**
   * Get all synced files
   */
  getAllSyncedFiles() {
    return Array.from(this.syncedFiles.entries()).map(([filePath, data]) => ({
      filePath,
      ...data,
    }));
  }
}

module.exports = new FileSyncManager();
```

#### 2.3 Add API Routes

**File**: `Flexy/cospec-ai/server/index.js`

Add new routes after existing file routes:

```javascript
// Import sync manager
const fileSyncManager = require('./fileSyncManager');
const kaiContextClient = require('./kaiContextClient');

// POST /api/files/:path/sync-to-context - Manually mark file for sync
app.post('/api/files/:path(*)/sync-to-context', authenticateToken, async (req, res) => {
  try {
    const filePath = sanitizePath(req.params.path);
    const fullPath = path.join(MARKDOWN_DIR, filePath);

    // Read file content
    const content = await fs.readFile(fullPath, 'utf-8');

    // Sync to context
    const result = await fileSyncManager.markForSync(filePath, content);

    res.json(result);
  } catch (error) {
    console.error('[ContextSync] Failed to mark file for sync:', error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/files/:path/sync-to-context - Unmark file from sync
app.delete('/api/files/:path(*)/sync-to-context', authenticateToken, async (req, res) => {
  try {
    const filePath = sanitizePath(req.params.path);
    const result = await fileSyncManager.unmarkFromSync(filePath);
    res.json(result);
  } catch (error) {
    console.error('[ContextSync] Failed to unmark file from sync:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/files/:path/sync-status - Get sync status
app.get('/api/files/:path(*)/sync-status', async (req, res) => {
  try {
    const filePath = sanitizePath(req.params.path);
    const status = fileSyncManager.getSyncStatus(filePath);
    res.json(status);
  } catch (error) {
    console.error('[ContextSync] Failed to get sync status:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/context-config - Get context configuration
app.get('/api/context-config', async (req, res) => {
  try {
    const healthy = await kaiContextClient.healthCheck();
    res.json({
      enabled: kaiContextClient.enabled,
      healthy,
      projectId: kaiContextClient.projectId,
      syncedFiles: fileSyncManager.getAllSyncedFiles(),
    });
  } catch (error) {
    console.error('[ContextSync] Failed to get config:', error);
    res.status(500).json({ error: error.message });
  }
});
```

#### 2.4 Integrate with File Watcher

**File**: `Flexy/cospec-ai/server/index.js`

Update the chokidar watcher to trigger context sync:

```javascript
// Add to existing watcher setup
watcher
  .on('add', async (filepath) => {
    console.log(`File ${filepath} has been added`);
    invalidateCache();
    broadcastToClients({ type: 'add', path: filepath });

    // NEW: Check for context sync
    try {
      const relativePath = path.relative(MARKDOWN_DIR, filepath);
      if (relativePath.endsWith('.md')) {
        const content = await fs.readFile(filepath, 'utf-8');
        fileSyncManager.handleFileChange(relativePath, content);
      }
    } catch (error) {
      console.error('[ContextSync] Error on file add:', error);
    }
  })
  .on('change', async (filepath) => {
    console.log(`File ${filepath} has been changed`);
    invalidateCache();
    broadcastToClients({ type: 'change', path: filepath });

    // NEW: Check for context sync
    try {
      const relativePath = path.relative(MARKDOWN_DIR, filepath);
      if (relativePath.endsWith('.md')) {
        const content = await fs.readFile(filepath, 'utf-8');
        fileSyncManager.handleFileChange(relativePath, content);
      }
    } catch (error) {
      console.error('[ContextSync] Error on file change:', error);
    }
  })
  .on('unlink', (filepath) => {
    console.log(`File ${filepath} has been removed`);
    invalidateCache();
    broadcastToClients({ type: 'unlink', path: filepath });

    // NEW: Delete from context
    try {
      const relativePath = path.relative(MARKDOWN_DIR, filepath);
      if (relativePath.endsWith('.md')) {
        fileSyncManager.handleFileDelete(relativePath);
      }
    } catch (error) {
      console.error('[ContextSync] Error on file delete:', error);
    }
  });
```

#### 2.5 Add Dependencies

**File**: `Flexy/cospec-ai/server/package.json`

Add `gray-matter` for YAML frontmatter parsing:

```json
{
  "dependencies": {
    "axios": "^1.6.0",
    "chokidar": "^3.5.3",
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "express-rate-limit": "^7.1.5",
    "glob": "^10.3.3",
    "gray-matter": "^4.0.3",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "socket.io": "^4.7.2",
    "openai": "^3.3.0"
  }
}
```

### Phase 3: CoSpec AI Frontend Changes

#### 3.1 Add Context Sync Redux Slice

**File**: `Flexy/cospec-ai/app-react/src/store/slices/contextSlice.ts` (NEW)

```typescript
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { contextApi } from '../../services/api';

interface SyncStatus {
  status: 'not-synced' | 'auto-eligible' | 'synced' | 'syncing' | 'error';
  memoryId?: string;
  lastSync?: string;
  error?: string;
}

interface ContextState {
  syncStatuses: Record<string, SyncStatus>;
  config: {
    enabled: boolean;
    healthy: boolean;
    projectId?: string;
  } | null;
  isLoading: boolean;
}

const initialState: ContextState = {
  syncStatuses: {},
  config: null,
  isLoading: false,
};

// Async thunks
export const fetchContextConfig = createAsyncThunk(
  'context/fetchConfig',
  async () => {
    const config = await contextApi.getConfig();
    return config;
  }
);

export const syncFileToContext = createAsyncThunk(
  'context/syncFile',
  async (filePath: string) => {
    const result = await contextApi.syncFile(filePath);
    return { filePath, ...result };
  }
);

export const unsyncFileFromContext = createAsyncThunk(
  'context/unsyncFile',
  async (filePath: string) => {
    const result = await contextApi.unsyncFile(filePath);
    return { filePath, ...result };
  }
);

export const fetchSyncStatus = createAsyncThunk(
  'context/fetchStatus',
  async (filePath: string) => {
    const status = await contextApi.getSyncStatus(filePath);
    return { filePath, ...status };
  }
);

const contextSlice = createSlice({
  name: 'context',
  initialState,
  reducers: {
    setSyncStatus: (state, action: PayloadAction<{ filePath: string; status: SyncStatus }>) => {
      state.syncStatuses[action.payload.filePath] = action.payload.status;
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch config
      .addCase(fetchContextConfig.fulfilled, (state, action) => {
        state.config = action.payload;
        // Update sync statuses from config
        if (action.payload.syncedFiles) {
          action.payload.syncedFiles.forEach((file: any) => {
            state.syncStatuses[file.filePath] = {
              status: file.status,
              memoryId: file.memoryId,
              lastSync: file.lastSync,
            };
          });
        }
      })
      // Sync file
      .addCase(syncFileToContext.pending, (state, action) => {
        state.syncStatuses[action.meta.arg] = { status: 'syncing' };
      })
      .addCase(syncFileToContext.fulfilled, (state, action) => {
        state.syncStatuses[action.payload.filePath] = {
          status: 'synced',
          memoryId: action.payload.memoryId,
          lastSync: new Date().toISOString(),
        };
      })
      .addCase(syncFileToContext.rejected, (state, action) => {
        state.syncStatuses[action.meta.arg] = {
          status: 'error',
          error: action.error.message,
        };
      })
      // Unsync file
      .addCase(unsyncFileFromContext.fulfilled, (state, action) => {
        state.syncStatuses[action.payload.filePath] = { status: 'not-synced' };
      })
      // Fetch status
      .addCase(fetchSyncStatus.fulfilled, (state, action) => {
        state.syncStatuses[action.payload.filePath] = {
          status: action.payload.status,
          memoryId: action.payload.memoryId,
          lastSync: action.payload.lastSync,
          error: action.payload.error,
        };
      });
  },
});

export const { setSyncStatus } = contextSlice.actions;
export default contextSlice.reducer;
```

#### 3.2 Update API Service

**File**: `Flexy/cospec-ai/app-react/src/services/api.ts`

Add context sync API methods:

```typescript
export const contextApi = {
  // Get context configuration
  getConfig: async (): Promise<any> => {
    const response = await api.get('/context-config');
    return response.data;
  },

  // Sync file to context
  syncFile: async (path: string): Promise<any> => {
    const response = await api.post(`/files/${encodeURIComponent(path)}/sync-to-context`);
    return response.data;
  },

  // Unsync file from context
  unsyncFile: async (path: string): Promise<any> => {
    const response = await api.delete(`/files/${encodeURIComponent(path)}/sync-to-context`);
    return response.data;
  },

  // Get sync status
  getSyncStatus: async (path: string): Promise<any> => {
    const response = await api.get(`/files/${encodeURIComponent(path)}/sync-status`);
    return response.data;
  },
};
```

#### 3.3 Add Context Menu to File Tree

**File**: `Flexy/cospec-ai/app-react/src/components/FileTree/FileTree.tsx`

Add context menu items for sync control:

```typescript
// Add to imports
import { fetchSyncStatus, syncFileToContext, unsyncFileFromContext } from '../../store/slices/contextSlice';
import { useAppDispatch, useAppSelector } from '../../store/hooks';

// Inside component
const dispatch = useAppDispatch();
const syncStatuses = useAppSelector(state => state.context.syncStatuses);
const contextConfig = useAppSelector(state => state.context.config);

const handleSyncToContext = async (filePath: string) => {
  try {
    await dispatch(syncFileToContext(filePath)).unwrap();
    // Show success notification
  } catch (error) {
    // Show error notification
  }
};

const handleUnsyncFromContext = async (filePath: string) => {
  try {
    await dispatch(unsyncFileFromContext(filePath)).unwrap();
    // Show success notification
  } catch (error) {
    // Show error notification
  }
};

// Add context menu items
const contextMenuItems = [
  // ... existing items
  {
    label: syncStatuses[file.path]?.status === 'synced'
      ? 'Remove from Context'
      : 'Sync to Context',
    onClick: () => {
      if (syncStatuses[file.path]?.status === 'synced') {
        handleUnsyncFromContext(file.path);
      } else {
        handleSyncToContext(file.path);
      }
    },
    icon: syncStatuses[file.path]?.status === 'synced'
      ? <CheckCircleIcon />
      : <CloudUploadIcon />,
  },
];

// Add sync status badge to file item
const renderSyncBadge = (filePath: string) => {
  const status = syncStatuses[filePath];
  if (!status || status.status === 'not-synced') return null;

  return (
    <span className={`sync-badge ${status.status}`}>
      {status.status === 'synced' && '✓'}
      {status.status === 'syncing' && '⟳'}
      {status.status === 'error' && '✗'}
      {status.status === 'auto-eligible' && '●'}
    </span>
  );
};
```

#### 3.4 Add Toolbar Button to Editor

**File**: `Flexy/cospec-ai/app-react/src/components/MarkdownEditor/MarkdownEditor.tsx`

Add sync button to editor toolbar:

```typescript
// Add to imports
import { fetchSyncStatus, syncFileToContext } from '../../store/slices/contextSlice';

// Inside component
const dispatch = useAppDispatch();
const syncStatus = useAppSelector(state =>
  state.context.syncStatuses[currentFilePath]
);

const handleSyncClick = async () => {
  if (!currentFilePath) return;
  try {
    await dispatch(syncFileToContext(currentFilePath)).unwrap();
    // Show success notification
  } catch (error) {
    // Show error notification
  }
};

// Add to toolbar
<div className="editor-toolbar">
  {/* ... existing buttons */}

  <button
    className={`sync-button ${syncStatus?.status || ''}`}
    onClick={handleSyncClick}
    disabled={syncStatus?.status === 'syncing'}
    title={getSyncButtonTitle(syncStatus)}
  >
    {syncStatus?.status === 'syncing' && '⟳ Syncing...'}
    {syncStatus?.status === 'synced' && '✓ Synced'}
    {syncStatus?.status === 'error' && '✗ Sync Failed'}
    {(!syncStatus || syncStatus.status === 'not-synced') && '☁ Sync to Context'}
  </button>

  {syncStatus?.lastSync && (
    <span className="last-sync-time">
      Last synced: {formatDistanceToNow(new Date(syncStatus.lastSync))} ago
    </span>
  )}
</div>
```

#### 3.5 Update Store Configuration

**File**: `Flexy/cospec-ai/app-react/src/store/index.ts`

Add context slice to store:

```typescript
import contextReducer from './slices/contextSlice';

export const store = configureStore({
  reducer: {
    files: filesReducer,
    ui: uiReducer,
    editor: editorReducer,
    notifications: notificationsReducer,
    context: contextReducer, // NEW
  },
});
```

### Phase 4: Documentation & Testing

#### 4.1 Update CoSpec AI CLAUDE.md

Add integration documentation to `Flexy/cospec-ai/CLAUDE.md`

#### 4.2 Add Integration Tests

Create test file: `Flexy/cospec-ai/tests/context-integration.test.js`

#### 4.3 Update Kai CLAUDE.md

Add CoSpec integration references

## Configuration

### Environment Variables

| Variable | Location | Default | Description |
|----------|----------|---------|-------------|
| `KAI_PROJECT_ID` | Flexy Container | (none) | Project ID for context scope |
| `KAI_BACKEND_URL` | Flexy Container | (none) | Kai backend URL for API calls |
| `ENABLE_CONTEXT_SYNC` | Flexy Container | `true` | Feature flag for context sync |

### Auto-Sync Patterns

Default patterns that trigger automatic syncing:

- `specs/**/*.md`
- `requirements/**/*.md`
- `docs/specs/**/*.md`
- `**/*.spec.md`
- `**/SPEC.md`
- `**/REQUIREMENTS.md`

## Frontmatter Schema

Example markdown file with context metadata:

```markdown
---
title: User Authentication Specification
tags: [authentication, security, api]
description: OAuth2 and JWT authentication implementation
entities: [User, Token, Session]
context_synced: true
context_memory_id: "550e8400-e29b-41d4-a716-446655440000"
last_synced: "2025-10-24T10:30:00Z"
---

# User Authentication Specification

Content goes here...
```

## User Experience

### Sync Status Indicators

| Status | Icon | Color | Meaning |
|--------|------|-------|---------|
| Not Synced | - | Gray | File not synced, not eligible for auto-sync |
| Auto Eligible | ● | Blue | Matches pattern, will auto-sync on change |
| Syncing | ⟳ | Yellow | Currently syncing to context |
| Synced | ✓ | Green | Successfully synced |
| Error | ✗ | Red | Sync failed (click for details) |

### User Actions

1. **Automatic Sync**: Create/edit file in `specs/` directory → Auto-syncs after 3-second delay
2. **Manual Sync**: Right-click file → "Sync to Context" → File synced immediately
3. **View Status**: Hover over file → Tooltip shows last sync time
4. **Remove Sync**: Right-click synced file → "Remove from Context" → Memory deleted
5. **Check Health**: File menu → "Context System Status" → Shows connection status

## Error Handling

### Graceful Degradation

- **Kai backend unavailable**: Show warning banner, allow editing, queue syncs for retry
- **Network timeout**: Retry 3 times with exponential backoff, then show error
- **Parse error**: Skip sync, log error, don't block file operations
- **Permission error**: Show error notification, provide manual retry option

### Error Messages

- ✗ **Sync Failed: Backend Unreachable** - Kai backend is not responding. Your edits are saved locally.
- ✗ **Sync Failed: Invalid Metadata** - Could not parse frontmatter. Check YAML syntax.
- ✗ **Sync Failed: Permission Denied** - You don't have permission to create memories in this project.

## Future Enhancements

1. **Bulk Operations**: Select multiple files → "Sync All to Context"
2. **Sync History**: View timeline of sync operations per file
3. **Conflict Resolution**: Handle case where file and memory diverge
4. **Custom Patterns**: Allow users to configure auto-sync patterns per project
5. **Bi-directional Sync**: Update file when memory is edited in Kai UI
6. **Diff Viewer**: Show what changed before syncing
7. **Org/Workspace CoSpec**: Standalone CoSpec instance in Kai for higher-level specs
