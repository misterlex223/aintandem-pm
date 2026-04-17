# Kai Context System Architecture

**Version:** 1.0
**Date:** 2025-10-24
**Status:** Design Proposal

## Overview

The Kai Context System is a hierarchical memory management system inspired by [mem0](https://docs.mem0.ai), designed to capture, organize, and retrieve contextual information across AI task sessions, project specifications, workflow insights, and organizational knowledge. It aligns with Kai's Organization → Workspace → Project hierarchy and provides intelligent context sharing with hybrid storage (Vector + Graph).

## Motivation

As developers work with AI assistants (Claude, Qwen) within Kai sandboxes, valuable context is generated but currently lost:
- Task session dialogs and decisions
- Project requirements and specifications
- Workflow execution patterns and learnings
- Team conventions and architectural decisions

A context system enables:
- **AI Session Continuity**: Resume conversations with full context
- **Knowledge Reuse**: Leverage past decisions and patterns
- **Team Alignment**: Share conventions across projects
- **Smart Recommendations**: Auto-suggest relevant context for new tasks

## Architecture Principles

1. **Hierarchical Alignment**: Match Kai's Org → Workspace → Project structure
2. **Hybrid Storage**: Combine vector search (semantic) with graph relationships (structure)
3. **Selective Sharing**: Different memory types have different visibility rules
4. **Auto-Capture**: Automatic context extraction with manual control
5. **Incremental Adoption**: Designed for phased implementation

---

## 1. Memory Types & Hierarchy

### Memory Categories

| Type | Scope | Inheritance | Use Cases |
|------|-------|-------------|-----------|
| **Task Dialogs** | Project | None (isolated) | AI conversation history, debugging sessions |
| **Specifications** | Project | Workspace → Project | Requirements, design docs, API specs |
| **Workflow Insights** | Project | Org → All Projects | Execution patterns, optimization learnings |
| **Org Knowledge** | Org/Workspace | All descendants | Team conventions, architecture decisions |

### Hierarchy Mapping

```
Organization (org-123)
├─ Context: Team conventions, architectural patterns
│  ├─ Workspace (ws-456)
│  │  ├─ Context: Shared specs, team practices
│  │  └─ Project (proj-789)
│  │     ├─ Context: Task dialogs, project-specific specs
│  │     └─ Task Sessions: Individual AI conversations
```

### Visibility Rules

Each memory has a `visibility` metadata field:

- **`private`**: Project-only (default for task dialogs)
- **`workspace`**: All projects in workspace (shared specs)
- **`organization`**: All projects in org (patterns, conventions)

---

## 2. Data Models

### Memory Entity

```typescript
interface Memory {
  id: string;
  content: string; // Main text content
  type: 'task-dialog' | 'specification' | 'workflow-insight' | 'org-knowledge';
  scope: 'organization' | 'workspace' | 'project' | 'task';
  scopeId: string; // ID of org/workspace/project/task

  metadata: {
    // Hierarchy context
    organizationId?: string;
    workspaceId?: string;
    projectId?: string;
    taskId?: string;
    workflowStepId?: string;

    // Classification
    tags: string[];
    visibility: 'private' | 'workspace' | 'organization';

    // Source tracking
    sourceType: 'manual' | 'auto-captured' | 'extracted';
    capturedFrom?: string; // Task ID, workflow step ID, etc.

    // Semantic metadata
    summary?: string; // LLM-generated summary
    keyEntities?: string[]; // Extracted entities
    relatedMemoryIds?: string[]; // Cross-references
  };

  // Vector embedding for semantic search
  embedding?: number[];

  // Timestamps
  createdAt: string;
  updatedAt: string;
  lastAccessedAt?: string;
}
```

### Enhanced Task Execution

```typescript
interface TaskExecution {
  // ... existing fields from task-persistence.ts

  // Context integration fields
  contextMemoryIds?: string[]; // Context injected into task prompt
  generatedMemoryId?: string;  // Auto-captured dialog memory
  contextUsage?: {
    retrieved: number;    // # of memories searched
    injected: number;     // # of memories used in prompt
    generated: number;    // # of new memories created
  };
}
```

### Graph Relationships (Neo4j)

```cypher
// Hierarchy
(Organization)-[:HAS_WORKSPACE]->(Workspace)
(Workspace)-[:HAS_PROJECT]->(Project)
(Project)-[:HAS_TASK]->(TaskExecution)

// Memory ownership
(Memory)-[:BELONGS_TO]->(Organization|Workspace|Project|Task)

// Memory relationships
(Memory)-[:REFERENCES]->(Memory)      // Cross-references
(Memory)-[:DERIVED_FROM]->(TaskExecution)  // Auto-captured
(Memory)-[:RELATES_TO]->(WorkflowStep)     // Workflow insights
(Memory)-[:SUPERSEDES]->(Memory)      // Version tracking

// Entity extraction
(Memory)-[:MENTIONS]->(Entity)
(Entity)-[:RELATED_TO]->(Entity)
```

---

## 3. Storage Architecture

### Docker Services

Add to `docker-compose.yml`:

```yaml
services:
  # Existing services...

  qdrant:
    image: qdrant/qdrant:latest
    container_name: kai-qdrant
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant-data:/qdrant/storage
    networks:
      - kai-net
    restart: unless-stopped

  neo4j:
    image: neo4j:5-community
    container_name: kai-neo4j
    environment:
      NEO4J_AUTH: neo4j/kai-context-password
      NEO4J_PLUGINS: '["apoc"]'
    ports:
      - "7474:7474"  # Browser
      - "7687:7687"  # Bolt
    volumes:
      - neo4j-data:/data
      - neo4j-logs:/logs
    networks:
      - kai-net
    restart: unless-stopped

volumes:
  qdrant-data:
  neo4j-data:
  neo4j-logs:
```

### Storage Responsibilities

| Storage | Purpose | Operations |
|---------|---------|------------|
| **Qdrant** | Semantic search, similarity matching | Vector embedding, k-NN search, metadata filtering |
| **Neo4j** | Relationship traversal, hierarchy queries | Graph patterns, path finding, relationship inference |
| **JSON Files** | Metadata cache, quick lookups | Memory index, task-context mappings |

---

## 4. Backend Services

### Service Files (`backend/src/services/`)

#### 4.1 `context-persistence.ts`

**Responsibilities:**
- CRUD operations for memories
- Hierarchical queries with inheritance
- Metadata management

**Key Functions:**
```typescript
// Memory CRUD
async function createMemory(memory: Omit<Memory, 'id'>): Promise<Memory>
async function getMemory(id: string): Promise<Memory | null>
async function updateMemory(id: string, updates: Partial<Memory>): Promise<Memory>
async function deleteMemory(id: string): Promise<boolean>

// Hierarchical queries
async function getMemoriesForScope(
  scope: 'organization' | 'workspace' | 'project',
  scopeId: string,
  options?: {
    includeInherited?: boolean;
    types?: Memory['type'][];
    tags?: string[];
    limit?: number;
  }
): Promise<Memory[]>

// Batch operations
async function batchCreateMemories(memories: Omit<Memory, 'id'>[]): Promise<Memory[]>
async function batchUpdateMemories(updates: {id: string, changes: Partial<Memory>}[]): Promise<Memory[]>
```

#### 4.2 `context-embedding.ts`

**Responsibilities:**
- Generate embeddings for memory content
- Integrate with embedding providers (OpenAI, local models)
- Batch processing for efficiency

**Key Functions:**
```typescript
// Embedding generation
async function generateEmbedding(text: string): Promise<number[]>
async function generateEmbeddings(texts: string[]): Promise<number[][]>

// Provider management
function setEmbeddingProvider(provider: 'openai' | 'local'): void
async function initializeEmbeddingModel(): Promise<void>
```

**Configuration:**
```typescript
// .env variables
EMBEDDING_PROVIDER=openai  // or 'local'
OPENAI_API_KEY=sk-...
EMBEDDING_MODEL=text-embedding-3-small
EMBEDDING_DIMENSIONS=1536
```

#### 4.3 `context-search.ts`

**Responsibilities:**
- Semantic search via Qdrant
- Graph traversal via Neo4j
- Hybrid search with reranking
- Metadata filtering

**Key Functions:**
```typescript
// Semantic search (vector)
async function semanticSearch(
  query: string,
  options?: {
    scope?: {type: string, id: string};
    types?: Memory['type'][];
    limit?: number;
    scoreThreshold?: number;
  }
): Promise<{memory: Memory, score: number}[]>

// Graph search (relationships)
async function graphSearch(
  startNodeId: string,
  options?: {
    relationshipTypes?: string[];
    maxDepth?: number;
    limit?: number;
  }
): Promise<Memory[]>

// Hybrid search (combined)
async function hybridSearch(
  query: string,
  scopeId: string,
  options?: {
    vectorWeight?: number;  // 0-1, default 0.7
    graphWeight?: number;   // 0-1, default 0.3
    reranker?: 'none' | 'llm' | 'zero-entropy';
  }
): Promise<{memory: Memory, score: number}[]>
```

#### 4.4 `context-capture.ts`

**Responsibilities:**
- Auto-capture task dialogs from AI sessions
- Extract facts and entities from task results
- Link memories to task executions

**Key Functions:**
```typescript
// Dialog capture
async function startDialogCapture(taskId: string): Promise<string> // Returns memory ID
async function appendToDialog(memoryId: string, message: {role: string, content: string}): Promise<void>
async function finalizeDialogCapture(memoryId: string): Promise<Memory>

// Fact extraction
async function extractFacts(text: string): Promise<{
  summary: string;
  keyEntities: string[];
  insights: string[];
}>

// Auto-capture hooks (integrate with task-execution.ts)
export function onTaskStart(task: TaskExecution): Promise<void>
export function onTaskProgress(taskId: string, output: string): Promise<void>
export function onTaskComplete(task: TaskExecution): Promise<void>
```

#### 4.5 `context-injection.ts`

**Responsibilities:**
- Retrieve relevant context for task prompts
- Format context for LLM consumption
- Track context usage in task metadata

**Key Functions:**
```typescript
// Context retrieval
async function getRelevantContext(
  projectId: string,
  taskPrompt: string,
  options?: {
    maxMemories?: number;
    types?: Memory['type'][];
    includeWorkspace?: boolean;
    includeOrg?: boolean;
  }
): Promise<Memory[]>

// Context formatting
function formatContextForPrompt(memories: Memory[]): string

// Usage tracking
async function recordContextUsage(
  taskId: string,
  memoryIds: string[]
): Promise<void>
```

---

## 5. API Routes

### New Route File: `backend/src/routes/context.ts`

```typescript
// Memory CRUD
router.post('/api/context/memories', createMemoryHandler);
router.get('/api/context/memories/:id', getMemoryHandler);
router.put('/api/context/memories/:id', updateMemoryHandler);
router.delete('/api/context/memories/:id', deleteMemoryHandler);

// Search & Retrieval
router.post('/api/context/search', searchMemoriesHandler);
  // body: { query, scope?, filters?, limit?, searchType?: 'semantic' | 'graph' | 'hybrid' }

router.get('/api/context/:scope/:scopeId/memories', getScopeMemoriesHandler);
  // scope: organization|workspace|project|task
  // query params: types[], tags[], includeInherited

// Auto-capture Integration
router.post('/api/context/capture/task/:taskId', captureTaskDialogHandler);
router.get('/api/context/tasks/:taskId/dialog', getTaskDialogHandler);

// Graph Visualization
router.get('/api/context/graph/:scopeId', getMemoryGraphHandler);
  // Returns graph structure for visualization

// Batch Operations
router.post('/api/context/memories/batch', batchCreateMemoriesHandler);
router.put('/api/context/memories/batch', batchUpdateMemoriesHandler);

// Statistics
router.get('/api/context/stats/:scope/:scopeId', getContextStatsHandler);
  // Returns: total memories, by type, recent activity
```

### Enhanced Task Routes

Modify `backend/src/routes/tasks.ts`:

```typescript
// Add context-aware endpoints
router.post('/api/projects/:projectId/tasks/adhoc',
  // Add optional contextMemoryIds[] in request body
  executeAdhocTaskHandler
);

router.get('/api/projects/:projectId/tasks/:taskId/context',
  // Get injected + generated context for a task
  getTaskContextHandler
);

router.post('/api/projects/:projectId/tasks/:taskId/context/save',
  // Manually save task output as context
  saveTaskOutputAsContextHandler
);
```

---

## 6. Frontend Components

### New Components (`frontend/src/components/context/`)

#### 6.1 `context-browser.tsx`

**Purpose:** Main context browsing interface with hierarchical view

**Features:**
- Tree view: Org → Workspace → Project with memory counts
- Filter panel: Type, tags, date range, visibility
- Search bar: Real-time semantic + keyword search
- Memory cards: Preview, metadata, actions (edit, delete, view graph)

**Props:**
```typescript
interface ContextBrowserProps {
  initialScope?: { type: string; id: string };
  onSelectMemory?: (memory: Memory) => void;
  filterTypes?: Memory['type'][];
}
```

#### 6.2 `context-editor.tsx`

**Purpose:** Create/edit memory entries

**Features:**
- Rich text editor (markdown support)
- Type selector, tag input, visibility dropdown
- Auto-generate summary (LLM-based)
- Scope selector (org/workspace/project)
- Related memories picker

**Props:**
```typescript
interface ContextEditorProps {
  memory?: Memory; // For editing
  defaultScope?: { type: string; id: string };
  onSave: (memory: Memory) => void;
  onCancel: () => void;
}
```

#### 6.3 `context-search-dialog.tsx`

**Purpose:** Quick context search overlay (Cmd+K style)

**Features:**
- Instant semantic search as user types
- Keyboard navigation (↑/↓, Enter to select)
- Preview pane with highlights
- Multi-select for batch injection
- Recent searches history

**Props:**
```typescript
interface ContextSearchDialogProps {
  projectId: string;
  onSelectMemories: (memories: Memory[]) => void;
  isOpen: boolean;
  onClose: () => void;
}
```

#### 6.4 `context-graph-viewer.tsx`

**Purpose:** Visual graph of memory relationships

**Features:**
- Interactive node graph (D3.js or ReactFlow)
- Node types: Memory, Task, Project, Workflow Step
- Relationship edges: REFERENCES, DERIVED_FROM, RELATES_TO
- Click to expand, filter by relationship type
- Export graph as image

**Props:**
```typescript
interface ContextGraphViewerProps {
  rootMemoryId?: string;
  scopeId?: string;
  maxDepth?: number;
  relationshipTypes?: string[];
}
```

#### 6.5 `task-context-panel.tsx`

**Purpose:** Context sidebar in task detail view

**Features:**
- **Injected Context:** List of memories used in task prompt
- **Generated Dialog:** Summary of captured conversation
- **Actions:**
  - "Load More Context" button → Opens search dialog
  - "Save Output as Context" → Create new memory from result
  - "View Full Dialog" → Expand captured conversation

**Props:**
```typescript
interface TaskContextPanelProps {
  task: TaskExecution;
  onLoadContext: (memories: Memory[]) => void;
  onSaveContext: (content: string) => void;
}
```

---

## 7. Frontend Pages

### 7.1 New Page: `/context`

**File:** `frontend/src/pages/context-page.tsx`

**Layout:**
```
┌─────────────────────────────────────────────────┐
│ Header: Context Manager                        │
├──────────────┬──────────────────────────────────┤
│ Hierarchy    │ Memory List                      │
│ Tree         │ ┌──────────────┐                 │
│ ├─ Org 1     │ │ Memory Card 1│                 │
│ │  ├─ WS 1   │ └──────────────┘                 │
│ │  │  └─ P1  │ ┌──────────────┐                 │
│ │  └─ WS 2   │ │ Memory Card 2│                 │
│ └─ Org 2     │ └──────────────┘                 │
│              │                                  │
│ Filters:     │ Pagination: 1 2 3 ... 10        │
│ □ Dialogs    │                                  │
│ □ Specs      │                                  │
│ □ Insights   │                                  │
└──────────────┴──────────────────────────────────┘
```

**Features:**
- Hierarchical navigation
- Create new memory button
- Bulk operations (export, delete)
- Statistics dashboard (top-right): Total, by type, recent activity

### 7.2 Enhanced: `/sandbox/:id?tab=context`

**Modification:** Add "Context" tab to sandbox page

**Tab Content:**
- Project-scoped context browser
- Quick actions: "New Memory", "Import from Task"
- Integration with Tasks tab: Link task dialogs to context

### 7.3 Enhanced: AI Base Page

**Modification:** Add context indicators to project cards

**Indicators:**
- Badge showing memory count (e.g., "12 contexts")
- Icon for recent context activity
- Hover tooltip: "Last updated: 2 hours ago"

---

## 8. Data Flow Examples

### Example 1: Auto-Capture Task Dialog

**Scenario:** User runs a task to implement a feature

```
1. Task Start
   ├─ User: Click "Run Task" in Quick Task Launcher
   ├─ Frontend: POST /api/projects/{pid}/tasks/adhoc
   │   body: { title, prompt, parameters }
   └─ Backend: task-execution.ts → onTaskStart()
       ├─ context-capture.ts → startDialogCapture()
       │   ├─ Create Memory placeholder (type: task-dialog)
       │   └─ Return memoryId
       └─ Link task.generatedMemoryId = memoryId

2. Task Execution
   ├─ Backend: Stream output to frontend
   └─ Backend: context-capture.ts → onTaskProgress()
       └─ Append dialog chunks to memory.content

3. Task Complete
   ├─ Backend: task-execution.ts → onTaskComplete()
   └─ Backend: context-capture.ts → finalizeDialogCapture()
       ├─ extractFacts() → summary, key entities
       ├─ generateEmbedding(content) → vector
       ├─ Save to Qdrant (vector)
       ├─ Save to Neo4j (graph relationships)
       └─ Update task.contextUsage.generated = 1

4. Future Retrieval
   ├─ New task in same project
   ├─ semanticSearch(newTaskPrompt)
   └─ Returns relevant past dialogs with scores
```

### Example 2: Manual Context Injection

**Scenario:** User wants to reuse project specs in a new task

```
1. User: Open "Advanced Task Dialog"
   ├─ Click "Load Context" button
   └─ Opens context-search-dialog.tsx

2. Search
   ├─ User types: "authentication API spec"
   ├─ Frontend: POST /api/context/search
   │   body: { query, scope: {type: 'project', id: 'proj-123'} }
   └─ Backend: context-search.ts → hybridSearch()
       ├─ Qdrant: Semantic search (vector similarity)
       ├─ Neo4j: Graph search (related memories)
       └─ Rerank results (LLM-based or zero-entropy)

3. Selection
   ├─ User: Select 3 relevant memories
   ├─ Frontend: Display in "Context" section of dialog
   └─ Format: [Context 1] [Context 2] [Context 3] [Remove]

4. Task Execution
   ├─ Frontend: POST /api/projects/{pid}/tasks/adhoc
   │   body: { prompt, contextMemoryIds: ['mem-1', 'mem-2', 'mem-3'] }
   └─ Backend: context-injection.ts → formatContextForPrompt()
       ├─ Retrieve full memory content
       ├─ Format for LLM: "## Relevant Context\n\n### Memory 1\n..."
       ├─ Prepend to task prompt
       └─ Record task.contextUsage.injected = 3

5. Result
   ├─ Task executes with enriched context
   └─ Better quality output (uses existing specs)
```

### Example 3: Hierarchical Context Inheritance

**Scenario:** Workspace-level convention applied to all projects

```
1. Create Workspace Convention
   ├─ Admin: Navigate to /context
   ├─ Select Workspace: "Mobile Team"
   ├─ Create Memory:
   │   ├─ Type: org-knowledge
   │   ├─ Content: "Use React Native 0.72+, TypeScript strict mode"
   │   ├─ Visibility: workspace
   │   └─ Tags: [react-native, conventions, typescript]
   └─ Backend: Save with metadata.workspaceId = 'ws-456'

2. Project Task Uses Convention
   ├─ User: Create task in Project "MobileApp-iOS"
   ├─ Backend: getRelevantContext(projectId, taskPrompt)
   │   ├─ Search project memories
   │   ├─ Search workspace memories (visibility: workspace)
   │   └─ Search org memories (visibility: organization)
   └─ Return: Workspace convention + project-specific memories

3. Graph Visualization
   ├─ User: Click "View Context Graph" in project
   └─ Graph shows:
       ├─ Project node → BELONGS_TO → Workspace node
       ├─ Workspace node → HAS_MEMORY → Convention memory
       └─ Convention memory → APPLIES_TO → All workspace projects
```

---

## 9. Implementation Phases

### Phase 1: Foundation (Week 1-2)

**Goal:** Basic context storage and retrieval

**Tasks:**
1. Docker setup: Add Qdrant + Neo4j to docker-compose.yml
2. Backend services:
   - `context-persistence.ts` - CRUD operations
   - `context-embedding.ts` - OpenAI integration
   - Basic Qdrant client setup
3. API routes:
   - Memory CRUD endpoints
   - Simple search endpoint (Qdrant only)
4. Frontend:
   - `context-browser.tsx` - Basic list view
   - `context-editor.tsx` - Create/edit form
5. Testing: Unit tests for persistence, embedding

**Deliverables:**
- Manual memory creation works
- Simple semantic search functional
- Basic UI for browsing/editing

### Phase 2: Task Integration (Week 3-4)

**Goal:** Auto-capture task dialogs, manual injection

**Tasks:**
1. Backend services:
   - `context-capture.ts` - Dialog capture hooks
   - `context-injection.ts` - Context formatting
   - Integrate with `task-execution.ts`
2. API routes:
   - Task context endpoints
   - Capture/save endpoints
3. Frontend:
   - `context-search-dialog.tsx` - Quick search
   - `task-context-panel.tsx` - Task detail sidebar
   - Modify `quick-task-launcher.tsx` - Add "Load Context" button
   - Modify `task-detail-viewer.tsx` - Show context panel
4. Testing: E2E test for task capture, injection

**Deliverables:**
- Task dialogs auto-captured
- Manual context injection in task launcher
- Context displayed in task detail view

### Phase 3: Hierarchy & Sharing (Week 5-6)

**Goal:** Hierarchical queries, visibility control, graph relationships

**Tasks:**
1. Backend services:
   - Neo4j client setup
   - Graph relationship creation
   - Hierarchical query logic in `context-search.ts`
   - Visibility filtering
2. API routes:
   - Graph endpoints
   - Scope-based queries
3. Frontend:
   - `context-graph-viewer.tsx` - Graph visualization
   - Hierarchy tree in `context-browser.tsx`
   - Visibility selector in `context-editor.tsx`
4. Data migration: Backfill graph from existing memories
5. Testing: Graph query tests, visibility enforcement

**Deliverables:**
- Workspace/org-level context works
- Graph visualization shows relationships
- Visibility rules enforced

### Phase 4: Advanced Features (Week 7-8)

**Goal:** Hybrid search, reranking, workflow insights, optimization

**Tasks:**
1. Backend services:
   - Hybrid search (vector + graph)
   - Reranking algorithms (LLM-based, zero-entropy)
   - Workflow insight extraction
   - Caching layer (Redis optional)
   - Batch operations optimization
2. API routes:
   - Advanced search options
   - Statistics endpoints
   - Batch endpoints
3. Frontend:
   - Search filters (date, tags, type)
   - Context recommendation engine
   - Statistics dashboard
   - Export/import functionality
4. Performance:
   - Benchmark search latency
   - Optimize embedding generation (batch)
   - Add pagination for large result sets
5. Testing: Performance tests, load tests

**Deliverables:**
- Sub-200ms search latency
- Intelligent context recommendations
- Production-ready performance
- Complete documentation

---

## 10. Technology Stack

### Backend

**Storage:**
- **Qdrant** (`qdrant/qdrant:latest`): Vector store for semantic search
  - Collections: `memories`, `entities`
  - Embedding dimensions: 1536 (OpenAI) or 768 (local)

- **Neo4j** (`neo4j:5-community`): Graph store for relationships
  - Nodes: `Organization`, `Workspace`, `Project`, `Task`, `Memory`, `Entity`
  - Relationships: `HAS_WORKSPACE`, `BELONGS_TO`, `REFERENCES`, etc.

**Embedding Models:**
- **OpenAI** (production): `text-embedding-3-small` (1536 dims, $0.02/1M tokens)
- **Local** (development): `nomic-embed-text` via Ollama (768 dims, free)

**Dependencies:**
```json
{
  "@qdrant/js-client-rest": "^1.9.0",
  "neo4j-driver": "^5.15.0",
  "openai": "^4.20.0"
}
```

### Frontend

**UI Components:**
- **shadcn/ui**: Dialog, Card, Input, Select, Badge
- **ReactFlow** or **D3.js**: Graph visualization
- **react-markdown**: Rich text display
- **cmdk**: Command palette for quick search

**State Management:**
- Zustand store: `frontend/src/stores/context-store.ts`
  ```typescript
  interface ContextStore {
    memories: Memory[];
    selectedMemory: Memory | null;
    searchQuery: string;
    filters: { types: string[], tags: string[], ... };
    // Actions
    fetchMemories: (scope) => Promise<void>;
    searchMemories: (query) => Promise<void>;
    createMemory: (memory) => Promise<void>;
    // ...
  }
  ```

**Dependencies:**
```json
{
  "reactflow": "^11.10.0",
  "react-markdown": "^9.0.0",
  "cmdk": "^0.2.0"
}
```

---

## 11. Configuration

### Environment Variables

Add to `backend/.env`:

```bash
# Context System
CONTEXT_ENABLED=true

# Qdrant
QDRANT_URL=http://kai-qdrant:6333
QDRANT_API_KEY=  # Optional, for cloud deployment

# Neo4j
NEO4J_URI=bolt://kai-neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=kai-context-password

# Embeddings
EMBEDDING_PROVIDER=openai  # or 'local'
OPENAI_API_KEY=sk-...
EMBEDDING_MODEL=text-embedding-3-small
EMBEDDING_DIMENSIONS=1536

# Context Capture
AUTO_CAPTURE_ENABLED=true
CAPTURE_MIN_LENGTH=100  # Don't capture very short dialogs
EXTRACT_FACTS_ENABLED=true  # LLM-based fact extraction

# Search
DEFAULT_SEARCH_LIMIT=20
SEMANTIC_SCORE_THRESHOLD=0.7
RERANKER_TYPE=llm  # 'none', 'llm', 'zero-entropy'
```

### Feature Flags

Add to `frontend/src/lib/config.ts`:

```typescript
export const contextConfig = {
  enabled: import.meta.env.VITE_CONTEXT_ENABLED !== 'false',
  autoCapture: import.meta.env.VITE_AUTO_CAPTURE_ENABLED !== 'false',
  graphVisualization: import.meta.env.VITE_GRAPH_VIZ_ENABLED !== 'false',
  maxMemoriesPerSearch: 50,
};
```

---

## 12. Security & Privacy

### Access Control

1. **Hierarchy-based permissions:**
   - Users can only access memories in their org/workspace/projects
   - Implement `canAccessMemory(userId, memoryId)` checks

2. **Visibility enforcement:**
   - Private memories: Only accessible by project members
   - Workspace memories: All workspace members
   - Org memories: All org members

3. **Sensitive data:**
   - Add `sensitive: boolean` flag to Memory metadata
   - Exclude sensitive memories from auto-capture
   - Require explicit confirmation for deletion

### Data Retention

1. **Auto-cleanup:**
   - Task dialogs: Keep 90 days (configurable)
   - Workflow insights: Keep indefinitely
   - Org knowledge: Keep indefinitely

2. **Manual retention:**
   - Users can "pin" important memories
   - Pinned memories excluded from auto-cleanup

3. **GDPR compliance:**
   - Add "Export my context" feature
   - Add "Delete all my context" feature
   - Anonymize user data on account deletion

---

## 13. Performance Considerations

### Embedding Generation

**Problem:** OpenAI API latency (100-500ms per request)

**Solutions:**
1. **Batch processing:** Generate embeddings for multiple memories in single API call
2. **Async jobs:** Queue embedding generation, process in background
3. **Caching:** Cache embeddings, only regenerate on content change
4. **Local fallback:** Use local model (Ollama) when OpenAI unavailable

### Search Latency

**Target:** < 200ms for typical queries

**Optimizations:**
1. **Qdrant indexing:** Use HNSW index with optimized parameters
2. **Metadata filtering:** Filter before vector search (faster)
3. **Result caching:** Cache frequent queries (Redis)
4. **Pagination:** Limit results, fetch more on demand
5. **Graph query limits:** Set max depth, max nodes

### Storage Growth

**Estimates:**
- Task dialog: ~10KB per task
- 1000 tasks/month → ~10MB/month → 120MB/year
- Vector embeddings: 1536 floats × 4 bytes = 6KB per memory
- Graph nodes: ~1KB per memory

**Total for 10,000 memories:**
- Text content: ~100MB
- Embeddings: ~60MB
- Graph data: ~10MB
- **Total: ~170MB** (very manageable)

---

## 14. Monitoring & Observability

### Metrics to Track

1. **Usage metrics:**
   - Total memories created (by type)
   - Search queries per day
   - Context injection rate (% of tasks)
   - Auto-capture success rate

2. **Performance metrics:**
   - Search latency (p50, p95, p99)
   - Embedding generation time
   - Graph query time
   - API endpoint response times

3. **Quality metrics:**
   - Context relevance (user feedback)
   - Reranking effectiveness
   - Fact extraction accuracy

### Logging

Add structured logging to all context services:

```typescript
logger.info('context.search', {
  query,
  scope,
  resultCount,
  latency,
  userId,
});

logger.info('context.capture', {
  taskId,
  memoryId,
  dialogLength,
  factsExtracted,
});
```

---

## 15. Future Enhancements

### Phase 5+ (Post-MVP)

1. **Multi-modal support:**
   - Image memories (screenshots, diagrams)
   - Code snippet memories (syntax highlighting)
   - Link previews (fetch metadata)

2. **Collaborative features:**
   - Share memories with team members
   - Comment on memories
   - Suggest edits to shared knowledge

3. **AI-powered suggestions:**
   - Auto-suggest tags based on content
   - Recommend related memories during task creation
   - Detect duplicate/similar memories

4. **Advanced analytics:**
   - Context usage heatmaps
   - Knowledge gap detection
   - Team knowledge graph visualization

5. **Integration expansions:**
   - Export to Notion, Confluence
   - Import from Google Docs, Markdown files
   - Sync with external knowledge bases

6. **Custom memory types:**
   - User-defined memory categories
   - Custom metadata schemas
   - Workflow-specific memory templates

---

## 16. Migration Strategy

### From Current State

**Current:** No context system, task dialogs lost after execution

**Migration Path:**

1. **Phase 1 (Non-breaking):**
   - Deploy context system alongside existing features
   - All features opt-in initially
   - No changes to existing task execution

2. **Phase 2 (Backfill):**
   - Offer "Import Past Tasks" feature
   - Convert task history to task-dialog memories
   - Preserve timestamps, metadata

3. **Phase 3 (Enable by default):**
   - Auto-capture enabled for new tasks
   - User can disable per-project
   - Provide "Context Migration Complete" notification

4. **Phase 4 (Full integration):**
   - Context recommendations in task launcher
   - Workflow insights from execution history
   - Org-wide knowledge base established

### Data Export/Import

**Export format (JSON):**
```json
{
  "version": "1.0",
  "exportedAt": "2025-10-24T12:00:00Z",
  "scope": { "type": "project", "id": "proj-123" },
  "memories": [
    {
      "id": "mem-456",
      "content": "...",
      "type": "specification",
      "metadata": { ... },
      "relationships": [
        { "type": "REFERENCES", "targetId": "mem-789" }
      ]
    }
  ]
}
```

**Import:**
- Validate schema version
- Map old IDs to new IDs
- Recreate graph relationships
- Regenerate embeddings

---

## 17. Documentation Requirements

### User Documentation

1. **Quick Start Guide:**
   - "What is Context in Kai?"
   - "How to capture context from tasks"
   - "How to search and reuse context"

2. **Feature Guides:**
   - "Managing project specifications"
   - "Sharing knowledge across teams"
   - "Visualizing context relationships"

3. **Best Practices:**
   - "Organizing context with tags"
   - "When to use private vs shared context"
   - "Optimizing AI task performance with context"

### Developer Documentation

1. **API Reference:**
   - All context API endpoints
   - Request/response schemas
   - Error codes and handling

2. **Architecture Docs:**
   - System diagram (this document)
   - Data flow diagrams
   - Graph schema reference

3. **Integration Guide:**
   - How to capture context from custom sources
   - How to extend memory types
   - How to add custom search filters

---

## 18. Success Metrics

### KPIs (3 months post-launch)

1. **Adoption:**
   - 80%+ of projects have at least 1 memory
   - 50%+ of tasks use context injection
   - 10+ memories per active project (average)

2. **Quality:**
   - 4.0+ user satisfaction rating (1-5 scale)
   - 70%+ context relevance score
   - < 200ms average search latency

3. **Engagement:**
   - 5+ searches per user per week
   - 20%+ of tasks reference past context
   - 30%+ of users create manual memories

4. **Impact:**
   - 20% reduction in duplicate specifications
   - 15% improvement in task success rate (subjective)
   - 10+ team conventions documented per workspace

---

## 19. Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Embedding API cost too high | High | Medium | Implement local model fallback, batch processing, caching |
| Search quality poor | High | Medium | Hybrid search, reranking, user feedback loop |
| Graph DB complexity | Medium | Low | Start simple (few relationship types), add incrementally |
| User adoption low | High | Medium | Make auto-capture seamless, show value early, user education |
| Storage growth excessive | Medium | Low | Implement retention policies, compression, archiving |
| Integration breaks tasks | High | Low | Thorough testing, feature flags, graceful degradation |

---

## 20. Conclusion

The Kai Context System provides a **production-ready, scalable solution** for managing contextual knowledge across AI task sessions, projects, and teams. By leveraging proven architecture patterns from mem0 and aligning with Kai's existing hierarchy, it enables:

✅ **Seamless AI continuity** through auto-captured task dialogs
✅ **Knowledge reuse** via intelligent semantic search
✅ **Team alignment** through shared conventions and insights
✅ **Relationship understanding** via graph visualization
✅ **Incremental adoption** through phased implementation

The hybrid storage approach (Vector + Graph) balances **semantic search power** with **structural relationship tracking**, while the hierarchical visibility model ensures **appropriate context sharing** across organizational boundaries.

**Next Steps:**
1. Review and approve this design
2. Set up Phase 1 development environment
3. Begin implementation with Foundation phase
4. Iterate based on user feedback

---

## Appendix A: Comparison with mem0

| Feature | mem0 | Kai Context System |
|---------|------|-------------------|
| **Hierarchy** | user_id, agent_id, run_id | Organization → Workspace → Project → Task |
| **Storage** | Vector + Graph | Vector (Qdrant) + Graph (Neo4j) |
| **Memory Types** | Unified memories | 4 types: dialogs, specs, insights, knowledge |
| **Visibility** | User-scoped | 3 levels: private, workspace, organization |
| **Integration** | API-based, language SDKs | Deep integration with task execution |
| **Auto-capture** | Manual add() calls | Automatic task dialog capture |
| **Search** | Semantic + filters | Hybrid (semantic + graph + reranking) |
| **UI** | API-only (self-hosted) | Full-featured web UI |
| **Graph** | Entities + relationships | Hierarchy + memories + relationships |

**Key Differences:**
- mem0 is a general-purpose memory layer; Kai's is domain-specific (dev workflows)
- Kai adds hierarchical visibility and project-based scoping
- Kai auto-captures from task executions (mem0 requires explicit calls)
- Kai provides rich UI; mem0 is primarily API-driven

---

## Appendix B: Example Memory Data

### Task Dialog Memory

```json
{
  "id": "mem-abc123",
  "content": "**Task:** Implement user authentication\n\n**User:** I need to add JWT-based authentication to the API.\n\n**Claude:** I'll help you implement JWT authentication. Let me start by...\n\n[Full conversation content]",
  "type": "task-dialog",
  "scope": "task",
  "scopeId": "task-xyz789",
  "metadata": {
    "projectId": "proj-123",
    "workspaceId": "ws-456",
    "organizationId": "org-789",
    "taskId": "task-xyz789",
    "tags": ["authentication", "jwt", "api"],
    "visibility": "private",
    "sourceType": "auto-captured",
    "capturedFrom": "task-xyz789",
    "summary": "Implemented JWT-based authentication with refresh tokens, added middleware for route protection, and created login/logout endpoints.",
    "keyEntities": ["JWT", "authentication", "middleware", "login"],
    "relatedMemoryIds": []
  },
  "embedding": [0.023, -0.145, 0.089, ...],
  "createdAt": "2025-10-24T10:30:00Z",
  "updatedAt": "2025-10-24T10:45:00Z",
  "lastAccessedAt": "2025-10-24T14:20:00Z"
}
```

### Specification Memory

```json
{
  "id": "mem-def456",
  "content": "# API Authentication Specification\n\n## Overview\nOur API uses JWT (JSON Web Tokens) for stateless authentication.\n\n## Endpoints\n- `POST /auth/login` - Returns access + refresh tokens\n- `POST /auth/refresh` - Exchanges refresh token for new access token\n- `POST /auth/logout` - Invalidates refresh token\n\n## Token Format\n- Access token: 15min expiry\n- Refresh token: 7 days expiry\n- Algorithm: HS256\n\n## Security\n- Tokens stored in httpOnly cookies\n- CSRF protection enabled\n- Rate limiting: 5 requests/min per IP",
  "type": "specification",
  "scope": "project",
  "scopeId": "proj-123",
  "metadata": {
    "projectId": "proj-123",
    "workspaceId": "ws-456",
    "organizationId": "org-789",
    "tags": ["authentication", "api", "security", "specification"],
    "visibility": "workspace",
    "sourceType": "manual",
    "summary": "JWT-based API authentication specification with 15min access tokens, 7-day refresh tokens, and httpOnly cookie storage.",
    "keyEntities": ["JWT", "access token", "refresh token", "HS256", "httpOnly"],
    "relatedMemoryIds": ["mem-abc123"]
  },
  "embedding": [0.056, -0.092, 0.134, ...],
  "createdAt": "2025-10-23T16:00:00Z",
  "updatedAt": "2025-10-24T09:00:00Z",
  "lastAccessedAt": "2025-10-24T14:20:00Z"
}
```

### Workflow Insight Memory

```json
{
  "id": "mem-ghi789",
  "content": "**Pattern:** When implementing authentication, always implement refresh token rotation to prevent token theft.\n\n**Context:** Observed across 5 projects that static refresh tokens led to security issues. Best practice is to issue a new refresh token with each access token refresh.\n\n**Implementation:** Store refresh token family ID in database, invalidate all tokens in family if rotation broken.",
  "type": "workflow-insight",
  "scope": "organization",
  "scopeId": "org-789",
  "metadata": {
    "organizationId": "org-789",
    "workflowStepId": "step-auth-impl",
    "tags": ["authentication", "security", "best-practice", "refresh-token"],
    "visibility": "organization",
    "sourceType": "extracted",
    "capturedFrom": "task-abc111,task-abc222,task-abc333",
    "summary": "Always implement refresh token rotation for security, using token family IDs to detect theft.",
    "keyEntities": ["refresh token rotation", "token family", "security"],
    "relatedMemoryIds": ["mem-def456"]
  },
  "embedding": [0.089, -0.112, 0.067, ...],
  "createdAt": "2025-10-20T12:00:00Z",
  "updatedAt": "2025-10-24T08:00:00Z",
  "lastAccessedAt": "2025-10-24T14:20:00Z"
}
```

---

**Document Version:** 1.0
**Last Updated:** 2025-10-24
**Maintained By:** Kai Development Team
**Review Schedule:** Monthly during Phase 1-4, Quarterly thereafter
