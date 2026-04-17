# Kai User Manual

## Table of Contents
1. [Flexy Sandbox Management](#flexy-sandbox-management)
2. [Workspace Management](#workspace-management)
3. [Workflow Management](#workflow-management)
4. [Context Management](#context-management)

---

## Flexy Sandbox Management

### Overview
Flexy Sandbox is a containerized development environment that provides isolated spaces for AI-assisted development tasks. Each sandbox runs in a Docker container with pre-installed tools and services.

### Environment Isolation and Tools

#### Core Components
- **Docker Container**: Each sandbox runs in its own isolated container with a non-root user (`flexy`)
- **tmux Sessions**: Shared session with multiple windows for different AI tools (Claude in window 1, Qwen in window 2, user shell in window 0)
- **ttyd**: Web-based terminal that allows browser access to the terminal session
- **CoSpec AI**: Markdown editor with file management capabilities
- **Development Tools**: Node.js, Python, Git, GitHub CLI, Claude Code, Qwen Code

#### Environment Variables and Configuration
The sandbox environment is configured through several environment variables:
- `ENABLE_WEBTTY`: Enables the web terminal when set to `true`
- `MARKDOWN_DIR`: Directory for Markdown files (default: current working directory)
- `COSPEC_PORT`: Port for CoSpec AI unified server (default: 9280)
- `TASK_COMPLETION_TIMEOUT`: Timeout for task completion (default: 120000ms)

### Port Forwarding Design

#### Reverse Proxy Architecture
Kai implements a reverse proxy to securely access containerized services without exposing container ports directly to the host:

1. **Shell Access**: Requests to `/flexy/:id/shell/*` are forwarded to port 9681 in the container
   - Maps to ttyd service providing web-based terminal access
   - Handles WebSocket upgrades for interactive terminal sessions

2. **CoSpec AI Frontend**: Requests to `/flexy/:id/docs/*` are forwarded to port 9280 in the container
   - Maps to CoSpec AI React frontend
   - Allows for Markdown editing and file management

3. **CoSpec AI API**: Requests to `/flexy/:id/docs/api/*` are forwarded to port 9280 in the container (API and frontend consolidated)
   - Maps to CoSpec AI backend API
   - Handles file operations and context synchronization

4. **Custom Port Forwarding**: Requests to `/flexy/:id/port/:port/*` are forwarded to the specified port in the container
   - Allows access to any service running in the sandbox (e.g., development servers)
   - Example: `/flexy/abc123/port/5173/` accesses a Vite dev server running on port 5173

#### Security Features
- No container ports are directly exposed to the host
- All access goes through Kai's reverse proxy
- Path traversal prevention through proper sanitization
- Authentication can be added at the proxy level

### Creating and Managing Sandboxes

#### Creating a Sandbox
1. Navigate to the Sandboxes page in the Kai UI
2. Click the "New Flexy" button or use the "+ Create Sandbox" button in the AI Base page
3. Provide a name for the sandbox and optional folder mapping
4. The system creates a Docker container using the `flexy-dev-sandbox:latest` image
5. The container is connected to the configured Docker network (default: `kai-net`)

#### Folder Mapping
- Host paths can be mounted to the container at `/workspace` (default mount point)
- Multiple folders can be mapped using the format: `hostPath:containerPath`
- The sandbox only sees its own project folder, maintaining isolation

#### Controlling Sandboxes
- **Start**: Activates a stopped container
- **Stop**: Stops a running container
- **Delete**: Removes the container from the system
- **Shell Access**: Opens an embedded terminal in the UI
- **Docs Access**: Opens the CoSpec AI editor
- **Tasks Access**: Opens the task management interface

---

## Workspace Management

### Organizational Hierarchy
Kai organizes projects using a three-level hierarchy:
1. **Organization**: Top-level grouping unit
2. **Workspace**: Mid-level grouping within an organization
3. **Project**: Individual development units within a workspace

### Organization Management

#### Creating Organizations
1. Navigate to the AI Base page
2. Click the "+ New Organization" button
3. Provide a name and folder path
4. The system creates the organization and a default workspace automatically

#### Organization Details
- Each organization has a unique folder path relative to the KAI_BASE_ROOT
- Contains multiple workspaces
- Cannot be deleted if it contains non-default workspaces or projects in the default workspace

### Workspace Management

#### Creating Workspaces
1. Navigate to the desired organization
2. Click the "+ New Workspace" button
3. Provide a name and folder path
4. The system creates the workspace within the organization

#### Default Workspace
- Each organization has a default workspace created automatically
- Used for initial organization setup when no other workspaces exist
- Can contain projects but cannot be deleted if it has projects

### Project Management

#### Creating Projects
1. Navigate to the desired workspace
2. Click the "+ New Project" button
3. Provide a name and folder path
4. The system creates the project within the workspace

#### Project-Sandbox Association
- Projects can be associated with a sandbox container
- Creates isolated development environment for the project
- Sandboxes can be created, started, stopped, and destroyed from the project view

#### Moving Projects
- Projects can be moved between workspaces within the same organization
- Moving a project deletes its associated sandbox (if any) and requires recreation
- The project's folder is moved on the filesystem during the move operation

### Navigation and Management Views
The system provides multiple ways to view and manage the hierarchy:

1. **Project-Centric View**: Groups by organization → workspace → project
2. **Organization-Centric View**: Shows all projects grouped by organization and workspace
3. **Flat List View**: Shows all projects in a single list
4. **Tree View**: Hierarchical navigation tree
5. **Hierarchy View**: Visual tree-like structure with expand/collapse functionality

---

## Workflow Management

### Overview
Workflow management allows organizing development tasks into structured processes with multiple phases and steps. Each project can be associated with a workflow to guide the development lifecycle.

### Workflow Structure

#### Phases
A workflow consists of one or more phases, each representing a major stage in the development lifecycle:

**Default Phases (AI Team Workflows Template):**
1. **Rapid Prototyping** (`rapid-prototyping`)
   - Requirements gathering, design, and initial implementation
   - Includes steps for triggering requirements, defining features, and reaching QA-ready state
2. **Automated QA** (`automated-qa`)
   - Establishing comprehensive automated testing and quality assurance
   - Includes steps for CI/CD setup and promoting to production candidate
3. **Continuous Optimization** (`continuous-optimization`)
   - Ongoing improvements, monitoring, and feature development
   - Includes steps for feature updates, automated QA, and production deployment

#### Steps
Each phase contains multiple steps of different types:
- **Process**: Regular development tasks
- **Milestone**: Major checkpoints or completion markers
- **Decision**: Points where workflow can branch based on conditions
- **Documentation**: Steps that create or update documentation

### Workflow Lifecycle

#### Creating Workflows
1. Navigate to the Workflows page
2. Click "+ New Workflow" or clone an existing workflow
3. Provide a name and description
4. Define the phases and steps using the visual editor
5. Workflows start in "draft" status and can be published when ready

#### Workflow Statuses
- **Draft**: In development, not yet available for projects
- **Published**: Active and can be attached to projects
- **Archived**: Inactive, cannot be used for new projects

#### Version Management
- When a published workflow is modified, a new version is automatically created
- Each project maintains a reference to a specific workflow version
- This ensures projects continue to use the same workflow definition even if the workflow is updated

### Task Management

#### Task Execution
Tasks are executable units that run Qwen Code CLI commands within project sandboxes:

1. **Ad-hoc Tasks**: Tasks executed directly in the sandbox without workflow association
2. **Workflow Tasks**: Tasks associated with specific workflow steps
3. **Executable Steps**: Steps with the `hasExecutableTask` flag set to true

#### Task Queue System
- Each sandbox has its own task queue to manage concurrent execution
- Default limit is 1 task at a time per sandbox to prevent resource conflicts
- Tasks are processed sequentially to ensure proper execution order
- Can be configured to allow multiple concurrent tasks if needed

#### Task Parameters
Tasks can include:
- **Prompt**: The Qwen Code command to execute
- **Parameters**: Additional CLI parameters for the task
- **Metadata**: Title, description, and other identifying information
- **Execution Mode**: Interactive (send to running AI session) or on-demand (execute as separate command)

#### Task Artifacts
- The system captures new or modified files created during task execution
- Artifacts are tracked and associated with the task for reference
- Provides visibility into what changes were made during task execution

### Workflow State Management
- Each project with an attached workflow maintains state tracking:
  - Current phase and step being executed
  - Status of each step (pending, in-progress, completed)
  - Last updated timestamp
- State is persisted and can be resumed if interrupted

---

## Context Management

### Overview
The context management system captures, organizes, and retrieves relevant information to support AI-assisted development. It uses a combination of vector search, graph relationships, and metadata to provide intelligent context.

### Memory System

#### Memory Types
1. **Task Dialog** (`task-dialog`): Captured conversations between user and AI during task execution
2. **Specification** (`specification`): Technical specifications and requirements documents
3. **Workflow Insight** (`workflow-insight`): Insights and observations from workflow execution
4. **Org Knowledge** (`org-knowledge`): Organizational knowledge and standards

#### Memory Scopes
- **Organization**: Available to all workspaces and projects within the organization
- **Workspace**: Available to all projects within the workspace
- **Project**: Specific to the project
- **Task**: Specific to the task execution

#### Memory Visibility
- **Private**: Only visible to the creator
- **Workspace**: Visible to all users in the workspace
- **Organization**: Visible to all users in the organization

### Auto-Capture System

#### Task Dialog Capture
- Automatically captures conversations during task execution
- Creates memory entries with the dialog content
- Stores in the task scope with private visibility by default
- Uses minimum length threshold (default 100 characters) to avoid capturing empty dialogs

#### CoSpec AI Integration
CoSpec AI Markdown editor integrates with the context system:

1. **Auto-Sync Patterns**: Files matching specific patterns are automatically synced:
   - `specs/**/*.md` - Specification documents
   - `requirements/**/*.md` - Requirements documents
   - `docs/specs/**/*.md` - Specification documentation
   - `**/*.spec.md` - Files with `.spec.md` extension
   - `SPEC.md`, `REQUIREMENTS.md` - Root specification files

2. **Manual Sync Control**: 
   - Right-click context menu option in file tree
   - Toolbar button in editor
   - API endpoints for programmatic control

3. **Metadata Storage**: Sync state is stored in `.cospec-sync/sync-metadata.json` without modifying original files

#### Frontmatter Support
Markdown files can include YAML frontmatter for additional metadata:
```yaml
---
title: User Authentication Specification
tags: [authentication, security, api]
description: OAuth2 and JWT authentication implementation
entities: [User, Token, Session]
context_synced: true
context_memory_id: "550e8400-e29b-41d4-a716-446655440000"
last_synced: "2025-10-24T10:30:00Z"
---
```

### Search Capabilities

#### Semantic Search
- Uses vector embeddings to find semantically similar content
- Supports filtering by memory type, tags, visibility, and scope
- Implements threshold-based relevance scoring

#### Graph Search
- Leverages Neo4j graph database for relationship-based queries
- Finds connected memories based on semantic relationships
- Supports hierarchical context retrieval

#### Hybrid Search
- Combines vector similarity and graph relationships
- Configurable weights for vector (default 70%) and graph (default 30%) search results
- Provides more comprehensive search results by combining multiple approaches

### Hierarchical Context
- Retrieves memories from current scope and inherited parent scopes
- For project-level queries, includes memories from workspace and organization scopes
- Maintains proper visibility restrictions while providing broader context

### System Architecture
The context system uses multiple technologies for different aspects:
1. **Qdrant**: Vector database for semantic search capabilities
2. **Neo4j**: Graph database for relationship management and graph search
3. **JSON Storage**: Fallback and caching layer
4. **Embedding Service**: Generates vector representations of text content (uses OpenAI or local models)

---

## Appendix: WebTTY and CoSpec Integration

### WebTTY (ttyd) Design
- **Purpose**: Provides browser-based access to command-line interfaces
- **Implementation**: Uses ttyd (a terminal-to-web bridge) with tmux for shared sessions
- **Multiple Windows**: Supports multiple tmux windows for different AI tools (user, Claude, Qwen)
- **WebSocket Support**: Handles real-time interactive terminal sessions through WebSocket upgrades
- **Security**: Can be configured with authentication (though defaults to none for development)

### CoSpec AI Integration
- **Markdown Editor**: Browser-based editor using Vditor for rich text editing
- **File Management**: Browse, create, edit, and delete Markdown files
- **Reverse Proxy Compatible**: Designed to work behind Kai's reverse proxy with relative paths
- **Context Sync**: Automatic and manual synchronization of Markdown files to Kai's context system
- **Hash Router**: Uses hash-based routing for compatibility with proxy paths
- **Sync Metadata**: Stores synchronization state separately in `.cospec-sync/` directory

This comprehensive system provides a complete environment for AI-assisted software development, with isolated sandboxes for safe experimentation, organized workspaces for project management, structured workflows for development processes, and intelligent context management for knowledge capture and retrieval.