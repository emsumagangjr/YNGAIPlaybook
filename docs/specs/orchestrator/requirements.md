# Orchestrator: Requirements

Epic: #1 · Branch: `epic/1-orchestrator`

## Purpose

The Epic Workflow guide names a **dispatcher**: the one writer of issue
state, which checks Gate 1, hands slices to agents and moves labels as
the work progresses. This feature delivers that role as an
agent-runnable **orchestrator** skill, plus the **slice worker** agent
it dispatches to.

The orchestrator runs in the main agent session. Workers run as
subagents, one per slice, each in its own slice worktree. A worker's
final message is its report and returns to the orchestrator
automatically.

``` text
            Orchestrator (main session, the dispatcher)
                 │ plans · checks Gate 1 · dispatches · tracks
     ┌───────────┼───────────┐
     ▼           ▼           ▼
  Worker A    Worker B    Worker C     one per slice, own worktree
     │           │           │
     └─ report ──┴─ report ──┘         final message = completion report
```

Neither the orchestrator nor any worker passes a people-only gate: a
person promotes every issue (Gate 1) and a person merges every pull
request (Gate 2).

## Deliverables

``` text
skills/orchestrate/SKILL.md       the orchestrator: role, run log, the step sequence
skills/orchestrate/plan.md        step: planning (R3)
skills/orchestrate/dispatch.md    step: dispatch (R4)
skills/orchestrate/track.md       step: tracking (R5)
skills/orchestrate/report.md      the completion report format (R1)
agents/slice-worker.md            the worker (R2)
```

Each step lives in its own file, reached from `SKILL.md` only when that
step runs, so the entry file stays short and each step can change
without touching the others.

The orchestrator is user-invoked (`/orchestrate`): running an Epic is a
person's decision, so it carries no always-loaded description.

Installed into a project by copying them into the agent's config
folder (for Claude Code: `.claude/skills/` and `.claude/agents/`).

------------------------------------------------------------------------

## R1 Completion report

Slice: #2

1.  Every worker ends with one report in a single shared format:

    ``` text
    STATUS:        done | blocked | failed | needs-human
    SUMMARY:       what was delivered, in one or two sentences
    BRANCH:        slice branch name
    PR:            pull request URL, or "none"
    COMMITS:       short SHAs and subjects
    TESTS:         what ran and the result
    REVIEW RECORD: open decisions only, or "none"
    ISSUES:        new issues opened, or blockers and their cause
    ```

2.  The format is defined once, in `skills/orchestrate/report.md`. The
    worker and the orchestrator both reference it; neither restates it.
3.  Every field appears, in order, even when its value is "none".
4.  `needs-human` states its reason, so the orchestrator can hand the
    slice back without re-reading the work.

## R2 Slice worker

Slice: #3

1.  Works only in the worktree path and on the branch it is given.
    Checks `git status` and the current branch first and refuses on a
    mismatch.
2.  Runs the guide's chain inside `in-progress`: optional lead-in (a
    bug defaults to *diagnose*, a refactor to *design the seam*), then
    implement test-first, then code review last. Fixes what review finds
    that it can fix; puts only open decisions in the review record.
3.  Updates the spec on the Epic branch in the same change as the code
    it describes.
4.  Pushes the slice branch and opens a pull request into the Epic
    branch. Never merges. Never changes labels.
5.  Stops with `needs-human` on anything in *Never promoted to
    `ready-for-agent`* that surfaces during the work. Unsure means
    human.
6.  Follows the guide's *Agent Safety Rules* (section 20).
7.  Ends with the R1 report.

## R3 Planning

Slice: #4

1.  Reads the Epic and its spec and proposes slices, each titled for
    its outcome, with acceptance criteria and a link to the spec
    section it implements.
2.  Marks for `workflow:ready-for-human` any slice touching production
    schema, authentication or authorisation, a human-only step, or
    anything it is unsure about.
3.  Records dependencies between slices, so that independent slices
    can run in parallel.
4.  Shows the plan to the person. Only after approval does it create
    the slice issues, as sub-issues of the Epic, at
    `workflow:needs-triage`. It never sets `workflow:ready-for-agent`.

## R4 Dispatch

Slice: #5

1.  Dispatches only issues labelled `workflow:ready-for-agent`, and
    only after reading the issue timeline and confirming a human
    account applied that label (the guide's provenance check). Refuses
    and reports otherwise.
2.  Creates the slice worktree from the Epic branch, following the
    guide's naming, and records the Epic on the branch:

    ``` bash
    git --git-dir=.bare worktree add -b slice/<n>-<name> slice-<epic>-<name> <epic branch>
    git --git-dir=.bare config branch.slice/<n>-<name>.epicid <epic n>
    ```

3.  Links `.shared/` files into the worktree with `yngshared` when the
    project has a `.shared/` folder.
4.  Launches one slice worker per slice. Independent slices launch in
    parallel; a dependent slice waits for its inputs to merge into the
    Epic branch. Each prompt is self-contained: issue number and
    acceptance criteria, worktree path, branch, spec section.
5.  Sets `workflow:in-progress` when it hands the slice out.

## R5 Tracking

Slice: #6

1.  Acts on every report:

    | Report STATUS | Orchestrator action                                         |
    |---------------|-------------------------------------------------------------|
    | `done`        | Confirms the PR is open; sets `workflow:in-review`          |
    | `blocked` / `failed` | Re-dispatches once with the added context; on a second failure hands back to a person with the report |
    | `needs-human` | Sets `workflow:ready-for-human`; comments the reason        |

2.  After a person merges a slice PR into the Epic branch: closes the
    slice issue with a note naming the Epic branch, then removes the
    slice worktree and its local branch.
3.  Keeps a run log at `.orchestrator/run-log.md` in the Epic worktree,
    excluded from Git, so an interrupted run can resume where it
    stopped. `SKILL.md` defines the log's location and line format;
    `track.md` says what each report adds to it.
4.  Is the only writer of issue state during the work. Never merges.

## R6 Documentation

Slice: #7

1.  README lists the skills and agents and how to install them.
2.  `guides/epic-workflow.md` gains a section on running the dispatcher
    as an orchestrator, linked from *Who moves the labels*.
3.  CHANGELOG entry; `VERSION` and the guide header move to 1.1.0.
