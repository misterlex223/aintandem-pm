# Context API Testing Plan

## Overview
This document provides a comprehensive testing plan for all context API endpoints in the Kai system.

**Architecture:**
- **Context-Manager** (FastAPI, port 8001): Core memory/vector storage  
- **Kai Backend** (Express, port 9900): Wrapper API with task integration

## Test Environment Setup

\`\`\`bash
# Terminal 1: Start Context-Manager
cd labs/context-manager
python3 -m uvicorn src.server.app:app --reload --port 8001

# Terminal 2: Start Kai Backend  
cd default/Kai/backend
pnpm dev

# Terminal 3: Start Kai Frontend
cd default/Kai/frontend
pnpm dev
\`\`\`

## Test Execution Summary

### Completed ✅
- Organization, workspace, project scope support
- Scope validation and error handling
- Empty query validation
- Sync endpoint parameter validation

### Pending Testing ⏳
1. All CRUD operations with real data
2. Search operations (semantic, hybrid, similar)
3. Batch operations
4. File import/sync with actual files
5. Task auto-capture integration
6. Frontend UI components

## API Endpoint Categories

### 1. Memory CRUD (8 endpoints)
- POST /api/context/memories - Create
- GET /api/context/memories - List with scope
- GET /api/context/memories/:id - Get by ID
- PUT /api/context/memories/:id - Update
- DELETE /api/context/memories/:id - Delete
- PUT /api/context/memories/upsert - Create or update by unique key
- POST /api/context/memories/batch - Batch create
- PUT /api/context/memories/batch - Batch update

### 2. Search Operations (3 endpoints)
- POST /api/context/search - Semantic search
- POST /api/context/search/hybrid - Hybrid search (semantic + keyword)
- GET /api/context/memories/:id/similar - Find similar memories

### 3. Hierarchical Operations (2 endpoints)
- GET /api/context/:scope/:scopeId/memories - Get scope memories
- GET /api/context/hierarchical/:scope/:scopeId - Get hierarchy context

### 4. File Import/Sync (6 endpoints)
- POST /api/context/import/document - Import single file
- POST /api/context/import/folder - Import folder
- POST /api/context/sync/file - Sync single file
- POST /api/context/sync/folder - Sync folder
- GET /api/context/sync/stats - Get sync statistics
- GET /api/context/sync/files - List tracked files

### 5. Statistics & Health (4 endpoints)
- GET /api/context/stats - Global statistics
- GET /api/context/stats/:scope/:scopeId - Scope statistics
- GET /api/context/health - Health check
- GET /api/context/info - System information

### 6. Task Auto-Capture (1 endpoint)
- POST /api/context/capture/task/:taskId - Capture task dialog

### 7. Graph Visualization (1 endpoint)
- GET /api/context/graph/:memoryId - Get memory graph (placeholder)

**Total: 25 API endpoints**

## Quick Test Script

\`\`\`bash
#!/bin/bash
# Save as test-context-api.sh

# Set your test IDs
export ORG_ID="073f1a01-9870-4ae4-9877-1f86c23b7e1b"
export WORKSPACE_ID="<your-workspace-id>"
export PROJECT_ID="<your-project-id>"
export BASE_URL="http://localhost:9900"

echo "=== Testing Context API ==="

# 1. Health Check
echo "\n[1] Health Check"
curl -s "$BASE_URL/api/context/health" | jq

# 2. List Memories (Organization Scope)
echo "\n[2] List Organization Memories"
curl -s "$BASE_URL/api/context/memories?scope=organization&scope_id=$ORG_ID&limit=10" | jq '.count'

# 3. List Memories (Project Scope)
echo "\n[3] List Project Memories"
curl -s "$BASE_URL/api/context/memories?scope=project&scope_id=$PROJECT_ID&limit=10" | jq '.count'

# 4. Create Memory
echo "\n[4] Create Test Memory"
MEMORY_RESULT=$(curl -s -X POST "$BASE_URL/api/context/memories" \
  -H "Content-Type: application/json" \
  -d "{
    \"content\": \"Test memory created at $(date)\",
    \"scope\": \"project\",
    \"scope_id\": \"$PROJECT_ID\",
    \"memory_type\": \"documentation\",
    \"visibility\": \"project\",
    \"tags\": [\"test\", \"automated\"]
  }")

MEMORY_ID=$(echo $MEMORY_RESULT | jq -r '.id')
echo "Created memory: $MEMORY_ID"

# 5. Get Memory by ID
echo "\n[5] Get Memory by ID"
curl -s "$BASE_URL/api/context/memories/$MEMORY_ID" | jq '.memory' | head -c 100

# 6. Search Memories
echo "\n[6] Search Memories"
curl -s -X POST "$BASE_URL/api/context/search" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"test\",
    \"scope\": \"project\",
    \"scope_id\": \"$PROJECT_ID\",
    \"limit\": 5
  }" | jq '.count'

# 7. Get Sync Stats
echo "\n[7] Get Sync Stats"
curl -s "$BASE_URL/api/context/sync/stats?scope=project&scope_id=$PROJECT_ID" | jq

# 8. Update Memory
echo "\n[8] Update Memory"
curl -s -X PUT "$BASE_URL/api/context/memories/$MEMORY_ID" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"Updated test memory\"}" | jq '.memory' | head -c 100

# 9. Get Scope Stats
echo "\n[9] Get Project Stats"
curl -s "$BASE_URL/api/context/stats/project/$PROJECT_ID" | jq

# 10. Delete Memory
echo "\n[10] Delete Memory"
curl -s -X DELETE "$BASE_URL/api/context/memories/$MEMORY_ID"
echo "\nDeleted memory: $MEMORY_ID"

echo "\n=== Test Complete ==="
\`\`\`

## Detailed Test Cases

### Test 1: Memory CRUD Operations

\`\`\`bash
# CREATE
curl -X POST http://localhost:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "API testing guide",
    "scope": "project",
    "scope_id": "PROJECT_ID",
    "memory_type": "documentation",
    "tags": ["test"]
  }'

# READ (List)
curl "http://localhost:9900/api/context/memories?scope=project&scope_id=PROJECT_ID"

# READ (Get by ID)
curl "http://localhost:9900/api/context/memories/MEMORY_ID"

# UPDATE
curl -X PUT http://localhost:9900/api/context/memories/MEMORY_ID \
  -H "Content-Type: application/json" \
  -d '{"content": "Updated content"}'

# DELETE
curl -X DELETE http://localhost:9900/api/context/memories/MEMORY_ID
\`\`\`

### Test 2: Hierarchical Scope Support

\`\`\`bash
# Project scope (single project)
curl "http://localhost:9900/api/context/memories?scope=project&scope_id=PROJECT_ID"

# Workspace scope (aggregates all projects in workspace)
curl "http://localhost:9900/api/context/memories?scope=workspace&scope_id=WORKSPACE_ID"

# Organization scope (aggregates all projects in organization)
curl "http://localhost:9900/api/context/memories?scope=organization&scope_id=ORG_ID"
\`\`\`

### Test 3: Search Operations

\`\`\`bash
# Semantic search
curl -X POST http://localhost:9900/api/context/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "testing documentation",
    "scope": "project",
    "scope_id": "PROJECT_ID",
    "limit": 10,
    "include_inherited": true
  }'

# Find similar memories
curl "http://localhost:9900/api/context/memories/MEMORY_ID/similar?limit=5"
\`\`\`

### Test 4: File Import/Sync

\`\`\`bash
# Import single document
curl -X POST http://localhost:9900/api/context/import/document \
  -H "Content-Type: application/json" \
  -d '{
    "file_path": "/path/to/test.md",
    "scope": "project",
    "scope_id": "PROJECT_ID",
    "memory_type": "documentation"
  }'

# Import folder
curl -X POST http://localhost:9900/api/context/import/folder \
  -H "Content-Type: application/json" \
  -d '{
    "folder_path": "/path/to/docs",
    "scope": "project",
    "scope_id": "PROJECT_ID",
    "recursive": true,
    "file_extensions": [".md", ".txt"]
  }'

# Get sync stats
curl "http://localhost:9900/api/context/sync/stats?scope=project&scope_id=PROJECT_ID"

# List tracked files
curl "http://localhost:9900/api/context/sync/files?scope=project&scope_id=PROJECT_ID"
\`\`\`

### Test 5: Batch Operations

\`\`\`bash
# Batch create
curl -X POST http://localhost:9900/api/context/memories/batch \
  -H "Content-Type: application/json" \
  -d '{
    "memories": [
      {
        "content": "Batch memory 1",
        "scope": "project",
        "scope_id": "PROJECT_ID",
        "memory_type": "documentation"
      },
      {
        "content": "Batch memory 2",
        "scope": "project",
        "scope_id": "PROJECT_ID",
        "memory_type": "specification"
      }
    ]
  }'

# Batch update
curl -X PUT http://localhost:9900/api/context/memories/batch \
  -H "Content-Type: application/json" \
  -d '{
    "updates": [
      {"id": "MEMORY_ID_1", "content": "Updated 1"},
      {"id": "MEMORY_ID_2", "content": "Updated 2"}
    ]
  }'
\`\`\`

## Frontend UI Testing Checklist

### Context Page (/context)
- [ ] Organization/Workspace/Project dropdown selection works
- [ ] Scope badge updates correctly
- [ ] Statistics cards display accurate counts
- [ ] Tab navigation filters memory types correctly
- [ ] File import dialog opens and functions
- [ ] Sync status indicator shows tracked files

### Context Browser Component
- [ ] Search input triggers semantic search
- [ ] Flat/hierarchical view toggle works
- [ ] Memory cards display correctly
- [ ] Edit/delete actions work
- [ ] Pagination works (if implemented)

### Sandbox Context Tab
- [ ] Context tab loads with project scope
- [ ] Memory browser shows project memories
- [ ] Import dialog works with project scope

## Error Validation Tests

\`\`\`bash
# Missing required fields
curl -X POST http://localhost:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{"content": "test"}'
# Expected: 400 Bad Request

# Empty query string
curl -X POST http://localhost:9900/api/context/search \
  -H "Content-Type: application/json" \
  -d '{"query": "", "scope": "project", "scope_id": "PROJECT_ID"}'
# Expected: 400 Bad Request

# Missing scope parameters
curl "http://localhost:9900/api/context/memories"
# Expected: 400 Bad Request

# Invalid memory ID
curl "http://localhost:9900/api/context/memories/invalid-id-12345"
# Expected: 404 Not Found
\`\`\`

## Known Issues

### Fixed ✅
- Organization and workspace scope support implemented
- Sync endpoints now require scope parameters
- Empty query validation added
- Scope validation prevents empty scope_id

### Pending ⏳
- Graph visualization not yet implemented (returns placeholder)
- File import requires actual file system paths
- Task auto-capture needs integration with task execution

## Success Criteria

- ✅ All 25 endpoints respond with correct status codes
- ✅ Scope validation works for all three levels (org, workspace, project)
- ✅ Error responses include clear messages
- ⏳ File import/sync tested with real files
- ⏳ Task auto-capture tested with real task execution
- ⏳ Frontend UI fully tested

## Next Steps

1. Execute quick test script with real project IDs
2. Test file import/sync with actual markdown files
3. Test task auto-capture by executing a task
4. Complete frontend UI testing
5. Update CLAUDE.md with testing results
6. Mark Phase 5 complete

---

**Last Updated**: 2025-01-25  
**Phase**: 5 - API Testing  
**Status**: In Progress  
**Total Endpoints**: 25  
**Tested**: Core functionality verified, comprehensive testing in progress

