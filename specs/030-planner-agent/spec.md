# Feature Specification: Planner Agent

**Feature Branch**: `030-planner-agent`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a planner agent that analyzes user context and patterns to suggest tasks, plans, and next actions"

## User Scenarios & Testing

### User Story 1 - Context-Aware Task Suggestions (Priority: P1)

The planner agent analyzes the user's current context (open projects, recent activity, pending items) and suggests tasks: "Based on your recent work on the storage layer, you might want to: (1) Write tests for the new SQLite adapter, (2) Review the storage spec, (3) Update the storage architecture doc." Suggestions are ranked by priority and include rationale.

**Why this priority**: Task suggestions turn passive context into actionable work items. Users don't need to remember what to do next.

**Independent Test**: After a day of coding the storage layer, open the planner. Verify it suggests 3 tasks with rationales like "You modified 4 storage files today — consider adding tests for the new adapter" and "You referenced the storage spec 3 times but haven't updated it."

**Acceptance Scenarios**:

1. **Given** the user has been editing files in the "storage" module, **When** the planner analyzes context, **Then** it suggests tasks related to storage (e.g., write tests, review spec, refactor) with rationale based on activity patterns
2. **Given** no recent activity, **When** the planner is opened, **Then** it shows "No task suggestions available — start working to generate suggestions" with a prompt

---

### User Story 2 - Goal Management and Tracking (Priority: P1)

The user can create goals like "Read 30 minutes daily" or "Complete auth module by Friday". The goal engine tracks progress by matching events to goals — reading sessions count toward "Read 30 min daily", and events mentioning "auth" count toward the auth module goal. Progress is shown in the Now bar (spec 023). When a goal is falling behind, the planner schedules a nudge.

**Why this priority**: Goals are the core building block of proactive suggestions. Without goals, the agent host has no basis to suggest anything meaningful. Goals also bridge capture (what you did) to intention (what you wanted to do).

**Independent Test**: Create a goal "Write tests for 30 min daily". Work on test files for 15 min. Verify the goal shows 15/30 min in the Now bar. Skip a day. Verify a nudge appears the next morning: "You missed your test-writing goal yesterday. 15 min now?"

**Acceptance Scenarios**:

1. **Given** a goal "Read 30 min daily", **When** the user opens PDFs or documentation for 12 minutes, **Then** goal progress shows 12/30 min
2. **Given** a goal falling behind (e.g., 5/30 min at end of day), **When** the agent host runs the suggestion loop, **Then** a goal nudge is created: "You missed your [goal] target yesterday. [suggested duration] now?"
3. **Given** a goal that has been inactive for 7+ days, **When** the agent host reviews goals, **Then** it suggests archiving or removing the goal: "You haven't worked on 'Learn French' in 7 days. Archive it?"

**Goal CRUD**:

1. **Given** the user is on the Topics/Home screen, **When** they click "Add Goal", **Then** a form opens with fields: title, target (duration or sessions or date), period (daily/weekly/custom), optional trigger keywords for auto-matching
2. **Given** a goal, **When** the user clicks "Edit", **Then** the goal form opens pre-filled for editing
3. **Given** a goal, **When** the user clicks "Delete", **Then** a confirmation dialog appears; confirming removes the goal permanently

---

### User Story 3 - Daily Plan Generation (Priority: P2)

Each morning (or at user's preferred time), the planner generates a daily plan: a prioritized list of suggested tasks for the day, based on the previous day's unfinished work, recurring patterns, upcoming deadlines, and the user's energy patterns (morning = deep work, afternoon = meetings/review). The plan appears on Home.

**Why this priority**: A daily plan saves users 10-15 minutes of planning time. It also helps them start the day with direction.

**Independent Test**: After a week of OSAI usage, check the morning plan. Verify it includes: "Continue: implement search endpoint" (continued from yesterday), "Prepare: weekly sync notes" (recurring Tuesday task), "Deep work: storage benchmarking" (scheduled for morning based on energy patterns).

**Acceptance Scenarios**:

1. **Given** the user has unfinished work from yesterday, **When** the daily plan is generated, **Then** it includes "Continue: [task]" as the first priority item with a link to yesterday's last session
2. **Given** the user has recurring tasks on specific days (e.g., Monday standup prep), **When** the daily plan is generated, **Then** recurring tasks appear with a calendar icon and recurrence label

---

### User Story 3 - Project Roadmap Suggestions (Priority: P3)

For each project, the planner can generate a suggested roadmap: a set of milestones and tasks derived from project context. For example, if the project has recent events about "implementing auth", "fixing bugs", and "writing docs", the planner might suggest milestones: "M1: Auth Implementation Complete", "M2: Bug Bash", "M3: Documentation Pass".

**Why this priority**: Project roadmaps help users see the big picture and plan their work strategically rather than reactively.

**Independent Test**: For a project with 50+ events spanning 2 weeks, request a roadmap. Verify it includes 3-5 milestones with suggested tasks under each, derived from actual activity patterns.

**Acceptance Scenarios**:

1. **Given** a project with events covering "authentication", "database schema", and "API endpoints", **When** the user requests `generate_roadmap({ projectId: "osai" })`, **Then** the response suggests a phased roadmap with milestones like "Phase 1: Auth & Schema", "Phase 2: API Layer", "Phase 3: Testing" with tasks under each
2. **Given** a project with insufficient events (<20), **When** requesting a roadmap, **Then** the planner responds "Not enough activity data to generate a roadmap" with a suggestion to work more on the project

---

### User Story 4 - Time Estimation and Scheduling (Priority: P3)

The planner estimates how long suggested tasks will take based on the user's historical velocity. "Write storage tests" might be estimated at 45 minutes based on past test-writing sessions. Tasks can be dragged into a schedule for the day. The planner warns if the schedule is overcommitted.

**Why this priority**: Time estimation helps users make realistic plans. Most people underestimate task duration; historical data provides objective estimates.

**Independent Test**: Schedule 3 tasks: "Write tests" (est. 45min), "Review PR" (est. 20min), "Update docs" (est. 30min). Verify the total is 1h 35min. Add 4 more tasks and verify the planner warns "Estimated total: 4h 20min exceeds your available time today (3h)."

**Acceptance Scenarios**:

1. **Given** a task "Implement search endpoint", **When** the planner estimates time, **Then** it returns "Estimated: 2h 15min (based on 3 similar coding sessions)" with a confidence indicator
2. **Given** a schedule with 5 tasks totaling 6 hours, **When** the user has only 4 hours of free time today, **Then** the planner warns "Schedule overcommitted by 2 hours" with suggestions for which tasks to defer

---

### User Story 5 - Plan Tracking and Adaptation (Priority: P3)

The planner tracks whether the user follows the suggested plan. If the user ignores suggested tasks and works on something else, the planner adapts: it updates the plan to reflect actual work, moves incomplete tasks to the next day, and notes deviations as learning signals.

**Why this priority**: Plans that don't adapt are useless. The planner should learn from user behavior and improve its suggestions.

**Independent Test**: The planner suggests "Write tests" as priority 1. The user instead works on "Fix bug in search." At end of day, check the plan — verify "Write tests" is moved to tomorrow, and "Fix bug in search" is added as completed. Verify a note: "You worked on bug fixes instead of tests — adjusting future suggestions."

**Acceptance Scenarios**:

1. **Given** a daily plan with 3 suggested tasks, **When** the user completes 2 of them and works on 1 unplanned task, **Then** at end of day the plan auto-updates: 2 completed, 1 incomplete (moved to tomorrow), 1 unplanned (added)
2. **Given** the user consistently ignores a certain type of suggestion (e.g., "refactor" tasks), **When** the planner generates future plans, **Then** it deprioritizes that task type

---

### Edge Cases

- What happens when the user has no historical data for time estimation?
- How are very long task lists handled — should the planner limit to top 5?
- What happens when the user works outside of planned schedule (e.g., works late)?
- How are public holidays and days off handled?
- What happens when multiple projects have conflicting priorities?
- How are tasks that span multiple days handled?
- What happens when the user explicitly rejects all plan suggestions?

## Requirements

### Functional Requirements

- **FR-001**: Planner agent MUST analyze user context and suggest prioritized tasks
- **FR-002**: Task suggestions MUST include: title, description, rationale (why this task), priority, estimated duration, and related entities
- **FR-003**: Planner MUST provide goal CRUD: create, read, update, delete goals with title, target, period, and optional trigger keywords
- **FR-004**: Planner MUST match events to goals based on trigger keywords — events whose content/app/file mentions a keyword count toward that goal's progress
- **FR-005**: Planner MUST compute goal progress as a fraction (current/target) and expose it to the Now bar (spec 023) via IPC
- **FR-006**: Planner MUST flag goals below 50% of target at end of period for nudge generation by the agent host (spec 064)
- **FR-007**: Planner MUST suggest archiving goals with no activity for 7+ days
- **FR-008**: Planner MUST generate a daily plan at a configurable time (default 8 AM)
- **FR-009**: Daily plan MUST include: continued tasks from yesterday, recurring tasks, new suggestions, and priority ordering
- **FR-010**: Planner MUST estimate task duration based on historical user velocity for similar tasks
- **FR-011**: Time estimates MUST include: estimated duration, confidence level, and similar past tasks used for estimation
- **FR-012**: Planner MUST warn if daily schedule exceeds available time
- **FR-013**: Planner MUST generate project roadmap suggestions with milestones and tasks
- **FR-014**: Project roadmaps MUST be derived from project event analysis
- **FR-015**: Planner MUST track plan adherence and adapt future suggestions
- **FR-016**: Plans MUST auto-update at end of day: mark completed, move incomplete, add unplanned
- **FR-017**: Planner MUST learn from repeated task-type rejection and adjust suggestions
- **FR-018**: Planner MUST handle users with no historical data (fall back to default estimates)
- **FR-019**: Planner MUST be available as an MCP tool via the MCP server

### Key Entities

- **Goal**: A user-defined intention. Attributes: id, title, target (number), unit (minutes/sessions/events), period (daily/weekly/custom), triggerKeywords (array of strings for event matching), status (active/archived/deleted), createdAt, updatedAt.
- **GoalProgress**: Computed progress for a goal. Attributes: goalId, current (number matched), target, fraction (0-1), periodStart, periodEnd, status (on-track/falling-behind/missed), lastMatchedAt.
- **PlannedTask**: A task in a plan. Attributes: id, planId, title, description, rationale, priority, estimatedDuration, actualDuration, status (suggested/planned/in-progress/completed/deferred/skipped), source (suggestion/recurring/continued/manual), projectId, relatedEventIds, createdAt.
- **DailyPlan**: A plan for a day. Attributes: id, date, tasks (ordered), totalEstimatedDuration, totalAvailableTime, overcommitted (bool), generatedAt, adaptedAt, status (active/completed/archived).
- **ProjectRoadmap**: A suggested roadmap for a project. Attributes: id, projectId, milestones (array of {name, description, tasks, targetDate}), confidence, generatedAt.
- **UserVelocity**: Historical velocity data. Attributes: taskType (coding/testing/docs/review/research), averageDuration, sampleCount, confidence.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Daily plan generation completes in under 5 seconds
- **SC-002**: Task suggestions are relevant: 50%+ of suggested tasks are accepted or completed
- **SC-003**: Time estimation accuracy: estimates are within 30% of actual time, 70% of the time
- **SC-004**: Project roadmap generation completes in under 10 seconds
- **SC-005**: Plan adaptation updates within 1 minute of end-of-day trigger
- **SC-006**: Users who use daily plans report saving 10+ minutes per day on planning

## Assumptions

- Built as an OSAI agent running in the background process
- Uses session and project detection (specs 015-016) for context analysis
- Uses event classification (spec 013) for understanding task types
- Daily plans generated at configurable time (default 8 AM) via scheduling system (spec 031)
- Time estimation uses a simple k-NN algorithm over historical sessions
- Plans are stored locally in the storage layer
- Plan adaptation runs at end of day (configurable, default midnight)
- Project roadmaps require minimum 20 events in a project before generation
- Tasks are not synced to external task managers (out of scope for v1)
- Any LLM-based task suggestion or plan generation uses the provider layer (spec 062)
- Source code lives at `agents/planner/` in the monorepo