# Workflow System Specification

## Overview

The Kai workflow system provides a hierarchical structure for managing development processes through workflows, phases, steps, and tasks.

## Architecture

```
Workflow → Phase → Step → Task (optional)
```

## Core Components

### Workflow

A complete process definition that can be assigned to projects.

**Properties:**
- `id`: Unique identifier
- `name`: Workflow name
- `description`: Detailed description
- `status`: draft, published, or archived
- `definition`: Contains phases and transitions

### Phase

Major segments of a workflow representing distinct project stages.

**Properties:**
- `id`: Unique identifier
- `title`: Localized title
- `titleEn`: English title
- `description`: Detailed description
- `color`: Visual color for UI representation
- `steps`: Array of workflow steps

**Example Phases:**
- Environment Setup
- Development Phase
- Testing Phase

### Step

Individual actions within a phase.

**Step Types:**
- `process`: Standard work activities
- `milestone`: Major checkpoints or deliverables
- `decision`: Points requiring human decision
- `documentation`: Informational steps
- `task`: Executable units running Qwen Code CLI commands

**Properties:**
- `id`: Unique identifier
- `title`: Step title
- `description`: Detailed description
- `type`: Step type (process, milestone, decision, documentation, task)
- `taskId`: Optional reference to a specific task
- `workflows`: Array of related workflow links

### Task

A concrete execution unit with a Qwen Code CLI prompt.

**Properties:**
- `id`: Unique identifier
- `title`: Task title
- `description`: Detailed description
- `qwenCodePrompt`: The Qwen Code CLI prompt to execute
- `taskFile`: Optional path to task definition file
- `parameters`: Optional execution parameters
- `createdAt`/`updatedAt`: Timestamps

## Workflow State Management

### Workflow State Interface

```typescript
interface WorkflowState {
  currentPhaseId: string;  // rapid-prototyping, automated-qa, continuous-optimization
  currentStepId: string | null;
  stepStatuses: Record<string, 'pending' | 'in-progress' | 'completed'>;
  lastUpdated: string;
}
```

### API Endpoints

#### Get Workflow State
```
GET /api/projects/:id/workflow
```
Returns workflow state for a project, or default state if not set.

#### Update Workflow State
```
PUT /api/projects/:id/workflow
```
Updates entire workflow state. Validates `currentPhaseId` against allowed values.

#### Update Step Status
```
PATCH /api/projects/:id/workflow/step/:stepId
```
Updates a single step status while preserving existing step statuses.

## Flow Control

### Phase Transitions

Three transition types:
- **forward**: Move to the next phase in sequence
- **feedback**: Return to a previous phase (for revisions)
- **loop**: Cycle back to the same or earlier phase for iteration

### Decision Handling

Decision points are implemented through:
- Steps of type `decision` that pause execution awaiting human input
- Conditional logic implemented through workflow design
- Transition rules determining the next phase based on decision outcomes

## Linked Workflows

A step can link to one or more other workflow definitions:

**WorkflowLink Properties:**
- `name`: Link name
- `path`: Path to linked workflow
- `description`: Link description
- `phase`: Associated phase information

**Use Cases:**
- Reference materials and documentation
- Sub-workflows triggered from main workflow
- Template workflows for customization

## Task Execution

### Task Types

Tasks with type `task` can execute Qwen Code CLI commands in project sandboxes:
- `taskPrompt`: Field containing the command to execute
- `taskParameters`: Additional parameters for customization
- Execution happens in shared tmux session of project sandbox
- Results and errors captured in task history

### Task Queue Management

- Each sandbox has configurable task limit (default: 1 concurrent task)
- Queue system manages multiple tasks when limit is reached
- Task lifecycle: pending, queued, running, completed, failed

## UI Components

### Workflow Editor Page
Full editing interface for creating and modifying workflows.

### Step Editor Dialog
Modal for editing individual steps, includes task assignment dropdown.

### Workflow Structure Editor
Visual editor for phases and steps with drag-and-drop capabilities.

### Workflow Step Executor
Component that allows executing tasks from the workflow view.

### Task Execution Dialog
Modal for configuring and running tasks with additional input.

### Task History Panel
Shows execution history and results.

## Usage Flow

1. Create or edit a workflow using the workflow editor
2. Within a phase, add steps
3. For executable steps, assign a task in the step editor
4. Publish the workflow so it can be assigned to projects
5. Assign the workflow to a project
6. Execute steps that have associated tasks
7. Monitor task execution progress in task history panel

## Visual Indicators

### Step Type Icons
- **process**: ⚙️ (Gear icon)
- **milestone**: 🏁 (Checkered flag)
- **decision**: ❓ (Question mark)
- **documentation**: 📄 (Document)
- **task**: ⚡ (Executable task)
- **linked**: 🔗 (Linked workflow)

### Phase Transition Lines
- **Forward**: Blue solid lines
- **Feedback**: Red dashed lines
- **Loop**: Yellow dotted-dashed lines

---

**Last Updated**: 2026-01-29
**Status**: Current
