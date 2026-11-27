# YNG Board Command: Requirements

Epic: #177 · Branch: `epic/177-yngboardcommand`

## Purpose

1.16.0 shipped the run board, and one way to see it: `yngboard`, in a
terminal. By [yngboard](../yngboard/requirements.md) R9.3 that command
may never touch the provider, so it can only open whatever file is
already on disk — it can never refresh one. Inside Claude Code there is
no way to call a board up at all.

This feature adds **`/yngorchestrator board`**, which gathers a board
fresh and opens it; gives a **slice its own board** in its own
worktree; and **coalesces** board writes, so draining four interim
reports costs one write instead of four.

The command is nearly free. `board.md` is already self-contained — it
gathers, ranks, builds the payload, renders, writes and opens — and the
agent already loads `providers/<provider>.md`. So `board` is
`locate.md` steps 1 to 4 and then `board.md`: no new gather, no new
ranking, and none of the duplication yngboard R13 refused, which was
always about reimplementing provider reads in PowerShell and shell, not
about the agent doing what it already does.

``` text
   yngboard                     /yngorchestrator board [<n>]
   (a terminal)                 (the agent)
       │                             │
       │ opens the file              │ locate 1-4, then board.md
       │ as it stands                │ gather · rank · payload · render · write · open
       ▼                             ▼
   <root>/.yngaiplaybook/yngboard-<issue>.html
       ▲                             ▲
       │ one per issue               │ an Epic's, a slice's, a standalone's
```

This spec **amends** yngboard; each requirement below names what it
changes. Where it names nothing, it is new.

## Deliverables

``` text
skills/yngorchestrator/locate.md        board as an argument; steps 1-4 then board.md (R1, R2)
skills/yngorchestrator/SKILL.md         the Run log section coalesces; the command in Steps (R9)
skills/yngorchestrator/board.md         a slice board; naming per issue; the lock check (R3, R5, R6, R7)
skills/yngorchestrator/scoped.md        a slice run writes both boards (R8)
skills/yngorchestrator/web/template.html  a slice board's interim reports in full (R7)
scripts/yngboard.ps1, scripts/yngboard.sh  branch maps to an issue; names the command (R12)
INSTALL.md, README.md, guides/epic-workflow.md  the command, the slice board (R14)
VERSION, CHANGELOG.md, SKILL.md metadata  1.17.0 (R15)
```

------------------------------------------------------------------------

## R1 The `board` argument

1.  `/yngorchestrator board` and `/yngorchestrator board <n>` gather a
    board fresh, write it and open it. `<n>` takes the forms
    `locate.md` step 2 already reads: `39`, `#39` or an issue URL.
2.  `board` is a **bare-word argument**, read in `locate.md` step 2
    beside `continue`, which is the precedent: a word that is not a
    number and not a URL. No second skill is added, and `yngorch` gains
    no positional verb.
3.  The run is `locate.md` steps 1 to 4, then [board.md](board.md),
    then it ends. Steps 5, 6 and 7 of locate.md do not run, and no
    step of `SKILL.md` does.
4.  It opens the board however `board.md` step 6 opens one, whatever
    `<run-board>` says (R10).

## R2 What the command never does

Each of these is a way the command could do harm, and each is
forbidden outright:

1.  **It never launches an instance.** `locate.md` step 5 sends a run
    started outside the issue's worktree into its own instance; `board`
    short-circuits before that and runs where it was typed. Opening a
    Herdr space to look at a board would be absurd.
2.  **It never takes the lock.** It writes no issue state, so there is
    nothing to serialise.
3.  **It appends no run-log line.** A board write is not an event
    (yngboard R3.4), and a `board` line would itself fire the write
    rule — a command that logs a line that rewrites the board that
    logged the line.
4.  **It never reads, drains or deletes a progress channel.**
    `dispatch.md` opens a channel for the dispatcher, which is *its
    only reader*; a second reader would race the `logged` count and
    lose interim reports from the run log permanently. A board this
    command writes during a live run may therefore lag the
    dispatcher's by one drain, and that is the correct trade: a board
    is a rendering, and corrupting the log to freshen one is not a
    trade worth making.
5.  **It never creates a branch or a worktree.** It does not reach
    [worktree.md](worktree.md).
6.  **It never changes an issue.** It does not run `locate.md` step 6,
    so a closed issue is never offered a reopen (R4.4).

## R3 When a run holds the lock

1.  Before writing, the command reads
    `yngorchestratorruns/<log>.lock` for the board's own log.
2.  **Lock present**: write nothing. Open the board on disk, and say in
    one line that a run is working on this log and the board is as
    fresh as that run's last write.
3.  **Lock absent**: gather, write and open as `board.md` does.
4.  One writer stays one writer. A running dispatcher rewrites that
    board at every batch of events (R9); a second writer underneath it
    would serve no one, and the running board is seconds old.
5.  A lock belongs to a log, so a slice board whose Epic's log is
    locked is still written: the lock names the Epic's log, and the
    slice's board is its own file. Only the Epic's board defers.

## R4 Which board the command opens

*Amends yngboard R9.1 for the command's own form.*

1.  With no `<n>`, the worktree holding the session decides, by its
    branch:

    | Branch            | The board            |
    |-------------------|----------------------|
    | `epic/<n>-`       | the Epic's, `<n>`    |
    | `slice/<n>-`      | **that slice's**, `<n>` (R5) |
    | `fix/<n>-`        | the standalone's, `<n>` |
    | `main`, or the root | `<n>` is required  |

2.  With `<n>`, that issue's board, whatever worktree the session is
    in. The kind comes from `locate.md` step 4 as it always does.
3.  The command names, in one line, which board it opened and which
    issue it is about: from a slice worktree a person could otherwise
    not tell a slice board from its Epic's.
4.  A **closed** issue's board renders as a record. #135 and #155 are
    closed and both have boards worth reading; refusing them would make
    the command useless for everything already delivered.

## R5 A slice has its own board

*Withdraws yngboard R2.2.*

1.  A slice board is a board about one slice, in that slice's own
    worktree's name: `yngboard-<slice>.html` (R6).
2.  yngboard R2.2 — "a slice run writes its Epic's board and never a
    board of its own" — is withdrawn. It followed from boards being
    named by run log, which R6 changes.
3.  It is redundant beside the Epic's board, and deliberately so: a
    person working one slice has the Epic's other eight rows in the
    way, and the thing they want — that slice's interim reports in full
    — is what an Epic's board can only summarise.
4.  It is **not** a second kind of page. The shipped template renders
    it with the slice as `issue` and `slices: []`, exactly as a
    standalone's board is already rendered (yngboard R10, ynghandback
    R9). What it adds it adds to that one page, by the board's own
    issue rather than by its kind, so a standalone's board shows its
    own interim reports the same way (R7.2): one page behaving the
    same everywhere, not a second one.

## R6 A board is named for its issue

*Amends yngboard R2.1.*

1.  Every board is `<root>/.yngaiplaybook/yngboard-<issue>.html`, where
    `<issue>` is the issue the board is **about**: the Epic for an
    Epic's board, the slice for a slice's, the issue itself for a
    standalone's.
2.  yngboard R2.1 named it for `<log>`. A slice's log is its Epic's, so
    `<log>` can no longer tell an Epic's board from its slice's.
3.  Nothing an existing install holds changes name: an Epic's `<log>`
    and its own number are the same, and so are a standalone's.
4.  Issue numbers are unique in the issues repo, so no two boards
    collide.
5.  The stale-file deletion of yngboard R2.3 keeps its form, for the
    board's own issue: `ynghandback.html` and
    `ynghandback-<issue>.html`.

## R7 What a slice board shows

1.  The slice's own row, opened out: its `workflow:*` state, its pull
    request with number, checks and mergeable, its `dependsOn` and
    `blocks`, its `attention` and `why`, and its open review decisions
    — the same fields the Epic's board carries for it (yngboard R4.1).
    The slice is the payload's `issue`, so `issue` carries every field
    a slice row carries: `dispatchedAt`, `report`, `progress`,
    `dependsOn` and `decisions` beside the fields a board's own issue
    already had (yngboard R6.2). Its `blocks` is that slice's own, not
    the `[]` an Epic's and a standalone's first row takes: what it
    holds up is worth knowing in the worktree where it is worked.
2.  **Its interim reports in full**, newest first, each with the instant
    and the step the worker wrote (yngboard R14). This is the reason a
    slice board exists: an Epic's board shows the latest, a slice's
    shows the sequence. The payload gains **`interim`**: every readable
    interim report for the board's **own issue**, newest first, each
    `{ "at": ..., "step": ..., "note": ... }`, and `[]` on an Epic's
    board, whose rows each carry their own latest. Every attempt is in
    it, the dispatches that divide them being in `runlog` beside it.
    `progress` keeps its meaning — the latest interim report of this
    attempt (yngboard R14.5) — so an Epic board's rows are unchanged.
    A line logged `progress unreadable` is **no interim report**: it
    builds nothing into `interim` and stays in `runlog`, where the
    person can see what arrived (yngboard R14.4).
3.  One link up to the Epic's board, and the Epic named: `epic.board`,
    the bare file name `yngboard-<epic>.html`, every board sitting in
    `.yngaiplaybook/` (R6.1). It is written on a slice board alone; an
    Epic's board is the board above, and a standalone has no Epic, so
    both write `null` and the page shows no link rather than one to
    itself.
4.  No slice table: `slices` is `[]`, and the section hides as it does
    for a standalone (ynghandback R9.2). `epic` is the Epic — its
    `number`, `title`, `url` and `spec`, with `board` beside them.
5.  A slice board carries the same timestamp rules as any other
    (yngboard R5.4): every instant names its zone, and the elapsed
    figure is derived on render. The template renders `interim` as a
    list in the order the run gave it, each instant with its figure
    beside it and never instead of it (yngboard R7.3); the section is
    absent where `interim` is `[]`.
6.  **`runlog` is the Epic's log, filtered** to the lines naming
    `#<slice>`: a slice's log is its Epic's, and the other eight
    slices' lines are the noise this board exists to clear. The
    payload gains **`runlogNote`**, the one line that says the log is
    the Epic's and filtered, shown above the log; it is `null` on an
    Epic's board and a standalone's, which show their own log whole.
7.  **`schema` becomes `3`.** `runlog` changes meaning on a slice
    board, and a field changing meaning is what raises the schema
    (ynghandback R4.6); `interim`, `runlogNote` and `epic.board`
    arrive with it. The template still renders a schema it does not
    know and still says which way the mismatch runs (yngboard R6.6).
8.  **Every judgement stays in the run** (yngboard R7.2): which board
    sits above this one, what is readable, what order the reports come
    in, and which lines of the log are this slice's are all settled
    when the payload is written. The template does arithmetic on the
    instants the run baked in, and decides nothing.

## R8 Who writes which board

1.  | The writer                        | Writes                         |
    |-----------------------------------|--------------------------------|
    | an Epic run (the dispatcher)      | the Epic's board only          |
    | a slice run ([scoped.md](scoped.md)) | its own board **and** the Epic's |
    | a standalone run                  | its own board                  |
    | `/yngorchestrator board`          | the one board R4 names         |

2.  **The dispatcher writes no slice board.** It appends a line per
    slice event, interim reports included; writing each slice's board
    too would mean five writes per event with four live workers, each
    rebuilding a payload nobody is looking at — a slice board is read
    by someone sitting in that slice's worktree, and the dispatcher's
    instance is not.
3.  **A slice run writes both**, because it appends its lines to the
    Epic's log and the write rule covers the log it wrote to (yngboard
    *Run log*). Dropping the Epic's would stall it silently whenever
    work goes through slice runs.
4.  Both of a slice run's writes are reads it has already made: one
    gather, two renders.

## R9 Board writes coalesce

*Amends yngboard R3.2.*

1.  The rule becomes: **appending one or more lines to
    `yngorchestratorruns/<log>.md` rewrites that log's board once,
    after the last line of the batch.** A batch is the lines a step
    appends before it does anything else.
2.  yngboard R3.2 fired per line. Draining a channel of four interim
    reports therefore cost four writes, each rebuilding the whole
    payload, to change one slice's list — and R14's interim reports
    made such batches the common case, not the rare one.
3.  Nothing a person can observe changes: the board after the batch is
    identical either way, written once instead of N times.
4.  The rule keeps its shape and its home — a property of appending to
    the log, stated once in `SKILL.md`'s *Run log* section and nowhere
    else (yngboard R3.2).
5.  A batch that fails part-way still rewrites the board for the lines
    that landed: the board follows the log as it is, not as it was
    meant to be.

## R10 `run-board` and the command

*Amends yngboard R8.*

1.  `run-board` governs what a **run** does without being asked:
    `write`, `open` or `no` (yngboard R8.1).
2.  **`/yngorchestrator board` ignores it**, including `no`: a command
    typed by name is the person asking. It writes and opens.
3.  `run-board: no` therefore means "no board unless I ask for one",
    which is a usable setting rather than a dead one.
4.  The setting's documentation says this plainly, in the config
    template and in `INSTALL.md`.

## R11 An issue with no run log

1.  The command renders a board for an issue whose
    `yngorchestratorruns/<n>.md` does not exist: `runlog` is `[]`,
    every `dispatchedAt` is null, and no slice carries an interim
    report.
2.  The provider still has the slices, their labels, their pull
    requests and their `Depends on:` lines, which is the whole table.
3.  The moment before a run starts is exactly when a person wants to
    see what is about to happen, so refusing here would make the
    command useless in its best case.
4.  The board says, in one line, that no run has been logged for this
    issue.

## R12 `yngboard`, the terminal command

*Amends yngboard R9.1, withdraws yngboard R9.6, and amends R9.3's
wording, not its rule.*

1.  Its branch table maps a branch to the **issue** whose board to
    open, following R6:

    | The branch      | The board it opens                          |
    |-----------------|---------------------------------------------|
    | `epic/<n>-`     | `yngboard-<n>.html`, the Epic's             |
    | `slice/<n>-`    | `yngboard-<n>.html`, **that slice's own** (R5) |
    | `fix/<n>-`      | `yngboard-<n>.html`, the standalone's       |
    | no issue named  | the most recently written `yngboard-*.html` |

    `slice/<n>-` therefore opens that slice's board, not its Epic's.
    The last row is unchanged: the project root, `main`, a detached
    HEAD, and any branch carrying no issue number. A branch that names
    an issue still takes that issue's board or none at all — never
    another issue's, and its Epic's least of all, which is the one a
    person standing in a slice worktree could mistake for theirs.
2.  **yngboard R9.6 is withdrawn.** It had `yngboard` scan
    `yngorchestratorruns/*.md` for a line naming `#<n>`, to find the
    Epic log a slice's board was named for; with R6 naming every board
    for its own issue there is nothing left to find, because the branch
    names the board's issue directly. One test for a file replaces
    reading every run log, and a slice whose Epic has not logged it yet
    still has its own board.
3.  Where no board exists for that issue, its one line names
    **`/yngorchestrator board`**, not `/yngorchestrator <n>`: the
    cheaper command that does what the person asked. Where the branch
    names no issue, that line names `/yngorchestrator board <issue>`,
    since R4.1 needs an `<n>` there. It names a whole Epic run only
    where Claude Code cannot be reached, which is the scripts' headers
    and not this line.
4.  It still opens a file and nothing else (yngboard R9.3). Nothing in
    this feature gives it a provider call: that rule stands exactly as
    written, and this Epic adds the refreshing command beside it rather
    than inside it.
5.  Everything else of yngboard R9 stands: finding `<root>` (R9.2),
    `YNGV_HTML_BROWSER` read by `yngboard` itself and the four
    scripts' one function (R9.7, R9.9), the opening left to `yngv`
    (R9.8), and `-h` / `--help` with its header, an argument refused
    with exit 2, and the exit codes (R9.10) — where "no board for this
    worktree's log" is now "for this worktree's issue".

## R13 Vocabulary

1.  An **Epic board**, a **slice board** and a **standalone board** are
    the three kinds, all of them run boards, each named for the issue
    it is about.
2.  **Worktree**, not "workspace": the unit a person stands in is a
    worktree, and a Herdr space is the window around one. The guide,
    the skill and the command's own messages say worktree.
3.  The bare word "status" stays banned as a label or column heading
    (ynghandback R16.3, yngboard R11.3).
4.  No root `GLOSSARY.md`. These definitions live here, and the
    config template's "Words used below" gains nothing: `board` is a
    command argument, not a setting.

## R14 Documentation

1.  `guides/epic-workflow.md`, section 25's subsection: the command,
    the three kinds of board, and that a slice board is deliberately
    redundant.
2.  `README.md`: `/yngorchestrator board` beside `yngboard`.
3.  `INSTALL.md`: the command, and `run-board: no` described as "no
    board unless I ask" (R10.3).
4.  Every place that describes `yngboard` says what it cannot do —
    refresh — and names the command that can.

## R15 Version

1.  `VERSION` and `SKILL.md`'s `metadata.version` to **1.17.0**.
    Nothing breaks: a command argument and a board kind arrive, and a
    write rule fires less often.
2.  A `## [1.17.0]` entry in `CHANGELOG.md` with **Added** and
    **Changed**: the command, slice boards, boards named per issue,
    coalesced writes.
3.  `decisions.md` beside this file carries the options refused.
