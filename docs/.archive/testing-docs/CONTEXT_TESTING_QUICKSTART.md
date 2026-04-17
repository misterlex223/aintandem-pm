# Context System Testing - Quick Start Guide

## TL;DR

```bash
# 1. Start services (3 terminals)
cd labs/context-manager && python3 -m uvicorn src.server.app:app --reload --port 8001
cd default/Kai/backend && pnpm dev
cd default/Kai/frontend && pnpm dev

# 2. Run automated tests
cd default/Kai
./scripts/test-context-api.sh

# 3. Test frontend
open http://localhost:5173/context
```

## What Was Done (Phase 5 Progress)

### ✅ Completed Today

1. **Comprehensive Test Documentation** (`docs/CONTEXT_API_TESTING_PLAN.md`)
   - All 25 API endpoints documented
   - Detailed test cases with curl examples
   - Frontend UI testing checklist
   - Error validation scenarios

2. **Automated Test Script** (`scripts/test-context-api.sh`)
   - 13 automated test cases
   - Auto-detects Organization/Workspace/Project IDs
   - Tests core CRUD, search, and scope operations
   - Color-coded output (✓ pass / ✗ fail)

3. **Phase 5 Status Report** (`docs/PHASE5_TESTING_STATUS.md`)
   - Current progress tracking
   - Test coverage breakdown
   - Known issues and limitations

### ⏳ What's Next (Your Tasks)

1. **Run Automated Tests**
   - Execute `./scripts/test-context-api.sh`
   - Review test output
   - Report any failures

2. **Test File Import/Sync** (Manual)
   - Navigate to http://localhost:5173/context
   - Click "Import Files" button
   - Import a markdown file
   - Verify it appears in memory list

3. **Test Task Auto-Capture** (Manual)
   - Go to sandbox page
   - Execute a task
   - Check if dialog was captured to context
   - Verify in `/context` page

4. **Test Frontend UI** (Manual)
   - Test all tabs (All, Dialogs, Specs, Insights, Knowledge)
   - Test scope selection (Org → Workspace → Project)
   - Test search functionality
   - Test memory create/edit/delete

## Test Script Output Example

```
=== Context API Test Suite ===
Base URL: http://localhost:9900
Context Manager: http://localhost:8001

✓ Prerequisites check passed
✓ Using organization ID: 073f1a01-9870-4ae4-9877-1f86c23b7e1b
✓ Using workspace ID: abc-123
✓ Using project ID: xyz-789

[TEST 1] Health Check
✓ Context system is healthy

[TEST 2] Create Memory
✓ Created memory: mem_abc123xyz

[TEST 3] Get Memory by ID
✓ Retrieved memory successfully

... (10 more tests) ...

=== Test Summary ===
Total Tests: 13
Passed: 13
Failed: 0

✓ All tests passed!
```

## Quick API Test (Manual)

### 1. Health Check
```bash
curl http://localhost:9900/api/context/health | jq
```

### 2. List Memories (Organization Scope)
```bash
ORG_ID="073f1a01-9870-4ae4-9877-1f86c23b7e1b"  # Replace with your ID
curl "http://localhost:9900/api/context/memories?scope=organization&scope_id=$ORG_ID&limit=10" | jq
```

### 3. Create Test Memory
```bash
PROJECT_ID="your-project-id"  # Replace
curl -X POST http://localhost:9900/api/context/memories \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Test memory",
    "scope": "project",
    "scope_id": "'$PROJECT_ID'",
    "memory_type": "documentation",
    "tags": ["test"]
  }' | jq
```

### 4. Search Memories
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

### Error: "No projects available"
- Create at least one Organization → Workspace → Project
- Use frontend UI to create hierarchy

## File Locations

```
docs/
├── CONTEXT_API_TESTING_PLAN.md      # Comprehensive test guide
├── PHASE5_TESTING_STATUS.md         # Current status report
└── CONTEXT_TESTING_QUICKSTART.md    # This file

scripts/
└── test-context-api.sh              # Automated test script

backend/src/routes/
└── context.ts                       # Kai backend API routes

labs/context-manager/src/server/routes/
└── memory.py                        # Context-manager API routes
```

## What to Test

### Priority 1: Automated Tests ✅
Run `./scripts/test-context-api.sh` - should pass all 13 tests

### Priority 2: File Import/Sync
1. Import single file
2. Import folder
3. Check sync stats
4. Verify tracked files list

### Priority 3: Task Auto-Capture
1. Execute task
2. Check context for dialog
3. Verify metadata

### Priority 4: Frontend UI
1. Context page navigation
2. Memory CRUD operations
3. Search functionality
4. Scope selection

## Expected Results

- ✅ All automated tests pass (13/13)
- ✅ File import creates memories
- ✅ Task execution auto-captures dialog
- ✅ Frontend UI works without errors
- ✅ Scope selection filters correctly

## Questions?

See detailed documentation:
- API Testing Plan: `docs/CONTEXT_API_TESTING_PLAN.md`
- Phase 5 Status: `docs/PHASE5_TESTING_STATUS.md`
- Architecture: `docs/architecture/context-system.md`

---

**Status**: Ready for testing
**Created**: 2025-01-25
**All 25 API endpoints documented and ready to test**
