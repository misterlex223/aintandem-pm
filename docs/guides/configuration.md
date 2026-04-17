# Kai Configuration Guide

This guide explains how to configure Kai for different deployment scenarios.

## Table of Contents

- [Environment Variables](#environment-variables)
- [Deployment Modes](#deployment-modes)
- [Configuration Examples](#configuration-examples)
- [Troubleshooting](#troubleshooting)

---

## Environment Variables

### Backend Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `9900` | Backend server port |
| `NODE_ENV` | `development` | Node.js environment |
| `DOCKER_NETWORK` | `kai-net` | Docker network name |
| `IMAGE_NAME` | `flexy-dev-sandbox:latest` | Flexy sandbox image |
| `KAI_BASE_ROOT` | `${HOME}/KaiBase` | Base directory for all projects |
| `USER_ID` | `1000` | User ID to run backend as (production) |
| `GROUP_ID` | `1000` | Group ID to run backend as (production) |

### Frontend Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `API_BASE_URL` | ` ` (empty) | Backend API base URL (runtime, Docker) |
| `VITE_API_BASE_URL` | ` ` (empty) | Backend API base URL (build-time, dev) |
| `VITE_USE_MOCK_API` | `false` | Use mock API data in development |

---

## Deployment Modes

### Mode 1: Proxy Mode (Default, Recommended)

**When to use:** Normal operations, behind reverse proxy, single machine deployment

**Configuration:**
```bash
# No configuration needed - this is the default
docker compose up -d
```

**How it works:**
- Frontend makes relative API calls (`/api/organizations`)
- Nginx in frontend container proxies to `kai-backend:9900`
- Works seamlessly behind reverse proxies

**Access:**
- Frontend: `http://localhost:9901`
- Backend API (direct): `http://localhost:9900`
- Through frontend proxy: `http://localhost:9901/api/*`

---

### Mode 2: Direct Mode

**When to use:** Testing, distributed deployments, separate frontend/backend hosts

**Configuration:**
```bash
# Set explicit backend URL
API_BASE_URL=http://backend.example.com docker compose up -d
```

**How it works:**
- Frontend makes absolute API calls to configured URL
- Bypasses Nginx proxy entirely
- Useful for testing or multi-host deployments

**Example scenarios:**
```bash
# Test against staging backend
API_BASE_URL=https://staging-api.example.com docker compose up frontend

# Test against local backend on different port
API_BASE_URL=http://localhost:1234 docker compose up frontend

# Production with separate hosts
API_BASE_URL=https://api.production.com docker compose up
```

---

## Configuration Examples

### Example 1: Local Development (Docker Compose)

**Scenario:** Developer running full stack locally

```bash
# 1. Create base directory
mkdir -p ~/KaiBase

# 2. Start all services (proxy mode - default)
docker compose up -d

# 3. Access
# - Frontend: http://localhost:9901
# - Backend API: http://localhost:9900
# - Code Server: http://localhost:8443
```

**Files:** No configuration files needed, uses defaults

**Note:** On macOS/Windows, containers run as default user (UID 1000). On Linux production servers, set `USER_ID` and `GROUP_ID` to match your user for proper file permissions.

---

### Example 2: Production Server (Ubuntu/Linux)

**Scenario:** Production deployment on Ubuntu server with proper user permissions

```bash
# 1. Set up as your user (not root!)
# Create .env file with your user ID
cat > .env <<EOF
USER_ID=$(id -u)
GROUP_ID=$(id -g)
KAI_BASE_ROOT=${HOME}/KaiBase
EOF

# 2. Create base directory
mkdir -p ~/KaiBase

# 3. Start services
docker compose up -d

# 4. Verify containers run as your user
docker exec kai-backend id
# Output: uid=1000(appuser) gid=1000(appgroup) ...
```

**Key points:**
- Backend and code-server run as your user, not root
- Files created in KaiBase owned by your user
- Better security (non-root containers)
- Proper file permissions for editing files

---

### Example 3: Behind Reverse Proxy (Production)

**Scenario:** Production deployment with custom domain via Caddy/Nginx

```bash
# 1. Configure user (from Example 2)
cat > .env <<EOF
USER_ID=$(id -u)
GROUP_ID=$(id -g)
EOF

# 2. Start Kai services (proxy mode - default)
docker compose up -d

# 3. Configure host reverse proxy (e.g., Caddy)
# Caddyfile:
myapp.example.com {
    reverse_proxy localhost:9901
}

# 4. Access via custom domain
# https://myapp.example.com
```

**Key points:**
- Containers run as your user (non-root)
- No `API_BASE_URL` configuration needed
- Frontend automatically uses relative paths
- Reverse proxy forwards to `:9901`
- SSL/TLS handled by reverse proxy

---

### Example 4: Separate Frontend/Backend Hosts

**Scenario:** Frontend on CDN, backend on dedicated server

**Backend host (backend.example.com):**
```bash
# Only run backend
docker compose up backend -d
```

**Frontend host (frontend.example.com):**
```bash
# Configure backend URL, then run frontend
API_BASE_URL=https://backend.example.com docker compose up frontend -d
```

**Access:**
- Frontend: `https://frontend.example.com`
- Backend: `https://backend.example.com`
- Frontend makes direct API calls to backend

---

### Example 5: Development with Vite Dev Server

**Scenario:** Frontend developer working on UI

```bash
# Terminal 1: Start backend
cd backend
pnpm dev

# Terminal 2: Start frontend dev server
cd frontend
pnpm dev  # Uses Vite proxy to localhost:9900

# Or test against different backend
VITE_API_BASE_URL=http://localhost:1234 pnpm dev
```

**Configuration:**
- `frontend/vite.config.ts` includes proxy configuration
- Proxy forwards `/api/*`, `/flexy/*`, `/code-server/*` to backend
- Hot reload enabled for rapid development

---

### Example 6: Kubernetes Deployment

**Scenario:** Production Kubernetes cluster with ingress

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kai-frontend
spec:
  template:
    spec:
      containers:
      - name: frontend
        image: kai-frontend:latest
        env:
        # Use proxy mode - let ingress handle routing
        - name: API_BASE_URL
          value: ""
        ports:
        - containerPort: 80

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kai-ingress
spec:
  rules:
  - host: kai.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: kai-backend
            port:
              number: 9900
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kai-frontend
            port:
              number: 80
```

**Key points:**
- Empty `API_BASE_URL` = proxy mode
- Ingress routes `/api/*` to backend service
- Frontend uses relative paths
- Works with any ingress controller

---

## Troubleshooting

### Issue: Frontend can't connect to backend

**Symptom:** API calls fail with network errors

**Solution:**
1. Check if backend is running:
   ```bash
   docker compose ps
   curl http://localhost:9900/api/health
   ```

2. Check runtime config:
   ```bash
   curl http://localhost:9901/runtime-config.js
   ```

3. Verify Docker network:
   ```bash
   docker network inspect kai-net
   ```

---

### Issue: API calls show wrong URL in errors

**Symptom:** Errors show `http://localhost:9901/api/*` instead of expected URL

**Cause:** Running in proxy mode (default behavior)

**Solution:**
- If you want direct mode, set `API_BASE_URL`:
  ```bash
  API_BASE_URL=http://localhost:9900 docker compose up -d
  ```
- If proxy mode is correct, errors are expected to show current origin

---

### Issue: Configuration not taking effect

**Symptom:** Changed `API_BASE_URL` but frontend still uses old value

**Solution:**
1. Restart frontend container:
   ```bash
   docker compose restart frontend
   ```

2. Verify config was applied:
   ```bash
   curl http://localhost:9901/runtime-config.js
   ```

3. Clear browser cache and hard reload (Cmd/Ctrl + Shift + R)

---

### Issue: CORS errors in direct mode

**Symptom:** `CORS policy: No 'Access-Control-Allow-Origin' header`

**Cause:** Backend needs CORS configuration for cross-origin requests

**Solution:**
1. Backend should allow frontend origin in CORS settings
2. Or use proxy mode (no CORS issues)
3. For development, backend may need `CORS_ORIGIN` env var

---

## Advanced Configuration

### Custom Base Directory

**Change where projects are stored:**

```bash
# Set custom base directory
export KAI_BASE_ROOT=/mnt/data/kai-projects
mkdir -p $KAI_BASE_ROOT

# Start services
docker compose up -d
```

**Important:** Both backend and code-server must mount the same `KAI_BASE_ROOT`

---

### Custom Ports

**Change exposed ports:**

```yaml
# docker-compose.yml
services:
  frontend:
    ports:
      - "8080:80"  # Change from 9901 to 8080

  backend:
    ports:
      - "3000:9900"  # Change from 9900 to 3000
```

**Note:** If changing backend port, update frontend `API_BASE_URL` if using direct mode

---

## Configuration Files Reference

### docker-compose.yml
- Main orchestration configuration
- Service definitions, ports, networks, volumes
- Environment variable defaults

### frontend/vite.config.ts
- Vite dev server proxy configuration
- Development-only settings

### frontend/entrypoint.sh
- Runtime configuration injection
- Generates `runtime-config.js` at container startup

### frontend/Dockerfile
- Nginx proxy configuration
- Multi-stage build setup

### backend/.env.local
- Backend environment variables
- Not committed to git (use `scripts/setup-env.sh`)

---

## Best Practices

1. **Use proxy mode by default** - Simpler, works everywhere
2. **Only set `API_BASE_URL` when necessary** - For testing or special deployments
3. **Keep `KAI_BASE_ROOT` consistent** - Same path for backend and code-server
4. **Use environment-specific .env files** - Don't commit secrets
5. **Document custom configurations** - Help your team understand the setup

---

## Quick Reference

| What you want | Configuration |
|---------------|--------------|
| Run locally | `docker compose up -d` |
| Behind reverse proxy | `docker compose up -d` (no config needed!) |
| Test against different backend | `API_BASE_URL=http://other-backend docker compose up` |
| Development with hot reload | `cd frontend && pnpm dev` |
| Custom project location | `export KAI_BASE_ROOT=/path && docker compose up` |
| Build production image | `docker compose build` |

---

For more information, see:
- [Deployment Guide](./deployment.md) (if exists)
- [Development Guide](./development.md) (if exists)
- [Architecture Documentation](../architecture/)
