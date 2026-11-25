# YNG Board: Requirements

Epic: #155 · Branch: `epic/155-yngboard`

## Purpose

1.15.0 shipped the hand-back page ([ynghandback](../ynghandback/requirements.md)):
one HTML file per Epic, written once at the hand-back, showing what
waits on a person. In use, the problem it solves turned out to be the
wrong one. The question asked in a workspace is not *what is waiting on
me now that the run has ended* but *where has everything got to*, asked
while the run is going — and answering it means typing `status` at the
agent.

This feature turns that page into the **run board**: the same file, the
same template split, the same guardrails, but written at **every**
run-log event instead of once, showing **every** slice with its state
and whether it needs attention, and opened by typing `yngboard`.

It stays run-only. Nothing watches the provider and nothing refreshes
between runs: a board is current as of the last event of the last run,
which is what its timestamp says. Between runs nothing moves, because a
run is the only thing that moves a slice.

``` text
   /yngorchestrator <n>
        │
        ├─ plan ─ dispatch ─ report ─ relabel ─ merge ─ close ─ hand back
        │    │       │         │         │        │       │        │
        │    └───────┴─────────┴─────────┴────────┴───────┴────────┘
        │                    every run-log line rewrites
        │                              │
        │                              ▼
        │          <root>/.yngaiplaybook/yngboard-<n>.html
        │                              │
        └─ opens it once, at the first write (run-board: open)
                                       │
                            yngboard ──┘  any time after
```

This spec **amends** ynghandback, requirement by requirement; each one
below names what it changes. Where it names nothing, it is new.
`docs/specs/ynghandback/` stays as the record of what 1.15.0 shipped.

## Deliverables

``` text
skills/yngorchestrator/board.md                 replaces handback.md: gather, render, write, open (R1, R3)
skills/yngorchestrator/web/template.html        one table, attention column, elapsed and latest report on render (R4, R5, R7, R14)
skills/yngorchestrator/web/index.html           deleted (R2)
skills/yngorchestrator/SKILL.md                 the Run log section carries the write rule; a line per interim report (R3, R14)
agents/slice-worker.md                          sends an interim report as each step finishes (R14)
skills/yngorchestrator/report.md                the interim report's fields, beside the completion report's (R14)
skills/yngorchestrator/locate.md                reads run-board, falling back to handback-page (R8)
scripts/yngboard.ps1, scripts/yngboard.sh       opens this worktree's board (R9)
scripts/yngorch.ps1, scripts/yngorch.sh         installs yngboard beside yngv; adds run-board (R8, R9)
templates/yngorchestratorconfig.yml             run-board, and handback-page marked the former name (R8)
INSTALL.md, README.md, guides/epic-workflow.md  section 25 subsection, the files, the command (R12)
VERSION, CHANGELOG.md, SKILL.md metadata        1.16.0 (R13)
```

------------------------------------------------------------------------

## R1 The run board

*Amends ynghandback R1.*

1.  A **run board** is one HTML file for one run log, self-contained,
    opening from `file://` with no server, no network and no installed
    runtime. It shows every slice of the Epic, each slice's state, and
    whether each needs a person.
2.  It is still a rendering, not a second source of truth, and still
    computes nothing of its own (ynghandback R1.2, R3.4 as narrowed by
    R7 below).
3.  It is no longer scoped to what waits on a person. A slice that
    needs nothing appears, with its state. The scope rule of
    ynghandback R16.1 — what is not waiting on a person is not on the
    page — is **withdrawn**: it was the hand-back page's guard, and it
    is what made the page unable to answer *where has everything got
    to*.
4.  Step 5 of `SKILL.md` keeps its prose list, unchanged and still
    first (ynghandback R1.3): it is what reaches a person over Remote
    Control, where a `file://` path is useless.
5.  The board is read-only and never acts (ynghandback R11, carried
    over whole).
6.  **Run-only.** No hook, no watcher, no scheduled refresh, no
    daemon. A board changes only while a run is executing. A label a
    person applies, a check that goes red and a pull request someone
    else merges reach the board at the next run that reads the
    provider, never before.

## R2 Names, files, and what is deleted

*Amends ynghandback R2; supersedes ynghandback R8.*

1.  One board per run log, named by the log:

    | File                 | What it is                                |
    |----------------------|-------------------------------------------|
    | `yngboard-<n>.html`  | one run log's board, in `<root>/.yngaiplaybook/` |

    `<n>` is the run log's name: the Epic's number for an Epic run and
    for any of its slices, the issue's own number for a standalone
    (ynghandback R2.1, R2.2 carried over).
2.  **The project index is deleted**: `skills/yngorchestrator/web/index.html`,
    the `ynghandback.html` it wrote, ynghandback R8 and the per-row
    staleness rules it needed. It answered a question this project does
    not ask, and every run paid to write it.
3.  A board write **deletes the stale files it replaces**, if they are
    there: `<root>/.yngaiplaybook/ynghandback.html` and
    `ynghandback-<n>.html` for its own `<n>`. A file nothing updates is
    worse than one that is either current or absent — the reasoning that
    deleted the index applies to the page it indexed.
4.  A board is overwritten whole. The run log is the history (ynghandback
    R2.3).
5.  `yngboard-<n>.html` is the only path this feature adds under
    `.yngaiplaybook/`.

## R3 When a board is written

*Amends ynghandback R14.*

1.  **Writing and opening are separate acts.** ynghandback R14
    conflated them, and only opening was ever the problem its R14.2
    named ("an Epic of eight slices would open eight browser
    windows"). Writing a board is a local file write: it shows nothing
    and interrupts nothing.
2.  A board is rewritten **at every run-log event**. The rule is stated
    once, in `SKILL.md`'s *Run log* section, as a property of appending
    a line: whatever appends a line to
    `yngorchestratorruns/<log>.md` rewrites the board afterwards. It is
    not restated in `plan.md`, `dispatch.md`, `track.md`, `merge.md` or
    `scoped.md`, so no step added later can forget it, and the board
    cannot drift from the log.
3.  The browser opens **at most once per run**, at the run's first
    board write, and only under `run-board: open` (R8).
4.  The board write is **not itself a run-log event**: it appends no
    line. A rule that fires on every line must not write a line, and a
    derived file is not a change to issue state. ynghandback R14.5's
    `handback page written` line is withdrawn.
5.  A run that stops with a reason before its first logged event writes
    no board. A run that has already written one leaves it as it is:
    it is true as of its own timestamp.

## R4 The one table

*Supersedes ynghandback R5 and R6.*

1.  The board's body is **one table**, one row per slice, with the
    Epic's own row for the `epic-to-main` pull request first:

    | Column        | What it holds                                        |
    |---------------|------------------------------------------------------|
    | **Slice**     | number and title, linked to the issue                |
    | **State**     | the one `workflow:*` label                           |
    | **PR**        | number, linked, with its checks and mergeable        |
    | **Attention** | what it needs from a person, or nothing (R4.3)       |
    | **Blocks**    | the slices whose `Depends on:` waits on this one     |

2.  The separate ranked waiting list is gone. Its ranking survives as
    the table's **sort order**: rows needing attention first, in step
    5's order — the rows holding up the most slices first, and a slice
    waiting on a person ahead of the rows it holds up — then the rest
    by number.
3.  `Attention` takes the six values ynghandback R5.2 already shipped,
    plus `none`:

    | Value      | What the person must do                                   |
    |------------|-----------------------------------------------------------|
    | `merge`    | review and merge an open pull request (Gate 2)            |
    | `held`     | an `auto` merge was held; `why` names the condition        |
    | `human`    | the slice is `workflow:ready-for-human`; `why` the reason  |
    | `promote`  | label the slice `workflow:ready-for-agent` (Gate 1)        |
    | `decision` | answer an open decision in the review record              |
    | `conflict` | the label and the last report disagree (ynghandback R7)    |
    | `none`     | nothing; the row is there to say where the slice is        |

    No new vocabulary is invented: each of the six already attaches to
    exactly one slice, through its issue or its pull request.
4.  Every row carries `why` where its attention value has one, and the
    provider address where the person acts (ynghandback R5.4).
5.  A table in which no row needs attention renders as the table, with
    one line above it saying nothing needs a person. It is not hidden:
    *where has everything got to* is the question it answers.
6.  The dependency edges and the open review decisions keep their place
    (ynghandback R6.1) — the edges as the **Blocks** column, the
    decisions as the `decision` value with its `why`. The run log and
    the worktrees stay in the collapsed *run detail* section
    (ynghandback R6.2), and the spec folder stays a link (R6.3).

## R5 A slice in flight

1.  Between `dispatch.md` step 3's *set state* `workflow:in-progress`
    and the worker's completion report, the dispatcher knows only what
    the worker's **interim reports** tell it (R14). Until the first one
    arrives it knows **nothing else**, and the completion report stays
    the worker's whole hand-off either way.
2.  A row for a slice dispatched with no interim report yet therefore
    shows its **dispatch instant** and the words *nothing reported
    yet*, and nothing more. Once one has arrived, the row shows it
    (R14.5).
3.  No progress bar, no percentage, no phase, no spinner, no guess. A
    board that implies progress it cannot see is worse than one that
    says it cannot see any.
4.  The elapsed figure is what makes the row useful: a slice silent for
    hours is visibly stuck, which is how a hung worker is found. It is
    derived on render (R7).
5.  Making workers report progress is a change to
    `agents/slice-worker.md` and the report format. It was refused as
    out of this feature and has been **taken back into it**: `R14`
    states what the worker sends and what the board does with it.

## R6 The payload

*Amends ynghandback R4.*

1.  **Schema version 2.** `waiting[]` leaves and each slice gains its
    attention, so by ynghandback R4.6 — `schema` rises when a field
    changes meaning or leaves — this is a rise. Unlike the arrivals of
    R4.7 and R4.9, 1.15.0 has shipped a payload in the field, so a
    reader can hold a page carrying `waiting[]`.

    ``` json
    { "schema": 2, "generated": "<UTC>", "live": true,
      "mergePath": "slice-to-epic",
      "issue":  { "number": 155, "title": "...", "url": "...",
                  "branch": "epic/155-..." },
      "epic":   { "number": 155, "title": "...", "url": "...",
                  "spec": "../<worktree>/docs/specs/<feature>/" },
      "slices": [ { "number": 104, "title": "...", "url": "...",
                    "label": "workflow:in-progress",
                    "attention": "none",
                    "why": null,
                    "actionUrl": null,
                    "dispatchedAt": "<UTC>",
                    "report": { "outcome": "done", "at": "<date>",
                                "summary": "..." },
                    "pr": { "number": 131, "url": "...", "state": "OPEN",
                            "checks": "passed", "mergeable": true },
                    "dependsOn": [103], "blocks": [105, 106],
                    "decisions": ["..."] } ],
      "runlog": ["..."], "worktrees": [ { "path": "...", "deferred": false } ] }
    ```

2.  Each slice carries `attention` (R4.3's seven values), `why` (null
    where the value has no reason), `actionUrl` (the provider address
    for that attention, null for `none`), `blocks` (what waits on it,
    `[]` when nothing does) and `dispatchedAt` (the UTC instant of its
    `dispatched` run-log line, null when it has not been dispatched).
3.  `dispatchedAt` is an **instant**, not the log line's date:
    ynghandback R4.4 made `report.at` a date because a run-log line
    carries nothing finer, and R5.4's elapsed figure needs better than
    a date. So the `dispatched` line gains the time — a change to the
    run-log format in `SKILL.md` — or, where an older log has only a
    date, `dispatchedAt` is null and the row says *dispatched, time
    unknown*.
4.  Everything else keeps the meaning ynghandback R4 gave it:
    `mergePath` (R4.7), `issue` and the absence of `epic.branch`
    (R4.9), `epic.spec` as a path relative to `.yngaiplaybook/`
    (R4.8), `report.outcome` rather than `status` (R4.4), `generated`
    as a UTC instant (R4.3).
5.  The rule of ynghandback R4.4 stands: `label`, `report.outcome` and
    `pr.checks` are three different things and the payload keeps them
    apart.
6.  A template reading a `schema` it does not know renders the table
    and a line saying the board was written by a newer orchestrator
    (ynghandback R4.6, with the table in place of the waiting list).

## R7 What the template may compute

*Amends ynghandback R3.4.*

1.  ynghandback R3.4 — "the template never computes anything the run
    computes" — was written to keep ranking out of JavaScript. Read
    literally it also forbids rendering an elapsed figure from a baked
    instant, which is arithmetic, not judgement.
2.  Narrowed: **the template may not make a judgement the run makes; it
    may do arithmetic on a value the run supplied.** Ranking, the
    attention value, the merge path, the label/report conflict and
    every other decision stay with the run (ynghandback R3.4's list).
3.  So the elapsed figure on an in-flight row (R5.4) is derived on
    render from `dispatchedAt`, and `generated` may likewise be shown
    as an age beside its absolute instant. The absolute instant is
    always shown: an age alone cannot say when the data was true.
4.  The distinction to hold: the template may **present** a value
    differently; it may never **decide** one.

## R8 The config setting `run-board`

*Amends ynghandback R12.*

1.  The setting is `run-board`:

    | Value   | What a run does                                        |
    |---------|--------------------------------------------------------|
    | `write` | writes the board at every event, opens nothing (default) |
    | `open`  | writes the same, and opens the browser once, at the run's first write |
    | `no`    | writes no board                                        |

2.  **The default is `write`**, where ynghandback R12.2's was `open`.
    With open-at-first-write, `open` would raise a browser window near
    the start of every run, including a run that does nothing; the
    workflow this feature serves is a tab left open and reloaded, or
    `yngboard` (R9). An absent key, an empty value or any value other
    than `open` or `no` means `write`, and never stops a run.
3.  **`handback-page` is a deprecated alias.** `locate.md` step 3 reads
    `run-board:`; when that key is absent it reads `handback-page:` and
    uses its value, so a config nobody has touched keeps behaving as it
    does today, including a deliberate `write` or `no`. When both are
    present, `run-board` wins. The orchestrator never rewrites either
    key. The fall-back turns on the **key**, not on its value: a
    `run-board:` key with nothing after it is the setting's own default
    (R8.2), not a reason to read the former name. Whichever name the
    value comes from, R8.1's table reads it, so a `handback-page` value
    other than `open` or `no` is `write` where 1.15.0 read it as `open`.
4.  `yngorch` adds `run-board` at its default only when **neither** key
    is present as an active key, and never changes a value of either. A
    run that skips it says so, as a note. The template's `handback-page`
    block gains one line saying it is the former name of `run-board` and
    is still honoured, and its key is commented out, as `agent`'s is:
    the block stays to be read, and a file written from the template
    carries one live key for the setting, `run-board`. The
    cross-reference in the template's header (its "See handback-page
    below") names `run-board`.
5.  It stays beside `launcher` and `remote-control`: what a run may do
    on the person's own machine (ynghandback R12.5).

## R9 The `yngboard` command

*Amends ynghandback R13.*

1.  `yngboard`, run with no argument, opens this worktree's board:

    | Where it runs                        | What it opens                                  |
    |--------------------------------------|------------------------------------------------|
    | a worktree whose branch names an issue | that log's board (`epic/<n>-`, `slice/<n>-` its Epic's, `fix/<n>-`) |
    | the project root, or `main`          | the most recently written `yngboard-*.html`    |
    | no board written for that log        | one line saying so, naming `/yngorchestrator <n>` |

    Where there is no `<n>` to name — the root, `main` — that line names
    `/yngorchestrator <issue>` instead. A branch that names an issue takes
    the first row or the third, **never the second**: another log's board
    is not this worktree's, and a board of the wrong Epic is worse than no
    board.

2.  It finds `<root>` as step 1 of `locate.md` does
    (`git rev-parse --path-format=absolute --git-common-dir`, else a
    `.bare/` beside it) and takes `<n>` from the branch as `locate.md`'s
    `continue` does. A branch that is none of `epic/<n>-`, `slice/<n>-`
    and `fix/<n>-` leaves `<n>` empty — `main`, a detached HEAD, a name
    carrying no number — and an empty `<n>` is the table's second row,
    as the root is.
3.  **It opens a file and nothing else**: no provider call, no gather,
    no ranking, no regeneration, no write. ynghandback R13.2 and R13.3
    refused a command that *regenerates* a board, because the provider
    reads would then exist a second time in PowerShell and shell and
    double every future provider change. Opening a file duplicates
    nothing, so that reasoning does not reach this command — and
    R13.2's blanket "no new command" is withdrawn with it. `yngorch`
    still gains no positional verb: `yngboard` is its own script.
4.  It is `scripts/yngboard.ps1` and `scripts/yngboard.sh`, installed
    per user beside `yngv`, in the `yngorch` step that already copies
    it (step 7, honouring `--bin-dir`; `--skip-viewer` skips both).
5.  A board it opens is as old as its own timestamp, which the board
    states (R7.3). `yngboard` never implies otherwise, and a board too
    old to trust is refreshed by starting a run (ynghandback R13.4).
6.  A slice's board is its Epic's, and R9.3 forbids asking the provider
    which Epic that is. It reads the run logs instead: a slice run
    writes to its Epic's log (`SKILL.md`, *Run log*), so the log holding
    a slice's own events **is** its Epic's. `<log>` is therefore the
    first `yngorchestratorruns/<m>.md` holding a line whose issue field
    is `#<n>`, matched whole, so `#1599` is never read as `#159` and a
    pull request number later in the line is never read as an issue. A
    slice with no such line in any log has no board, which is the third
    row of R9.1's table.
7.  It **hands the file to `yngv`**: beside itself, where R9.4 installs
    the two together, else on PATH. That is the viewer the run itself
    opens a board with (`board.md`), so a board opens the same way
    whoever opened it, and the platform's opener stays at one
    implementation per shell instead of two. `yngboard` therefore
    reads no browser environment variable of its own:
    `YNGV_HTML_BROWSER` keeps one reader and one matching rule, in
    `yngv`, where ynghandback R13.7 states it and
    [#148](https://github.com/emsumagangjr/YNGAIPlaybook/issues/148)
    fixed it — a second reader is how that defect would come back. With
    no `yngv` to be found, it says so and names the board's path, as
    `board.md` does when the viewer is missing.
8.  It **takes no argument**, `-h` / `--help` (`-Help` in PowerShell)
    aside, which prints the script's own header. Anything else is
    refused with the usage, before anything is read. A board handed to
    `yngv` exits 0; no board for this worktree's log, no project around
    this folder, and no `yngv` to open it with each print their one line
    on standard error and exit 1; an argument exits 2.

## R10 Carried over unchanged

These hold as ynghandback states them, and this feature changes nothing
in them:

| ynghandback | What it holds                                                   |
|-------------|------------------------------------------------------------------|
| R3.1–R3.3, R3.5–R3.6 | the shipped template; the run writes only the payload, inlined |
| R7          | the label wins over a report; the disagreement is surfaced       |
| R9          | a standalone issue on the same template, `epic: null`, `fix-to-main` |
| R10         | live data; a failed operation writes nothing and leaves the file |
| R11         | the board never acts: no control that writes, no request at all  |
| R15.1, R15.2, R15.4, R15.5 | `file://`, theme-aware, no bare "status", every number a link |

R15.3 is amended only in that the **table** is the first thing on the
page at every width, in place of the waiting list.

## R11 Vocabulary

1.  **Run board** is the term, in the skill, the guide, the config and
    the command. The page is a board of a run: every slice, where it
    is, what it needs.
2.  **Hand-back page** is retired as a name for this file, and stays
    only in `docs/specs/ynghandback/` and the `[1.15.0]` CHANGELOG
    entry, as the name of what that version shipped.
3.  **The bare word "status" stays banned** as a label or column
    heading, for the reason ynghandback R16.3 gave and that still
    holds: it means an issue's `workflow:*` label, a report's
    `STATUS`, a run-log event and a pull request's checks. The column
    is **State**. The feature is not called `yngstatus` for the same
    reason, even though *typing status* is the problem it solves.
4.  **Attention** replaces *waiting* as the term for what a slice needs
    from a person. They named the same thing; one word now does it, as
    a row's value rather than a list's membership.
5.  No root `GLOSSARY.md` (ynghandback R16.4). These definitions live
    here, and "run board" is added to the "Words used below" block of
    `templates/yngorchestratorconfig.yml`, replacing "hand-back page".
6.  `docs/specs/ynghandback/` is **not renamed**. Renaming it would
    falsify the `[1.15.0]` CHANGELOG entry and the nine closed slice
    issues that cite its requirements.

## R12 Documentation

1.  `guides/epic-workflow.md`: the section 25 subsection is rewritten
    for the run board — written at every event, one table, run-only,
    and `yngboard`. Still a subsection of 25, for the reason
    ynghandback R17.1 gave.
2.  `README.md`: `yngboard-<n>.html` in the `.yngaiplaybook/` tree,
    `yngboard` in the scripts list beside `yngv`, and
    `ynghandback.html` removed from both.
3.  `INSTALL.md`: `run-board` with its three values, `handback-page`
    named as the former name, and `yngboard` as the way to open a
    board.
4.  `templates/yngaiplaybookreadme.md`: a line for `run-board` in
    place of `handback-page`.
5.  Every place that says what a run leaves the person says the board
    is an addition to step 5's list, never a replacement (ynghandback
    R17.5), and says the board is run-only (R1.6).

## R13 Version

1.  `VERSION` and `SKILL.md`'s `metadata.version` to **1.16.0**, not
    2.0.0: the alias of R8.3 keeps every existing config working, and
    the renamed step file and the deleted `web/index.html` are internal
    to the skill.
2.  A `## [1.16.0]` entry in `CHANGELOG.md` with explicit **Changed**
    and **Removed** headings: the page renamed and rewritten at every
    event, the default now `write`, the key renamed with its alias, the
    `yngboard` command added, the project index removed.
3.  `decisions.md` beside this file carries the options refused.

## R14 The worker reports while it works

1.  The worker sends an **interim report** while it works: one as it
    finishes each step of `agents/slice-worker.md`, and one when it
    stops early. It never replaces the completion report, which stays
    the worker's whole hand-off and the only thing the orchestrator
    acts on (`report.md`). An interim report is news, not a hand-off.
2.  An interim report carries four things and no more: the issue's
    full reference, the **step** just finished (its number and name,
    as `agents/slice-worker.md` writes it), **one line** of what that
    step did or found, and the **UTC instant**. No estimate, no
    percentage, no count of what is left, no time to completion: the
    worker reports what it has done, never a fraction of what remains.
3.  The worker **sends; it writes nothing**. It appends no run-log line
    and sets no issue state: both stay the orchestrator's, as the
    worker's guardrails already say. What carries an interim report
    back to the dispatcher is for the slice that builds this to settle,
    under one constraint: it must reach the dispatcher *while the
    worker is still working*, or it tells the board nothing the
    completion report would not have told it first.
4.  The dispatcher appends **one run-log line per interim report** it
    receives, in the log's own form (`<date> #<issue> <event>`), under
    its own event word, `progress`; `reported` stays the completion
    report's, and the log keeps the two apart as R6.5 keeps the
    payload's. By R3.2 that line rewrites the board, so an interim
    report reaches it the way everything else a run learns does, and
    the run log, not the board, holds their history.
5.  An in-flight row renders the **latest** interim report: its step,
    its one line, its instant, and the elapsed figure since it (R7.3).
    Earlier ones are not rendered; the run log holds them. The
    payload's slice gains `progress` — `{ "at": "<UTC>", "step": "...",
    "note": "..." }` — null until the first interim report arrives. It
    is an arrival, not a field changing meaning or leaving, so `schema`
    stays at **2** (R6.1, ynghandback R4.6).
6.  **R5.3 holds for everything the worker has not reported.** No
    progress bar, no percentage, no phase, no spinner, and no guess at
    where the worker has got to between two interim reports. The board
    shows the last thing the worker actually said and how long ago it
    said it, and nothing in between: a row whose latest interim report
    is hours old reads as stuck, which is what R5.4 is for.
