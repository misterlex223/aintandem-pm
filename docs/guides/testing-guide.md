# Testing Guide

## Overview

This guide provides comprehensive testing instructions for the Kai system, covering API endpoints, frontend UI components, and integration testing.

## Test Environment Setup

### Prerequisites
- Kai backend running on port 9900
- Frontend development server running (pnpm dev)
- Context-manager running on port 8001 (for context API tests)
- Access to test organization, workspace, and project
- Modern web browser (Chrome, Firefox, Safari, Edge)

### Starting Services

```bash
# Terminal 1: Start Context-Manager
cd labs/context-manager
python3 -m uvicorn src.server.app:app --reload --port 8001

# Terminal 2: Start Kai Backend
cd backend
pnpm dev

# Terminal 3: Start Kai Frontend
cd frontend
pnpm dev
```

## Context API Testing

### API Endpoints

**Total Endpoints**: 25

| Category | Endpoints |
|----------|-----------|
| Memory CRUD | 8 |
| Search Operations | 3 |
| Hierarchical Operations | 2 |
| File Import/Sync | 6 |
| Statistics & Health | 4 |
| Task Auto-Capture | 1 |
| Graph Visualization | 1 |

### Automated Testing

```bash
cd /home/flexy/workspace
./scripts/test-context-api.sh
```

### Manual API Tests

#### 1. Health Check
```bash
curl http://localhost:9900/api/context/health | jq
```

#### 2. List Memories (Organization Scope)
```bash
ORG_ID="your-org-id"
curl "http://localhost:9900/api/context/memories?scope=organization&scope_id=$ORG_ID&limit=10" | jq
```

#### 3. Create Memory
```bash
PROJECT_ID="your-project-id"
curl -X POST http://localhost:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Test memory",
    "scope": "project",
    "scope_id": "'$PROJECT_ID'",
    "memory_type": "documentation",
    "visibility": "workspace",
    "tags": ["test"],
    "source": {"type": "manual", "created_by": "user"}
  }' | jq
```

#### 4. Search Memories
```bash
curl -X POST http://localhost:9900/api/context/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "test",
    "scope": "project",
    "scope_id": "'$PROJECT_ID'",
    "limit": 5
  }' | jq
```

## Frontend UI Testing

### Context Browser

#### Basic Navigation
- [ ] Navigate to `/context` page successfully
- [ ] Verify context browser loads without errors
- [ ] Hierarchical tree view displays (Organization → Workspace → Project)
- [ ] Memory counts display correctly for each level
- [ ] Expand/collapse tree nodes functionality works

#### Memory List Display
- [ ] Memory cards display correctly with content preview
- [ ] Memory type indicators are visible and correct
- [ ] Memory metadata (tags, visibility, date) displays correctly
- [ ] Pagination works with multiple pages

#### Filtering & Search
- [ ] Type filter dropdown works (task-dialog, specification, etc.)
- [ ] Tag filter works on available tags
- [ ] Text search field works for keyword search
- [ ] Search results update in real-time

### Context Search Dialog

#### Quick Search Access
- [ ] Cmd+K opens search dialog (or equivalent shortcut)
- [ ] "Load Context" button opens search dialog
- [ ] Search dialog appears as overlay/modal

#### Search Interface
- [ ] Search input field appears and focuses on open
- [ ] Real-time search as user types
- [ ] Multi-select functionality for memories
- [ ] Selected results remain highlighted

### Task Context Integration

#### Task Context Panel
- [ ] Context tab appears in sandbox page
- [ ] Task context panel displays in task detail view
- [ ] "Injected Context" section shows used memories
- [ ] "Generated Dialog" shows captured conversation

#### Context Injection
- [ ] Load context button in quick task launcher works
- [ ] Context appears in task prompt preview
- [ ] Multiple context items can be loaded
- [ ] Context can be removed before task execution

## Error Validation Tests

### Missing Required Fields
```bash
curl -X POST http://localhost:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{"content": "test"}'
# Expected: 400 Bad Request
```

### Empty Query String
```bash
curl -X POST http://localhost:9900/api/context/search \
  -H "Content-Type: application/json" \
  -d '{"query": "", "scope": "project", "scope_id": "PROJECT_ID"}'
# Expected: 400 Bad Request
```

### Invalid Memory ID
```bash
curl "http://localhost:9900/api/context/memories/invalid-id-12345"
# Expected: 404 Not Found
```

## Known Issues & Notes

### Mem0 Deduplication
Mem0 automatically deduplicates similar content. When creating a memory with content similar to an existing one, the API returns:
```json
{
  "results": [],
  "relations": {...}
}
```
This is expected behavior, not an error.

### Response Format Variations
- **Create endpoint**: Returns Mem0 native format with `results` array
- **List/Get endpoints**: Return KaiMemory format with `memories` array
Both formats are correct and intentional based on the operation type.

## Troubleshooting

### Error: "Context system is disabled"
- Check `backend/.env.local` has `CONTEXT_ENABLED=true`
- Restart backend server

### Error: "Context-manager returned 500"
- Check context-manager is running on port 8001
- Check Qdrant and Neo4j are running
- View context-manager logs

### Error: "Missing required parameters: scope and scope_id"
- All list operations require scope parameters
- Get IDs from frontend at http://localhost:5173

## Success Criteria

- All automated tests pass (20/20)
- File import creates memories
- Task execution auto-captures dialog
- Frontend UI works without errors
- Scope selection filters correctly

---

**Last Updated**: 2026-01-29
**Status**: Current
