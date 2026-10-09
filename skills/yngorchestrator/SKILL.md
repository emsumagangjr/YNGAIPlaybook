---
name: yngorchestrator
description: Run an Epic, a slice or a standalone issue as its dispatcher, from anywhere in the project. Plan an Epic's slices, dispatch promoted issues to worker subagents in their own worktrees, and act on each completion report.
disable-model-invocation: true
license: CC-BY-4.0
metadata:
  display-name: YNG Orchestrator
  version: 1.4.0
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
  request, or in advance per merge path in
  `<root>/.yngaiplaybook/yngorchestratorconfig.yml`. You merge only
  where that config says `auto`, through
  [merge.md](merge.md); everywhere else your part ends at
  `workflow:in-review`, and resumes once the person has merged.

Commands are shown for GitHub (`gh`). On another tracker, use its
equivalent.

## The project root

`<root>` is the folder holding `.bare/`, outside every worktree and
outside Git. Step 1 finds it, through [locate.md](locate.md), from a
session started at the root, in any worktree, or in any folder below
one.

The session stays where it started. Every command on the target names
it by absolute path: `git -C <worktree>` or `git --git-dir=<root>/.bare`,
files read from `<worktree>/docs/specs/...`, and `gh` with
`-R <owner>/<repo>`. Every `<... worktree>` in these steps is an
absolute path below `<root>`, so a run behaves the same from wherever
it started.

`<root>/.yngaiplaybook/` holds the playbook's files for the project.
Yours are the person's config (`yngorchestratorconfig.yml`) and your
run logs and locks (`yngorchestratorruns/`). Nothing in it belongs to
a branch, so nothing in it is committed, and no branch can change it.
These are the only paths you read or write there.

An older root keeps them in `<root>/.yngorchestrator/` or
`<root>/.orchestrator/`. You never read those folders and never move
them: `yngorch` migrates them. Step 1 of [locate.md](locate.md) stops
a run on a root that has not been migrated, before anything is
touched.

## Run log

Logs live in `<root>/.yngaiplaybook/yngorchestratorruns/`. The log a
run writes, `<log>`, follows the issue's kind:

| Kind       | `<log>`                    |
|------------|----------------------------|
| Epic       | the Epic's number          |
| slice      | its Epic's (parent) number |
| standalone | the issue's own number     |

A slice run writes to its Epic's log, so a later Epic run resumes from
what the slice run did. Append one line per event to
`yngorchestratorruns/<log>.md` (`<date> #<issue> <event>`): a slice
planned, dispatched, reported, relabelled, merged, closed.

### The lock

One writer of issue state at a time: a run holds
`yngorchestratorruns/<log>.lock` while it writes
`yngorchestratorruns/<log>.md`. A slice run takes its Epic's lock, so
it never runs beside its Epic's run.

Take the lock as soon as [locate.md](locate.md) has told the issue's
kind (its step 4), before its step 5 can reopen the issue. Create the
file only if it is absent, holding the start time and the session's
folder:

``` bash
mkdir -p "<root>/.yngaiplaybook/yngorchestratorruns"
( set -o noclobber
  printf 'started: %s\nsession: %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(pwd -P)" \
    > "<root>/.yngaiplaybook/yngorchestratorruns/<log>.lock" )
```

When that fails because the file is present, another run holds it, or
one crashed. Stop: show the person the lock's path and contents, and
leave the file. Only the person deletes a lock, once they know no run
holds it; then they start the run again.

With the lock held, read `yngorchestratorruns/<log>.md`, if it
exists, and resume from its last line.

Delete the lock when the run ends, and only the lock this run created:
after step 5 (for a slice or standalone run, at the hand-back of
[scoped.md](scoped.md)), and on every stop after taking it (a stop
with a reason, or the person ending the run).

``` bash
rm -f "<root>/.yngaiplaybook/yngorchestratorruns/<log>.lock"
```

## Steps

### 1. Locate

The command is `/yngorchestrator <issue>`, where `<issue>` is `39`,
`#39` or the issue's URL. Follow [locate.md](locate.md): it finds
`<root>`, checks the issue is in `origin`'s repository, tells its kind
and handles a closed issue. Once it has told the kind, take the lock
(*The lock* above) before going on.

For a slice or a standalone issue, locate.md hands on to
[scoped.md](scoped.md), which runs that one issue to its hand-back;
the steps below are an Epic run's.

For an Epic, locate.md hands on through [worktree.md](worktree.md):
it finds or creates the Epic branch and the Epic worktree, and checks
the spec folder `<epic worktree>/docs/specs/<feature>/`. Then find the
run log and the Epic's slice issues with their labels.

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
(`gh pr create -R <owner>/<repo> --base main --head <epic branch>`)
and follow [merge.md](merge.md) for the `epic-to-main` path. On
`required`, say the Epic is ready for the person's spec-level review
against `requirements.md`.

Last, delete the run's lock (*The lock* above): the run has ended.

Done when the person holds the list and the lock is gone.
