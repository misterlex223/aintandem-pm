# Workflow, Phase, Step, and Task Relationship

This document describes the hierarchical relationship between workflows, phases, steps, and tasks in the Kai system.

## Hierarchy Structure

```
Workflow → Phase → Step → Task (optional execution component)
```

## Detailed Relationships

### 1. Workflow
- A complete process definition that can be assigned to projects
- Contains multiple phases
- Has metadata like name, description, status (draft, published, archived)
- Defines the overall process flow for teams to follow
- Stores its definition in the `definition` property which contains phases and transitions

### 2. Phase (within a Workflow)
- Major segments of a workflow that represent distinct project stages
- Contains multiple steps
- Has visual properties (colors, titles) and descriptions
- Examples: "Environment Setup", "Development Phase", "Testing Phase"
- Has properties:
  - `id`: Unique identifier
  - `title`: Localized title
  - `titleEn`: English title
  - `description`: Detailed description
  - `color`: Visual color for UI representation
  - `steps`: Array of workflow steps

### 3. Step (within a Phase)
- Individual actions or tasks within a phase
- Has type (process, milestone, decision, documentation)
- Contains title, description
- **Can optionally reference a Task** via `taskId` property
- Represents a specific action to be completed
- Has properties:
  - `id`: Unique identifier
  - `title`: Title of the step
  - `description`: Detailed description of the step
  - `type`: Type of step ('process' | 'milestone' | 'decision' | 'documentation')
  - `taskId`: Optional reference to a specific task (enables execution)
  - `workflows`: Array of related workflow links

### 4. Task (referenced by a Step)
- A concrete execution unit with a Qwen Code CLI prompt
- Contains `qwenCodePrompt` for defining what command to execute
- May include a `taskFile` for additional context
- Executed in the project's sandbox environment
- Provides the actual execution logic when a step is run
- Has properties:
  - `id`: Unique identifier
  - `title`: Title of the task
  - `description`: Detailed description
  - `qwenCodePrompt`: The Qwen Code CLI prompt to execute
  - `taskFile`: Optional path to task definition file
  - `parameters`: Optional execution parameters
  - `createdAt`/`updatedAt`: Timestamps

## Key Implementation Notes

- **Optional Relationship**: Steps don't have to reference a task - they can exist as pure workflow steps for documentation or tracking purposes
- **Task Reference**: Steps have a `taskId` property that links to a specific task definition
- **Execution Flow**: When a user executes a task-enabled step, the system looks up the task by `taskId` and runs its prompt in the project's sandbox
- **UI Integration**: The Step Editor Dialog includes a dropdown to assign existing tasks to steps
- **Frontend Display**: Steps with associated tasks show a "Task" badge and an "Execute" button

## Usage Flow

1. Create or edit a workflow using the workflow editor
2. Within a phase, add steps 
3. For executable steps, assign a task in the step editor via the task assignment dropdown
4. Publish the workflow so it can be assigned to projects
5. Assign the workflow to a project through the project management interface
6. Execute steps that have associated tasks through the project workflow interface
7. Monitor task execution progress and results in the task history panel

## UI Components

- **Workflow Editor Page**: Full editing interface for creating and modifying workflows
- **Step Editor Dialog**: Modal for editing individual steps, now includes task assignment dropdown
- **Workflow Structure Editor**: Visual editor for phases and steps with drag-and-drop capabilities
- **Workflow Step Executor**: Component that allows executing tasks from the workflow view
- **Task Execution Dialog**: Modal for configuring and running tasks with additional input
- **Task History Panel**: Shows execution history and results

This structure allows workflows to be flexible - containing both conceptual steps (like documentation) and executable steps (with actual task prompts) that run in the sandbox environment.