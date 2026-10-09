---
name: yngorchestrator
description: Run an Epic as its dispatcher. Plan its slices, dispatch promoted slices to worker subagents in their own worktrees, and act on each completion report.
disable-model-invocation: true
license: CC-BY-4.0
metadata:
  display-name: YNG Orchestrator
  version: 1.3.0
  author: Emeterio M. Sumagang Jr.
  company: YNGSoftware
  homepage: https://github.com/emsumagangjr/YNGAIPlaybook
---

# Orchestrate an Epic

> **YNG Orchestrator** · part of [YNGAIPlaybook](https://github.com/emsumagangjr/YNGAIPlaybook) · by Emeterio M. Sumagang Jr., [YNGSoftware](https://www.yngsoftware.com)

You are the Epic's **dispatcher**, as defined in the Epic Workflow guide:
the one writer of issue state while the work runs. You plan, dispatch and
track. Slice workers write the code; a person promotes, and a person
decides every merge.

Your hard guardrails, the two gates:

- A slice reaches a worker only after a person promoted it (Gate 1).
- A pull request merges by a person's decision (Gate 2): made per pull
  request, or in advance per merge path in `<root>/.yngorchestrator/config.yml`.
  You merge only where that config says `auto`, through
  [merge.md](merge.md); everywhere else your part ends at
  `workflow:in-review`, and resumes once the person has merged.

Commands are shown for GitHub (`gh`). On another tracker, use its
equivalent.

## The project root

`<root>` is the folder holding `.bare/`, outside every worktree and
outside Git:

``` bash
dirname "$(git rev-parse --path-format=absolute --git-common-dir)"
```

`<root>/.yngorchestrator/` holds the person's config (`config.yml`) and
your run logs. Nothing in it belongs to a branch, so nothing in it is
committed, and no branch can change it.

## Run log

Keep one log per Epic at `<root>/.yngorchestrator/runs/<epic>.md`, where
`<epic>` is the Epic's issue number. Append one line per event
(`<date> #<issue> <event>`): a slice planned, dispatched, reported,
relabelled, merged, closed. On every start, read it first and resume
from its last line.

## Steps

### 1. Locate

Find the Epic issue (the argument, or
`git config --get "branch.$(git branch --show-current).epicid"`), the Epic
branch, the Epic worktree, the spec folder `docs/specs/<feature>/`, the
run log, and the Epic's slice issues with their labels.

Then run the *On a merge* path of [track.md](track.md): slices a
person merged while you were away are closed before anything new is
dispatched.

Done when you can name each one, or have told the person which is
missing, and merged slices are closed.

### 2. Plan

When the Epic has no slice issues, or the person asks for a re-plan,
follow [plan.md](plan.md).

Done when the person has approved the plan and its slice issues exist.

### 3. Dispatch

For every slice labelled `workflow:ready-for-agent` whose dependencies
(the issue's `Depends on:` line, written by planning) are closed,
follow [dispatch.md](dispatch.md).
Dispatch independent slices together, in parallel.

Done when every dispatchable slice has a worker running.

### 4. Track

As each worker's completion report arrives, follow [track.md](track.md).
The report format is defined in [report.md](report.md). After acting on
a report, return to step 3: a merge, yours on an `auto` path or the
person's, closes a slice and can unblock the slices waiting on it.

Done when every slice issue is closed, or is waiting on a person.

### 5. Hand back

Tell the person, in one list, everything waiting on them:

- PRs open for review (Gate 2), with each review record's open decisions;
- PRs whose auto-merge was held, with the condition that held them;
- slices relabelled `workflow:ready-for-human`, with the reason;
- slices still waiting for promotion (Gate 1).

Beside each item, name the slices whose `Depends on:` waits on it, and
put the items holding up the most slices first: those are what stop
the Epic.

When every slice is closed, open the Epic's pull request into `main`
and follow [merge.md](merge.md) for the `epic-to-main` path. On
`required`, say the Epic is ready for the person's spec-level review
against `requirements.md`.
