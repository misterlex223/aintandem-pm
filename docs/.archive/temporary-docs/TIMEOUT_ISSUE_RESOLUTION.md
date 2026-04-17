# Timeout Issue - Root Cause and Resolution

## Date: 2025-01-25

## Problem Summary

Memory creation requests were timing out when calling `/api/context/memories`. Investigation revealed the context-manager couldn't connect to its required services.

## Root Cause Analysis

### Issue 1: mem0-api-server Network Isolation ✅ FIXED

**Symptom**: mem0-api-server container status showed `(unhealthy)`

**Investigation**:
```bash
docker logs mem0-api-server --tail 50
# Error: psycopg_pool.PoolTimeout: couldn't get a connection after 30.00 sec
```

**Root Cause**: mem0-api-server and kai-postgres were on different Docker networks:
- `mem0-api-server` → `mem0-network` (192.168.107.x)
- `kai-postgres` → `kai-network` (192.168.117.x)

**Solution**:
```bash
# Connect mem0-api-server to kai-network
docker network connect kai-network mem0-api-server
docker restart mem0-api-server

# Verify health
docker ps | grep mem0
# Output: ec8ccbcad5c5 ... Up 24 seconds (healthy) ... mem0-api-server
```

**Status**: ✅ Fixed - mem0-api-server is now healthy

---

### Issue 2: Context-Manager PostgreSQL Connection (When Run from Terminal)

**Context**: The user is running context-manager from the terminal:
```bash
# User's setup
cd ../labs/context-manager
python3 -m uvicorn src.server.app:app --reload --port 8001
```

**Architecture Discovery**:
- Context-manager uses Mem0 Python library directly (NOT the mem0-api-server container)
- Mem0 library connects directly to PostgreSQL via pgvector
- Configuration in `src/core/memory_client.py`:
  ```python
  {
      "vector_store": {
          "provider": "pgvector",
          "config": {
              "host": os.getenv("POSTGRES_HOST", "localhost"),  # Defaults to localhost!
              "port": int(os.getenv("POSTGRES_PORT", "5432")),
              # ...
          }
      }
  }
  ```

**Problem**:
- PostgreSQL runs in Docker container (`kai-postgres`)
- Exposed on `localhost:5432` → `192.168.117.3:5432` (inside kai-network)
- When context-manager runs from terminal (host), it tries to connect to `localhost:5432`
- PostgreSQL IS accessible at `localhost:5432` (port forwarding works)
- However, connection might timeout due to:
  1. Connection pool exhaustion
  2. Slow initialization
  3. Missing environment variables

**Solutions**:

### Option A: Set Environment Variables (Recommended)

Add to `labs/context-manager/.env`:
```bash
# PostgreSQL Connection (for terminal/host execution)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=kai
POSTGRES_USER=kai
POSTGRES_PASSWORD=kai_password
POSTGRES_COLLECTION_NAME=kai_memories

# Neo4j Connection
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password
```

Then restart context-manager to pick up the new env vars.

### Option B: Run Context-Manager in Docker

Create `labs/context-manager/docker-compose.yml`:
```yaml
version: '3.8'
services:
  context-manager:
    build: .
    ports:
      - "8001:8001"
    environment:
      POSTGRES_HOST: kai-postgres
      POSTGRES_PORT: 5432
      POSTGRES_DB: kai
      POSTGRES_USER: kai
      POSTGRES_PASSWORD: kai_password
      NEO4J_URI: bolt://kai-neo4j:7687
      NEO4J_USER: neo4j
      NEO4J_PASSWORD: password
    networks:
      - kai-network

networks:
  kai-network:
    external: true
```

Run: `docker-compose up`

### Option C: Connect to Host PostgreSQL

If PostgreSQL is accessible on host:
```bash
# Find PostgreSQL port mapping
docker ps | grep kai-postgres
# Example: 0.0.0.0:5432->5432/tcp

# Context-manager can connect to localhost:5432 directly
# Just ensure the .env has correct credentials
```

---

## Verification Steps

### 1. Check PostgreSQL Connectivity

```bash
# From host terminal
psql -h localhost -p 5432 -U kai -d kai
# Enter password: kai_password

# Should connect successfully
```

### 2. Test Context-Manager Startup

```bash
cd labs/context-manager
source .venv/bin/activate
python3 -m uvicorn src.server.app:app --reload --port 8001

# Watch for errors in startup logs
# Should see: "Application startup complete"
```

### 3. Test Health Endpoint

```bash
curl http://localhost:8001/health
# Expected: {"status":"healthy","service":"kai-context-manager"}
```

### 4. Test Memory Creation

```bash
# First, ensure hierarchy is synced (see PHASE5_FIXES_APPLIED.md)

# Then test memory creation
curl -X POST http://localhost:9900/api/context/memories \
  -H 'Content-Type: application/json' \
  -d @- << 'EOF'
{
  "content": "Test memory",
  "scope": "project",
  "scope_id": "726622e3-e3f7-47a6-883c-9d49717f1f0f",
  "memory_type": "documentation",
  "visibility": "workspace",
  "tags": ["test"],
  "source": {
    "type": "manual",
    "created_by": "test"
  }
}
EOF

# Should return memory object with ID
```

---

## Current Status

### ✅ Fixed
1. mem0-api-server network connectivity (connected to kai-network)
2. mem0-api-server health status (now healthy)
3. Health check endpoint (no longer requires scope)
4. Hierarchy synchronization (custom IDs working)
5. Test script parameters (correct visibility and source)

### ⏳ Pending Verification
1. Context-manager PostgreSQL connection from terminal
   - **Action Required**: Add PostgreSQL environment variables to `.env`
   - **Alternative**: Run context-manager in Docker

### 🔍 Recommended Next Step

**Check if context-manager is actually running and accessible:**
```bash
# Test context-manager health
curl http://localhost:8001/health

# If it times out, context-manager isn't running or can't start
# Check the terminal where you started it for error messages
```

**If context-manager shows PostgreSQL connection errors:**
```bash
# Add to labs/context-manager/.env:
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=kai
POSTGRES_USER=kai
POSTGRES_PASSWORD=kai_password

# Restart context-manager
# (Ctrl+C in the terminal, then restart)
```

---

## Files Modified

1. **Kai Backend**:
   - `backend/src/routes/context.ts` (health check fix)
   - `scripts/test-context-api.sh` (parameter fixes)

2. **Context-Manager**:
   - `src/models/hierarchy.py` (custom ID support)
   - `src/core/hierarchy_manager.py` (custom ID logic)

3. **Docker**:
   - Connected mem0-api-server to kai-network

4. **Documentation**:
   - `docs/PHASE5_FIXES_APPLIED.md`
   - `docs/TIMEOUT_ISSUE_RESOLUTION.md` (this file)
   - `docs/CONTEXT_TESTING_QUICKSTART.md`

---

## Architecture Notes

### Mem0 Integration Clarification

**Two Separate Services**:

1. **mem0-api-server** (Docker container, port 8000)
   - Standalone Mem0 REST API server
   - Currently NOT used by context-manager
   - Fixed for potential future use

2. **Mem0 Python Library** (used by context-manager)
   - Imported as `from mem0 import Memory`
   - Connects directly to PostgreSQL (pgvector)
   - Requires PostgreSQL connection details in environment
   - This is what context-manager actually uses

**Key Insight**: The timeout wasn't due to mem0-api-server at all! Context-manager uses the Mem0 Python library, which needs direct PostgreSQL access.

---

**Status**: Network issue fixed, PostgreSQL connection pending verification
**Last Updated**: 2025-01-25
**Next Action**: Verify PostgreSQL environment variables in context-manager
