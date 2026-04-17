# Phase 2 Context System - Testing Guide

**Date:** 2025-01-25
**Purpose:** Manual testing guide for Phase 2 context system features
**Prerequisites:** Backend and frontend running, Qdrant and Neo4j available

---

## 🎯 Testing Objectives

Test all Phase 2 features to ensure:
1. **Auto-capture** - Task dialogs are automatically captured as memories
2. **Manual injection** - Context can be loaded and injected into tasks
3. **Context search** - Semantic search finds relevant memories
4. **Context display** - Context information is displayed correctly
5. **End-to-end flow** - Complete workflow from search to execution to viewing

---

## 🚀 Test Environment Setup

### 1. Start All Services

```bash
# Terminal 1: Start Docker services (Qdrant + Neo4j)
cd /Users/lex.yang/RD/cotandem/default/Kai
docker compose up -d

# Terminal 2: Start backend
cd backend
pnpm dev

# Terminal 3: Start frontend
cd frontend
pnpm dev
```

### 2. Verify Services

```bash
# Check backend health
curl http://localhost:9900/api/context/health

# Expected response:
# {
#   "status": "healthy",
#   "qdrant": true,
#   "embedding": true,
#   "neo4j": true
# }
```

### 3. Access Frontend

Open browser: `http://localhost:5173`

---

## 📝 Test Cases

### Test 1: Create Test Memories

**Purpose:** Create some test memories to use for context injection

**Steps:**
1. Open browser console or use curl:

```bash
# Create org-level memory
curl -X POST http://localhost:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Always use TypeScript strict mode and ESLint for all projects. Follow Airbnb style guide.",
    "type": "org-knowledge",
    "scope": "organization",
    "scopeId": "073f1a01-9870-4ae4-9877-1f86c23b7e1b",
    "metadata": {
      "visibility": "organization",
      "tags": ["typescript", "eslint", "standards"],
      "summary": "TypeScript and ESLint standards",
      "organizationId": "073f1a01-9870-4ae4-9877-1f86c23b7e1b"
    }
  }'

# Create project-level memory
curl -X POST http://localhost:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "For React components, use functional components with hooks. Prefer named exports. Use shadcn/ui for UI components.",
    "type": "specification",
    "scope": "project",
    "scopeId": "726622e3-e3f7-47a6-883c-9d49717f1f0f",
    "metadata": {
      "visibility": "private",
      "tags": ["react", "components", "ui"],
      "summary": "React component guidelines",
      "organizationId": "073f1a01-9870-4ae4-9877-1f86c23b7e1b",
      "workspaceId": "68f8e0d8-6a00-4bee-b9ba-d800b12011b7",
      "projectId": "726622e3-e3f7-47a6-883c-9d49717f1f0f"
    }
  }'
```

**Expected:**
- Both memories created successfully
- Each returns a memory object with an ID

---

### Test 2: Quick Task Launcher - Load Context

**Purpose:** Test context loading in Quick Task Launcher

**Steps:**
1. Navigate to Sandbox page for a project
2. Find the "Quick Task Launcher" card
3. Click "Load Context" button
4. Context search dialog should open
5. Enter search query: "TypeScript"
6. Press Enter or click search
7. Results should appear with relevance scores
8. Select 1-2 memories (click checkboxes)
9. Click "Add Context" button

**Expected Results:**
- ✅ Dialog opens smoothly
- ✅ Search returns relevant results
- ✅ Can select multiple memories
- ✅ Selected memories appear as badges below prompt
- ✅ Badges show memory summary
- ✅ Can remove individual badges with X button

**Screenshot Locations:**
- Quick launcher with "Load Context" button
- Context search dialog with results
- Selected context badges displayed

---

### Test 3: Quick Task Launcher - Execute with Context

**Purpose:** Test task execution with injected context

**Steps:**
1. After loading context (Test 2), enter a prompt:
   ```
   Create a simple React button component
   ```
2. Click "Execute Task" or press Cmd/Ctrl+Enter
3. Wait for task to start
4. Navigate to "Tasks" tab

**Expected Results:**
- ✅ Task starts successfully
- ✅ Context badges clear after execution
- ✅ Task appears in history
- ✅ No errors in console

**Verify Backend:**
Check backend logs for:
```
[ContextInjection] Injecting 2 memories into task prompt
```

---

### Test 4: Advanced Task Dialog - Context Section

**Purpose:** Test context loading in Advanced Task Dialog

**Steps:**
1. In Quick Task Launcher, click "Advanced" button
2. Advanced Task Dialog opens
3. Fill in:
   - Title: "Create user profile component"
   - Description: "A reusable profile component"
   - Prompt: "Generate a React component for displaying user profile with avatar and bio"
4. Scroll to "Context" section
5. Click "Search Context" button
6. Search for "React"
7. Select relevant memories
8. Click outside dialog to close search
9. Verify selected context appears as badges
10. Click "Execute Task"

**Expected Results:**
- ✅ Context section visible in dialog
- ✅ Search button works
- ✅ Selected context displays correctly
- ✅ Context persists when search dialog closes
- ✅ Can remove individual context items
- ✅ Task executes with context

**Screenshot Locations:**
- Advanced dialog with context section
- Context badges in advanced dialog

---

### Test 5: Auto-Capture Task Dialog

**Purpose:** Verify task dialogs are auto-captured as memories

**Steps:**
1. Execute a task (from Test 3 or 4)
2. Wait for task to complete
3. Check backend logs for auto-capture messages:
   ```
   [ContextCapture] Starting dialog capture for task: ...
   [ContextCapture] Dialog captured and indexed: ...
   ```
4. Verify memory was created:
   ```bash
   # Check memories
   cat backend/data/memories.json | jq '.[] | select(.type == "task-dialog")'
   ```

**Expected Results:**
- ✅ Backend logs show capture start and completion
- ✅ Memory created with type "task-dialog"
- ✅ Memory has embedding
- ✅ Memory indexed in Qdrant

**Backend Logs to Look For:**
```
[ContextCapture] Starting dialog capture for task: <task-id>
[ContextEmbedding] Generated embedding (1536 dimensions)
[MemoryPersistence] Created memory <memory-id> (type: task-dialog, scope: project)
[ContextSearch] Indexed memory <memory-id> in Qdrant
```

---

### Test 6: Task Detail Viewer - Context Tab

**Purpose:** Test context information display in task detail

**Steps:**
1. In Tasks tab, click on a completed task
2. Task Detail Viewer dialog opens
3. Click on "Context" tab
4. Observe context panel

**Expected Results:**
- ✅ "Context" tab visible in tabs list
- ✅ Badge shows count of injected context (if any)
- ✅ Context panel displays three sections:
  - **Context Usage Stats** (Injected, Retrieved, Generated counts)
  - **Injected Context** (List of memories used in task)
  - **Generated Dialog** (Auto-captured conversation)
- ✅ Can expand/collapse memory content
- ✅ Shows memory metadata (type, tags, visibility)

**Screenshot Locations:**
- Task detail with Context tab
- Context panel showing injected memories
- Generated dialog display

---

### Test 7: Context Search - Semantic Relevance

**Purpose:** Verify semantic search returns relevant results

**Steps:**
1. Open context search dialog
2. Test different queries:
   - "React components" → Should return React-related memories
   - "TypeScript configuration" → Should return TypeScript memories
   - "authentication" → Should return auth-related memories (if any)
3. Observe relevance scores
4. Note which memories appear for each query

**Expected Results:**
- ✅ Search returns results quickly (< 2 seconds)
- ✅ Results are semantically relevant
- ✅ Relevance scores displayed (0.0 - 1.0)
- ✅ Higher scores appear first
- ✅ Can search with partial keywords

**Validation:**
- Results should make semantic sense
- "React components" should NOT return authentication memories
- Synonyms should work (e.g., "React" and "component library")

---

### Test 8: Context Panel - Load Context Action

**Purpose:** Test loading additional context from task detail view

**Steps:**
1. Open a completed task in Task Detail Viewer
2. Go to "Context" tab
3. Look for "Load Context" button in TaskContextPanel
4. Click "Load Context"
5. Context search dialog opens
6. Select additional memories
7. Confirm

**Expected Results:**
- ✅ Button is visible (if implemented in TaskContextPanel)
- ✅ Dialog opens correctly
- ✅ Can select additional context
- Note: This is for future task re-runs or updates

---

### Test 9: Hierarchical Context Retrieval

**Purpose:** Verify project tasks can access workspace and org memories

**Steps:**
1. Ensure you have memories at different scopes:
   - Organization-level (from Test 1)
   - Workspace-level
   - Project-level (from Test 1)
2. In context search dialog (project context), search for "TypeScript"
3. Observe results from all scopes

**Expected Results:**
- ✅ Search returns memories from:
  - Current project
  - Parent workspace
  - Parent organization
- ✅ Visibility rules respected:
  - `organization` memories visible everywhere
  - `workspace` memories visible in workspace projects
  - `private` memories only in owning project

**API Test:**
```bash
# Get hierarchical context for project
curl "http://localhost:9900/api/context/hierarchical/project/726622e3-e3f7-47a6-883c-9d49717f1f0f?limit=20"

# Should return memories from org + workspace + project
```

---

### Test 10: End-to-End Flow

**Purpose:** Complete workflow from context creation to task execution to viewing

**Complete Flow:**
1. **Create context memory** (Test 1) ✅
2. **Open Quick Task Launcher**
3. **Load context** - Search and select memories
4. **Enter task prompt** - "Build a login form with validation"
5. **Execute task** - Watch it run
6. **Wait for completion**
7. **View task in history**
8. **Open task detail**
9. **Check Context tab** - See injected context and generated dialog
10. **Verify auto-capture** - Check backend logs

**Full Success Criteria:**
- ✅ Context created successfully
- ✅ Context search works
- ✅ Context injected into task
- ✅ Task executes successfully
- ✅ Context visible in task detail
- ✅ Dialog auto-captured as new memory
- ✅ New memory searchable

---

## 🐛 Common Issues & Troubleshooting

### Issue 1: Search Returns No Results

**Symptoms:** Context search shows empty results

**Checks:**
1. Verify Qdrant is running: `docker ps | grep qdrant`
2. Check memories have embeddings: `cat backend/data/memories.json | jq '.[0].embedding'`
3. Verify OpenAI API key: `echo $OPENAI_API_KEY` in backend
4. Check backend logs for embedding generation errors

**Fix:**
```bash
# Restart Qdrant
docker restart kai-qdrant

# Check Qdrant health
curl http://localhost:9900/api/context/health
```

### Issue 2: Context Not Appearing in Task

**Symptoms:** Context badges shown but not used in task

**Checks:**
1. Check browser console for API errors
2. Verify `contextMemoryIds` sent in request (Network tab)
3. Check backend logs for context injection messages

**Fix:**
- Ensure backend is running latest code
- Check task execution service has context hooks

### Issue 3: Auto-Capture Not Working

**Symptoms:** Task completes but no dialog memory created

**Checks:**
1. Verify `AUTO_CAPTURE_ENABLED=true` in backend/.env.local
2. Check task output length (must be > `CAPTURE_MIN_LENGTH`)
3. Look for errors in backend logs

**Fix:**
```bash
# Check environment
grep AUTO_CAPTURE backend/.env.local

# Should see: AUTO_CAPTURE_ENABLED=true
```

### Issue 4: Context Tab Not Showing

**Symptoms:** No Context tab in Task Detail Viewer

**Checks:**
1. Verify frontend code has Context tab (line 173-181 in task-detail-viewer.tsx)
2. Check browser console for errors
3. Refresh page

**Fix:**
- Clear browser cache
- Restart frontend dev server

---

## ✅ Success Checklist

After completing all tests, verify:

- [ ] Context search returns relevant results
- [ ] Can select multiple memories in search dialog
- [ ] Selected context displays as badges
- [ ] Context injected into task prompts
- [ ] Tasks execute successfully with context
- [ ] Context tab shows in task detail
- [ ] Injected context displayed in Context tab
- [ ] Auto-capture creates task-dialog memories
- [ ] Generated dialogs appear in Context tab
- [ ] Hierarchical context retrieval works
- [ ] All backend logs show expected messages
- [ ] No errors in browser console
- [ ] No errors in backend logs

---

## 📊 Expected Test Results Summary

| Test | Feature | Expected Outcome | Status |
|------|---------|-----------------|--------|
| 1 | Create test memories | 2+ memories created | ⏳ |
| 2 | Quick launcher load context | Context badges display | ⏳ |
| 3 | Execute with context | Task runs successfully | ⏳ |
| 4 | Advanced dialog context | Context section works | ⏳ |
| 5 | Auto-capture | Dialog saved as memory | ⏳ |
| 6 | Context tab | Shows context info | ⏳ |
| 7 | Semantic search | Relevant results | ⏳ |
| 8 | Load context action | Additional context loadable | ⏳ |
| 9 | Hierarchical retrieval | Multi-scope memories | ⏳ |
| 10 | End-to-end flow | Complete workflow works | ⏳ |

---

## 📸 Screenshot Checklist

Capture screenshots of:
1. Quick Task Launcher with "Load Context" button
2. Context Search Dialog with results
3. Selected context badges in Quick Launcher
4. Advanced Task Dialog with Context section
5. Task Detail Viewer - Context tab
6. TaskContextPanel showing injected context
7. TaskContextPanel showing generated dialog
8. Backend logs showing auto-capture
9. Memory created in memories.json

---

## 🎉 Testing Complete

Once all tests pass and screenshots are captured:
1. Update Phase 2 documentation with test results
2. Mark any issues found
3. Create GitHub issues for bugs (if any)
4. Proceed to Phase 3 testing (if applicable)

---

**Testing Date:** ___________
**Tester:** ___________
**Overall Result:** ⏳ Pass / Fail
**Notes:** ___________

