---
name: yngorchestrator
description: Run an Epic, a slice or a standalone issue as its dispatcher, each in its own agent instance and worktree, started from anywhere in the project; continue resumes a run without its number. Plan an Epic's slices, dispatch promoted issues to worker subagents in their own worktrees, and act on each completion report.
disable-model-invocation: true
license: CC-BY-4.0
metadata:
  display-name: YNG Orchestrator
  version: 1.16.0
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

- A slice reaches a worker only after a person promoted it (Gate 1):
  by applying `workflow:ready-for-agent`, or, where
  `<root>/.yngaiplaybook/yngorchestratorconfig.yml` says
  `auto-promote: yes`, by approving the Epic's plan, which is then the
  person's advance decision for the agent slices that plan creates.
  Plan approval never promotes a slice routed to a person, a
  standalone issue, or a slice created by hand; with `auto-promote: no`
  or absent, only a person's label promotes.
- A pull request merges by a person's decision (Gate 2): made per pull
  request, or in advance per merge path in
  `<root>/.yngaiplaybook/yngorchestratorconfig.yml`. You merge only
  where that config says `auto`, through
  [merge.md](merge.md); everywhere else your part ends at
  `workflow:in-review`, and resumes once the person has merged.

## The provider

Every call to the git provider is an **operation**, named in italics
(*read issue*, *set state*, *create pr*), and lives in one provider
file, `providers/<provider>.md` beside this file. Step 3 of
[locate.md](locate.md) reads `<provider>` and `<host>` from the config
at the start of every run: an absent `provider:` is `github`, an
absent `host:` the provider's cloud host. Load
[providers/README.md](providers/README.md), which defines each
operation, and that one provider file, never another (R7.2): the steps
name operations, and the provider file says how each runs on `<host>`.

## The project root

`<root>` is the folder holding `.bare/`, outside every worktree and
outside Git. Step 1 finds it, through [locate.md](locate.md), from a
session started at the root, in any worktree, or in any folder below
one.

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

## Its own instance

Every Epic, slice and standalone run has its own agent instance, in
the issue's own worktree (R46). A session started anywhere else hands
the run on: it finds or creates the worktree, opens a new instance
there, in a Herdr app space, a herdr workspace or a new terminal window, with
`/yngorchestrator <n>` already sent, logs `launched`, and ends
([launch.md](launch.md)). A session already in the issue's own
worktree is the dispatcher, right there. Slice workers stay
`slice-worker` subagents inside the dispatcher's instance.

Every command on the target still names it by absolute path:
`git -C <worktree>` or `git --git-dir=<root>/.bare`, files read from
`<worktree>/docs/specs/...`, and every operation on `<issues repo>` or
`<code repo>` (*Two repositories* below). Every `<... worktree>` in
these steps is an absolute path below `<root>`.

## Two repositories

A project may keep its issues in a separate repository, on the same
provider and host as its code (R11). Step 3 of [locate.md](locate.md)
resolves both repositories before the lock, and the run holds them to
its end:

| Name            | What it is                                        | Its operations |
|-----------------|---------------------------------------------------|----------------|
| `<code repo>`   | `origin`'s repository path                        | pull requests, their checks, merges; Git's fetching, branches and worktrees |
| `<issues repo>` | the config's `issues:` value, else `<code repo>`  | reading an issue, its parent and children, states, comments, closing, reopening, creating and linking slice issues, provenance |

Every operation names one of them; none is left to a tool's default.
Issue numbers, the run log's `#<issue>` and branch names
(`slice/<n>-<name>`) are the issues repo's. Wherever an issue is named
from the code repo's side (a dispatch prompt, a commit, a pull
request), it is named by full reference, the provider file's *Issue
reference* (`<issues repo>#<n>` on GitHub), so a link never lands on
the code repo's own `#<n>`. Without an `issues:` value the two are one
repository, and every operation targets it as before.

## Asking the person

When the run needs information only the person has, grill them
(R58): a gap in the spec, an acceptance criterion you cannot check,
signals that conflict, anything you would otherwise guess. Grilling
is built into this skill; it needs no other skill or plugin.

1. Ask **one question per message**, never two, and never a list of
   questions to answer together.
2. Give your **recommended answer** with it, and why, in a sentence.
   Where the answers are a few clear options, offer them, yours first.
3. Wait for the answer. Build the next question on it: follow up
   where the answer opens something new, and drop a question it
   already settled.
4. Look it up instead of asking when the code, the spec, the issue or
   the run log can tell you.
5. Stop when nothing open is left, or the person says to go on. Sum up
   what was decided in a few lines, and carry on with the step that
   asked.

A plain pick between things you found (which of these branches, which
of these runs) is one question, not a grilling. Approving the plan,
and the gates, are the person's decisions, not questions: grilling
never stands in for them.

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
planned, dispatched, reported, relabelled, merged, closed, a worktree
removed or its removal deferred ([track.md](track.md)), a run launched
into its own instance ([launch.md](launch.md)), and each interim
report a worker sends while it works (*Interim reports* below).

The `dispatched` line carries the instant, not its date alone, and so
does `re-dispatched`: a board's elapsed figure needs better than a date
to tell a slice dispatched minutes ago from one dispatched before
breakfast (yngboard R6.3). Every other event keeps the bare `<date>`;
an interim report's own instant is part of its event (*Interim
reports* below).

``` text
2026-11-25 #104 dispatched 2026-11-25T03:21:55Z
2026-11-25 #104 re-dispatched 2026-11-25T11:04:02Z
```

### The board

**Appending a line to `yngorchestratorruns/<log>.md` rewrites that
log's run board afterwards**: follow [board.md](board.md), which
gathers, ranks, builds the payload, renders it into the shipped
template, writes the board or boards this run owns — each named for
the issue it is about (*Which board this run writes* in board.md) —
and, under `run-board: open`, opens one once at the run's first write
(yngboard R3.2, yngboardcommand R6.1, R8.1).

The rule lives here and nowhere else. It is a property of appending a
line, not a step of its own, so no step added later can forget it and
the board cannot drift from the log: [plan.md](plan.md),
[dispatch.md](dispatch.md), [track.md](track.md), [merge.md](merge.md)
and [scoped.md](scoped.md) never restate it. The board write is not
itself an event and appends no line of its own (R3.4), and a board is
a rendering: a write that fails leaves the board on disk alone, names
the operation that failed, and stops nothing.

It covers this run's own `<log>`, and two runs never reach it:

- a run that **stops with a reason before its first logged event**
  writes no board, and one that has already written one leaves it as
  it is, true as of its own timestamp (R3.5);
- a run that **hands on to its own instance** ([launch.md](launch.md))
  writes none either: it holds no lock, it ends at the hand-off, and
  the instance it opens writes the board from the same reads — paying
  for them twice would buy the person nothing.

A line the *Sweep deferred removals* path of [track.md](track.md)
appends to **another** log is not this run's: that log's board waits
for a run on it, because the board would need provider reads about an
Epic this run is not running (R1.6).

### Interim reports

A worker sends **interim reports** while it works, and each one you
receive becomes one run-log line (yngboard R14). The worker writes no
line itself and sets no state: it appends to the **progress channel**
[dispatch.md](dispatch.md) opened for it, and you are its only reader.

**Drain every open channel each time a worker's message reaches you,
and before you append any line of your own.** You hold how many of
each channel's lines you have already logged; the rest are new:

``` bash
tail -n +$((logged + 1)) "$progress"
```

Append one line per new channel line, oldest first, keeping the
instant, the step and the one line as the worker wrote them:

``` text
2026-11-25 #104 progress 2026-11-25T03:40:12Z | 3. Lead-in | The refresh path already has a seam: the token store.
```

`<date>` is the day you logged it, as on every line. `progress` is the
interim report's event word and `reported` stays the completion
report's, so the log keeps news and hand-off apart (yngboard R14.4).
The lines you append here are not channel lines, so a drain never
drains itself, and each one rewrites the board by the rule above: an
interim report reaches the board the way everything else a run learns
does.

A channel line you cannot read — a field missing, a reference that is
not that slice's, an instant that does not name its zone — is logged
as it arrived and built into nothing:

``` text
2026-11-25 #104 progress unreadable <the line as it arrived, on one line>
```

It never fails the slice and never changes its state: the row falls
back to what you already know about it (yngboard R14.4). Invent no
field for it and ask the worker for nothing — news is not a hand-off,
and the completion report is still what you act on.

Delete a channel once you have acted on that slice's completion report
(*On a report* in [track.md](track.md)): drain it one last time, then
`rm -f` it. It is scratch, and the run log holds the history.

### The lock

One writer of issue state at a time: a run holds
`yngorchestratorruns/<log>.lock` while it writes
`yngorchestratorruns/<log>.md`. A slice run takes its Epic's lock, so
it never runs beside its Epic's run.

Take the lock as soon as [locate.md](locate.md) has told the issue's
kind (its step 4) and found the session in the issue's own worktree
(its step 5), before its step 6 can reopen the issue. A run that
launches never takes it: [launch.md](launch.md) only checks it, and
the instance it opens takes it (R48). Create the
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
`#39` or the issue's URL, or `/yngorchestrator continue`, which
resumes a run without its number; a bare `/yngorchestrator` is
`continue` (R50). Follow [locate.md](locate.md): it finds
`<root>`, reads the provider and host, resolves the code repo and the
issues repo, checks the issue
is in the issues repo, tells its kind, decides whether the run goes on
here or in its own instance, and handles a closed issue. A run here
takes the lock (*The lock* above) once the kind is known; a run that
launches hands on through [launch.md](launch.md) and ends there.

For a slice or a standalone issue, locate.md hands on to
[scoped.md](scoped.md), which runs that one issue to its hand-back;
the steps below are an Epic run's.

For an Epic, locate.md hands on through [worktree.md](worktree.md):
it finds or creates the Epic branch and the Epic worktree, and checks
the spec folder `<epic worktree>/docs/specs/<feature>/`. Then find the
run log and the Epic's slice issues with their labels (*list
children*).

Then run the *On a merge* path of [track.md](track.md): slices a
person merged while you were away are closed before anything new is
dispatched. Then *Sweep deferred removals* there: worktrees a slice or
standalone run could not remove from inside are removed now (R61.2).

Done when you can name each one, or have told the person which is
missing, merged slices are closed, and deferred removals are swept.

### 2. Plan

When the Epic has no slice issues, or the person asks for a re-plan,
follow [plan.md](plan.md).

Done when the person has approved the plan and its slice issues exist.
With `auto-promote: yes`, go straight on to step 3 in this run: the
approval promoted the agent slices.

### 3. Dispatch

For every slice labelled `workflow:ready-for-agent` whose dependencies
(the issue's `Depends on:` line, written by planning) are closed,
follow [dispatch.md](dispatch.md).
Dispatch independent slices together, in parallel.

Done when every dispatchable slice has a worker running.

### 4. Track

As each worker's completion report arrives, follow [track.md](track.md).
The report format is defined by *Completion report* in
[report.md](report.md). After acting on a report, return to step 3: a
merge, yours on an `auto` path or the person's, closes a slice and can
unblock the slices waiting on it.

Done when every slice issue is closed, or is waiting on a person.

### 5. Hand back

Tell the person, in one list, everything waiting on them:

- PRs open for review (Gate 2), with each review record's open decisions;
- PRs whose auto-merge was held, with the condition that held them;
- slices relabelled `workflow:ready-for-human`, with the reason;
- slices created `workflow:ready-for-human` by a plan under
  `auto-promote: yes`, with the reason;
- slices still waiting for promotion (Gate 1).

Beside each item, name the slices whose `Depends on:` waits on it, and
put the items holding up the most slices first: those are what stop
the Epic. A slice waiting on a person always comes ahead of the items
it holds up.

When every slice is closed, look for the Epic's pull request into
`main`: *list prs* for the head `^<epic branch>$`, keeping those based
on `main`. With none open or merged, *create pr* from `<epic branch>`
into `main`, titled with the Epic's title. Its body is the provider
file's *Closing reference* for the Epic (`Closes <issues repo>#<epic>`
on GitHub), so the merge into the default branch closes the Epic where
the provider can (R12.1).

Then follow [merge.md](merge.md) for the `epic-to-main` path. On
`required`, say the Epic is ready for the person's spec-level review
against `requirements.md`. When a person has already merged it, skip
to the `epic-to-main` close in step 3 of [merge.md](merge.md): the
Epic is closed there if the merge left it open (R12.2).

The list above stays first and stays whole, because it is what reaches
the person over Remote Control, where a `file://` path is useless
(yngboard R1.4). Add one line below it naming the run's board, which
every event of this run has rewritten (*The board* above):

``` text
Run board: <root>/.yngaiplaybook/yngboard-<log>.html — every slice, its state and what it needs. Type yngboard to open it.
```

Where no board has been written, leave that line out: the list above
is the hand-back either way.

Last, delete the run's lock (*The lock* above): the run has ended.

Done when the person holds the list, and the board's path where there
is a board, and the lock is gone.
