# Workflow Visualizer Integration Plan

## Overview

Integrate AI Team Workflows Visualizer into Kai to enable workflow stage tracking for each project.

## Architecture

```
┌─────────────────────────────────────────┐
│          AI Team Workflows              │
│     /RD/cotandem/default/               │
│       ai-team-workflows/                │
│         └── workflow-visualizer/        │
│              (React Components)         │
└──────────────┬──────────────────────────┘
               │
               │ Copy Components
               ↓
┌─────────────────────────────────────────┐
│            Kai Frontend                 │
│  /frontend/src/components/workflow/     │
│    - WorkflowLifecycle.tsx              │
│    - PhaseCard.tsx                      │
│    - StepCard.tsx                       │
│    - WorkflowPanel.tsx                  │
│  /frontend/src/pages/                   │
│    - workflow-page.tsx (NEW)            │
└──────────────┬──────────────────────────┘
               │
               │ API Calls
               ↓
┌─────────────────────────────────────────┐
│            Kai Backend                  │
│  /backend/src/routes/workspaces.ts      │
│    - GET /api/projects/:id/workflow     │
│    - PUT /api/projects/:id/workflow     │
│  /backend/src/services/persistence.ts   │
│    - updateProjectWorkflowState()       │
└─────────────────────────────────────────┘
```

## Data Model

### Backend Types (`backend/src/types/workspace.ts`)

```typescript
export interface WorkflowState {
  currentPhaseId: string; // rapid-prototyping, automated-qa, continuous-optimization
  currentStepId: string | null;
  stepStatuses: Record<string, 'pending' | 'in-progress' | 'completed'>;
  lastUpdated: string;
}

export interface Project {
  // ... existing fields
  workflowState?: WorkflowState;
}
```

### Frontend Types (`frontend/src/lib/types.ts`)

- Same as backend types
- Already updated ✅

## Implementation Steps

### Phase 1: Backend API (Priority: High)

**File**: `backend/src/routes/workspaces.ts`

```typescript
// GET /api/projects/:id/workflow - Get workflow state
router.get('/projects/:id/workflow', async (req, res) => {
  const { id } = req.params;
  const project = await Persistence.getProjectById(id);
  if (!project) {
    return res.status(404).json({ message: 'Project not found' });
  }

  // Return default state if not set
  const workflowState = project.workflowState || {
    currentPhaseId: 'rapid-prototyping',
    currentStepId: null,
    stepStatuses: {},
    lastUpdated: new Date().toISOString()
  };

  res.json(workflowState);
});

// PUT /api/projects/:id/workflow - Update workflow state
router.put('/projects/:id/workflow', async (req, res) => {
  const { id } = req.params;
  const workflowState: WorkflowState = req.body;

  const updatedProject = await Persistence.updateProject(id, {
    workflowState: {
      ...workflowState,
      lastUpdated: new Date().toISOString()
    }
  });

  if (!updatedProject) {
    return res.status(404).json({ message: 'Project not found' });
  }

  res.json(updatedProject);
});
```

### Phase 2: Copy Workflow Visualizer Components (Priority: High)

**Source**: `/RD/cotandem/default/ai-team-workflows/workflow-visualizer/src/`

**Destination**: `/frontend/src/components/workflow/`

Components to copy:
1. `components/WorkflowLifecycle.tsx` + `.css`
2. `components/PhaseCard.tsx` + `.css`
3. `components/StepCard.tsx` + `.css`
4. `components/WorkflowPanel.tsx` + `.css`
5. `data/lifecycle.ts`
6. `types/index.ts`

### Phase 3: Create Workflow Page (Priority: High)

**File**: `frontend/src/pages/workflow-page.tsx`

```typescript
import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { WorkflowLifecycle } from '@/components/workflow/WorkflowLifecycle';
import { WorkflowState, Project } from '@/lib/types';

export function WorkflowPage() {
  const { projectId } = useParams<{ projectId: string }>();
  const [project, setProject] = useState<Project | null>(null);
  const [workflowState, setWorkflowState] = useState<WorkflowState | null>(null);

  useEffect(() => {
    // Fetch project and workflow state
    fetchProjectAndWorkflowState();
  }, [projectId]);

  const handleStepStatusChange = async (stepId: string, status: 'pending' | 'in-progress' | 'completed') => {
    if (!workflowState) return;

    const updated = {
      ...workflowState,
      stepStatuses: {
        ...workflowState.stepStatuses,
        [stepId]: status
      }
    };

    // Update via API
    await fetch(`/api/projects/${projectId}/workflow`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    });

    setWorkflowState(updated);
  };

  return (
    <div className="workflow-page">
      <h1>{project?.name} - Workflow Progress</h1>
      <WorkflowLifecycle
        workflowState={workflowState}
        onStepStatusChange={handleStepStatusChange}
        onPhaseChange={(phaseId) => {
          // Update current phase
        }}
      />
    </div>
  );
}
```

### Phase 4: Add Router for Workflow Page (Priority: High)

**File**: `frontend/src/App.tsx`

```typescript
import { WorkflowPage } from '@/pages/workflow-page';

// Add route
<Route path="/project/:projectId/workflow" element={<WorkflowPage />} />
```

### Phase 5: Update Project Card with Workflow Button (Priority: Medium)

**File**: `frontend/src/components/ai-base/project-card.tsx`

```typescript
import { useNavigate } from 'react-router-dom';

// In ProjectCard component:
const navigate = useNavigate();

const handleOpenWorkflow = () => {
  navigate(`/project/${project.id}/workflow`);
};

// Add button in CardFooter
<Button
  size="sm"
  variant="outline"
  onClick={handleOpenWorkflow}
>
  Workflow
</Button>
```

### Phase 6: Display Workflow Progress in Project Card (Priority: Low)

**File**: `frontend/src/components/ai-base/project-card.tsx`

```typescript
// Add badge showing current phase
{project.workflowState && (
  <Badge variant="secondary">
    {getPhaseDisplayName(project.workflowState.currentPhaseId)}
  </Badge>
)}

// Helper function
const getPhaseDisplayName = (phaseId: string) => {
  const phases = {
    'rapid-prototyping': '🚀 快速原型',
    'automated-qa': '🤖 自動化QA',
    'continuous-optimization': '📈 持續優化'
  };
  return phases[phaseId] || phaseId;
};
```

## Workflow Visualizer Customizations

### Required Changes to Copied Components

1. **Update base URL handling**:
   ```typescript
   // In WorkflowLifecycle.tsx
   const baseUrl = `/flexy/${sandboxId}/docs`;
   ```

2. **Add step status update callbacks**:
   ```typescript
   interface WorkflowLifecycleProps {
     workflowState?: WorkflowState;
     onStepStatusChange?: (stepId: string, status: 'pending' | 'in-progress' | 'completed') => void;
     onPhaseChange?: (phaseId: string) => void;
   }
   ```

3. **Make steps clickable to update status**:
   ```typescript
   // In StepCard.tsx
   const handleStatusClick = () => {
     const nextStatus = {
       'pending': 'in-progress',
       'in-progress': 'completed',
       'completed': 'pending'
     }[currentStatus];

     onStatusChange?.(step.id, nextStatus);
   };
   ```

## UI/UX Enhancements

### Progress Indicators

```typescript
// Calculate overall progress
const calculateProgress = (workflowState: WorkflowState) => {
  const statuses = Object.values(workflowState.stepStatuses);
  const completed = statuses.filter(s => s === 'completed').length;
  return (completed / statuses.length) * 100;
};

// Display progress bar
<Progress value={calculateProgress(workflowState)} />
```

### Phase Transitions

```typescript
// Automatically move to next phase when all steps completed
useEffect(() => {
  if (allStepsCompleted(currentPhase)) {
    suggestNextPhase();
  }
}, [workflowState]);
```

## Testing Strategy

### Backend Tests

```typescript
// backend/src/routes/workspaces.test.ts
describe('Workflow State API', () => {
  it('should get workflow state for project', async () => {
    // Test GET /api/projects/:id/workflow
  });

  it('should update workflow state for project', async () => {
    // Test PUT /api/projects/:id/workflow
  });

  it('should return default state if not set', async () => {
    // Test default state initialization
  });
});
```

### Frontend Tests

```typescript
// frontend/src/pages/workflow-page.test.tsx
describe('WorkflowPage', () => {
  it('should render workflow lifecycle', () => {
    // Test component rendering
  });

  it('should update step status on click', () => {
    // Test status update
  });
});
```

## Migration Strategy

### Existing Projects

```typescript
// Add migration script to initialize workflow state for existing projects
const initializeWorkflowStates = async () => {
  const projects = await Persistence.getAllProjects();

  for (const project of projects) {
    if (!project.workflowState) {
      await Persistence.updateProject(project.id, {
        workflowState: {
          currentPhaseId: 'rapid-prototyping',
          currentStepId: null,
          stepStatuses: {},
          lastUpdated: new Date().toISOString()
        }
      });
    }
  }
};
```

## Future Enhancements

1. **Workflow Templates**: Pre-defined workflow states for common project types
2. **Time Tracking**: Track time spent in each phase/step
3. **Team Collaboration**: Multiple users can see and update workflow state
4. **Notifications**: Alert team when phases change
5. **Analytics**: Dashboard showing workflow metrics across projects
6. **Custom Workflows**: Allow users to define custom workflow phases/steps

## Dependencies

### Frontend
- React Router (already installed)
- Existing UI components (Button, Badge, Progress, Card)
- No additional npm packages required

### Backend
- No additional dependencies required
- Uses existing persistence layer

## Deployment Checklist

- [ ] Backend API implemented and tested
- [ ] Frontend types updated
- [ ] Workflow components copied and customized
- [ ] Workflow page created
- [ ] Router updated with new route
- [ ] Project card updated with workflow button
- [ ] Integration tests passing
- [ ] Documentation updated (CLAUDE.md)
- [ ] Migration script for existing projects
- [ ] User guide created

## Timeline Estimate

- Phase 1 (Backend API): 2-3 hours
- Phase 2 (Copy components): 1-2 hours
- Phase 3 (Workflow page): 3-4 hours
- Phase 4 (Router setup): 30 minutes
- Phase 5 (Project card): 1 hour
- Phase 6 (Progress display): 1-2 hours
- Testing & Bug fixes: 2-3 hours

**Total**: 11-15 hours

## Success Criteria

1. ✅ Users can view workflow visualization for any project
2. ✅ Users can update step statuses (pending/in-progress/completed)
3. ✅ Workflow state persists across sessions
4. ✅ Project cards show current workflow phase
5. ✅ All workflows link to correct documentation in sandbox
6. ✅ Responsive design works on all screen sizes
7. ✅ No performance degradation with many projects

---

**Status**: Ready for implementation
**Priority**: High
**Estimated Effort**: Medium (11-15 hours)
