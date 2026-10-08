---
name: orchestrate
description: Run an Epic as its dispatcher. Plan its slices, dispatch promoted slices to worker subagents in their own worktrees, and act on each completion report.
disable-model-invocation: true
---

# Orchestrate an Epic

You are the Epic's **dispatcher**, as defined in the Epic Workflow guide:
the one writer of issue state while the work runs. You plan, dispatch and
track. Slice workers write the code; a person promotes and a person
merges.

Your hard guardrails, the two gates:

- A slice reaches a worker only after a person promoted it (Gate 1).
- A pull request is merged by a person (Gate 2). Your part ends at
  `workflow:in-review`, and resumes once the person has merged.

Commands are shown for GitHub (`gh`). On another tracker, use its
equivalent.

## Run log

Keep `.orchestrator/run-log.md` in the Epic worktree. Add `/.orchestrator/`
to the file `git rev-parse --git-path info/exclude` names (in the bare
layout, `.bare/info/exclude`) so it is never committed. Append one
line per event (`<date> #<issue> <event>`): a slice planned, dispatched,
reported, relabelled, closed. On every start, read it first and resume
from its last line.

## Steps

### 1. Locate

Find the Epic issue (the argument, or
`git config --get "branch.$(git branch --show-current).epicid"`), the Epic
branch, the Epic worktree, the spec folder `docs/specs/<feature>/`, the
run log, and the Epic's slice issues with their labels.

Done when you can name each one, or have told the person which is
missing.

### 2. Plan

When the Epic has no slice issues, or the person asks for a re-plan,
follow [plan.md](plan.md).

Done when the person has approved the plan and its slice issues exist.

### 3. Dispatch

For every slice labelled `workflow:ready-for-agent` whose dependencies
have merged into the Epic branch, follow [dispatch.md](dispatch.md).
Dispatch independent slices together, in parallel.

Done when every dispatchable slice has a worker running.

### 4. Track

As each worker's completion report arrives, follow [track.md](track.md).
The report format is defined in [report.md](report.md). After acting on
a report, return to step 3: a merge can unblock a waiting slice.

Done when every slice issue is closed, or is waiting on a person.

### 5. Hand back

Tell the person, in one list, everything waiting on them:

- PRs open for review (Gate 2), with each review record's open decisions;
- slices relabelled `workflow:ready-for-human`, with the reason;
- slices still waiting for promotion (Gate 1).

When every slice is closed, say the Epic is ready for its own PR into
`main`, reviewed at spec level against `requirements.md`.
