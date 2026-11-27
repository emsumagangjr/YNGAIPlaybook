# Write the run board

The run board is one HTML file for one issue: every slice of the Epic,
each slice's state, and what each needs from a person (R1.1,
yngboardcommand R6.1). You write it again at every run-log event, so
it says where everything has got to as of the line just appended.

This file is six things in order — **gather, rank, build the payload,
render, write, open** — and no run-log line at the end. The board write
is not itself an event: a rule that fires on every line must not write
a line, and a derived file is not a change to issue state (R3.4).

It is a rendering, not a second source of truth. **Every judgement is
made here, never in the template** (R7.2): the order of the rows, each
row's `attention` value, the merge path, and a label and a report that
disagree. The template may do arithmetic on an instant you baked in —
an elapsed figure beside it — and it decides nothing (R7.4).

The board never acts (R1.5, R10). Nothing here adds a control, a form
or a request of any kind to it: every row that needs a person carries
the provider address where they act, and the next run reads what they
did, as it already does.

## When you arrive, and what you hold

**At every event.** The rule is stated once, in *Run log* in
[SKILL.md](SKILL.md), as a property of appending a line, and it names
there the two runs it does not reach. Nothing else in the skill
restates it (R3.2).

You hold what the run already holds: `<root>`, `<log>` (*Run log* in
SKILL.md), `<run-board>` (step 3 of [locate.md](locate.md)), `<host>`,
`<code repo>`, `<issues repo>`, the run's issue `<n>` with its title
and branch, the Epic's worktree and spec folder where the run holds
them, and the reads the step that logged the line made. `<skill>` is
the folder holding this file and SKILL.md.

| `<run-board>` | What this file does                                                                 |
|---------------|-------------------------------------------------------------------------------------|
| `write`       | steps 1 to 5: writes the board or boards this run owns, opens nothing (the default) |
| `open`        | the same, and step 6 opens it once, at this run's first write                       |
| `no`          | nothing: return to the step that called you                                         |

Writing a board is a local file write: it shows nothing and interrupts
nothing, and this file prints no line of its own for it (R3.1, R3.8).
At the hand-back, step 5 of SKILL.md and step 8 of
[scoped.md](scoped.md) name the path of every board the run wrote,
once, below the prose list that still comes first and stays whole
(R1.4).

## Which board this run writes

Every board is `<root>/.yngaiplaybook/yngboard-<issue>.html`, where
`<issue>` is the issue the board is **about**: the Epic for an Epic's
board, the slice for a slice's, the issue itself for a standalone's
(yngboardcommand R6.1).

yngboard R2.1 named the file for `<log>` instead, one board per run
log. A slice's log is its Epic's (*Run log* in SKILL.md), so `<log>`
can no longer tell an Epic's board from its slice's, now that a slice
has one of its own (yngboardcommand R6.2). Nothing an existing install
holds changes name: an Epic's `<log>` and its own number are the same,
and so are a standalone's (yngboardcommand R6.3). Issue numbers are
unique in the issues repo, so no two boards collide (yngboardcommand
R6.4).

### Who writes which board

| The writer                           | Writes                                               |
|--------------------------------------|------------------------------------------------------|
| an Epic run (the dispatcher)         | the Epic's board only                                |
| a slice run ([scoped.md](scoped.md)) | its own board **and** the Epic's                     |
| a standalone run                     | its own board                                        |
| `/yngorchestrator board`             | the one board the command names (yngboardcommand R4) |

**The dispatcher writes no slice board** (yngboardcommand R8.2). It
appends a line per slice event, interim reports included; writing each
slice's board too would mean five writes an event with four live
workers, each rebuilding a payload nobody is looking at. A slice board
is read by someone sitting in that slice's worktree, and the
dispatcher's instance is not.

**A slice run writes both** (yngboardcommand R8.3), because it appends
its lines to the Epic's log and the write rule covers the log it wrote
to (*Run log* in SKILL.md). Dropping the Epic's would stall it
silently whenever the work goes through slice runs. Both writes are
reads it has already made: one gather, two renders — steps 1 and 2
once, then steps 3 to 5 again for the second board (yngboardcommand
R8.4).

**yngboard R2.2 is withdrawn** (yngboardcommand R5.2): "a slice run
writes its Epic's board and never a board of its own". It followed
from boards being named by run log, which yngboardcommand R6 changes.

### What each board is about

| The board                           | Is about         | `epic`, `slices`     | `mergePath`     |
|-------------------------------------|------------------|----------------------|-----------------|
| an Epic's, `yngboard-<epic>.html`   | the Epic         | the Epic, its slices | `slice-to-epic` |
| a standalone's, `yngboard-<n>.html` | the issue itself | `null`, `[]`         | `fix-to-main`   |

A slice board, `yngboard-<slice>.html`, is about its slice; what it
holds is yngboardcommand R5 and R7.

A slice run holds its Epic only as `<parent>` ([scoped.md](scoped.md)),
so the Epic's title, address and slices are reads it makes here (step
1). A standalone run's board is about the issue the run is on: there
is no Epic above it, and it is no slice of one (R10, ynghandback R9.1).

## 1. Gather

The payload is live data. It comes from four operations, on this run's
own Epic and its slices — or on a standalone's own issue — and on
nothing else (R10, ynghandback R10.1, R10.2):

| What you need                                     | Operation                         |
|---------------------------------------------------|-----------------------------------|
| the Epic's slices, their titles and labels        | *list children* `<n>`             |
| each slice's body, for its `Depends on:` line     | *read issue* `<m>`                |
| each slice's pull request                         | *list prs*, head `^slice/[0-9]+-` |
| a pull request's state, checks, mergeable, number | *pr status* `<PR>`                |

**Use what the run already holds.** A board is written at every event,
and the step that logged the line holds the reads it made: a label it
has just set, a pull request it has just merged, an issue it has just
closed, the slices *list children* gave at the start of the run.
Gather from the provider only what the run holds nothing current for —
the first board of a run, and an answer an action since has changed.
ynghandback R10.2 kept page generation from adding provider traffic of
its own; written at every event, that matters more, not less. Add no
operation to the four, and make none about an Epic this run is not
running.

In a **standalone** run there are no slices, so none of those four is a
read of one: the issue is the board's own subject (*read issue* `<n>`,
which the run has already made), and its pull request is found by *list
prs* for the head `^fix/<n>-`, then *pr status* (R10, ynghandback R9.1).

In a **slice** run the board is its Epic's, so these are the Epic's
reads: *read issue* `<parent>` for the Epic's title and address, *list
children* for its slices, and the per-slice reads above. For a slice
run writing its Epic's board those reads **are** the board, not traffic
on top of it.

**The Epic's own pull request** fills the first row (R4.7, R6.8), and
is read only where the run holds it: step 5 of SKILL.md looks for it
with *list prs* for the head `^<epic branch>$` once every slice is
closed. Before that there is none to show, and no read is made to
confirm it: `issue.pr` is `null`.

The **run log** is the narrative spine, and is read from
`<root>/.yngaiplaybook/yngorchestratorruns/<log>.md`, never from the
provider (R10, ynghandback R10.1). It gives `runlog`, each slice's
dispatch instant, its latest interim report and its last completion
report, the conditions that held a merge, and the deferred worktree
removals. It records events, not current truth — a label changed by
hand, a check gone red, a pull request someone else merged are in none
of it — so where the log and a live read differ, the live read is what
the board shows. For a label and a report, ynghandback R7 settles it,
carried over whole by R10: step 2's `conflict` value.

**A failed operation writes nothing.** When any of the four fails — a
rate limit, an expired login, an outage — leave the existing
`yngboard-<issue>.html` exactly as it is and return to the step that
called you, naming the operation that failed. Say it once in the run:
which operation failed, that the board on disk is unchanged, and that
it carries its own timestamp. Do not retry, and never write a board
from part of the data: an honestly dated board from this morning beats
a freshly dated one that is wrong where the person cannot see it (R10,
ynghandback R10.3, R10.4). A later failure of the same kind in the same
run needs no second line; the run goes on either way, because a board
is a rendering and nothing waits on it.

Done when you hold the four reads and the run log, or the write has
stopped with the operation that failed.

## 2. Rank

The table is one row per slice, and the run decides both what each row
needs from a person and the order they come in: the template renders
`slices[]` in the order you give it and re-orders nothing (R4.9, R7.2).

### What the row needs from a person

One value per row, on open slices only — a closed slice needs nothing
and takes `none` — with the address where the person acts (R4.3, R4.4):

| `attention` | A row for                                                         | `actionUrl`      |
|-------------|-------------------------------------------------------------------|------------------|
| `conflict`  | a slice whose label and its last report disagree                  | the issue        |
| `held`      | a slice whose last `merge held <condition>` has no later `merged` | the pull request |
| `decision`  | a slice with an open review decision and an `OPEN` pull request   | the pull request |
| `merge`     | a slice at `workflow:in-review` whose pull request is `OPEN`      | the pull request |
| `human`     | a slice at `workflow:ready-for-human`                             | the issue        |
| `promote`   | an open slice still waiting for Gate 1                            | the issue        |
| `none`      | anything else: the row is there to say where the slice is         | `null`           |

A slice has one row, so it takes **the first value in that table that
applies to it**, which is the most specific: a held merge and an open
decision are both true of a pull request waiting for review, and
`merge` alone would say the least of the three. Where a later value
also applied, name it in the same `why`: half of what is waiting is
worse than a longer sentence. A `conflict` comes first because it says
the rest of the row may be wrong.

A `promote` row is a slice still waiting for Gate 1: it carries none
of `workflow:ready-for-agent`, `workflow:in-progress`,
`workflow:in-review` or `workflow:ready-for-human`. A `conflict` row is
a slice whose label and its last report disagree, which *A label and a
report that disagree* in [track.md](track.md) names pair by pair.

`why` is one sentence, in SKILL.md step 5's own words: for `merge`,
that the pull request is open for review (Gate 2), with its checks; for
`held`, the condition that held the merge; for `human`, the reason —
two attempts, `needs-human`, or routed to a person by the plan; for
`promote`, that it waits for Gate 1; for `decision`, the open question,
as the review record phrases it; for `conflict`, both readings, with
the date of the report's run-log line, and that the label is the one
the run acts on (R10, ynghandback R7.2, R7.3). `why` is `null` for
`none`, which has no reason, and `actionUrl` is `null` with it: there
is nowhere to go.

An `actionUrl` is never lent across values: a pull request standing in
for an issue is worse than no link at all (R10, ynghandback R3.6). The
row's own `url` stays the slice's issue, whichever address its
`actionUrl` carries.

`blocks` is every open slice whose `Depends on:` line names this row's
issue, by number, lowest first; `[]` when the row holds nothing up.

In a standalone run the issue itself is read as the table's one row:
its own label and its own pull request give it the same values, and its
`blocks` is always `[]` — with `slices: []` there is nothing for it to
hold up (R10, ynghandback R9.1).

### The order

The ranking of SKILL.md step 5 survives as the order of the rows
(R4.2). Rows whose `attention` is anything but `none` come first:

1. the rows holding up the most slices first — most `blocks` first;
   equal counts by issue number, lowest first;
2. then, while any row sits after a row on a slice its own `blocks`
   names, move it directly before that row: a slice waiting on a
   person comes ahead of the rows it holds up. `Depends on:` has no
   cycles, so this ends.

Then every remaining row, by issue number, lowest first. The same
inputs always give the same order, and that order is SKILL.md step 5's.

The board's own issue is not in `slices[]` and is not ranked: the
template puts it first, always (R4.1).

Done when every slice has its `attention`, `why`, `actionUrl` and
`blocks`, and `slices[]` is in that order.

## 3. Build the payload

Every key of R6.1, in that order, schema `2`. An absent value is
`null`, an absent list `[]`.

| Key         | What you write                                                                   |
|-------------|----------------------------------------------------------------------------------|
| `schema`    | `2`                                                                              |
| `generated` | now, in UTC, in the lock's form: `date -u +%Y-%m-%dT%H:%M:%SZ` (R6.4)            |
| `live`      | `true`: this payload was gathered from the provider                              |
| `mergePath` | this run's own merge path, as [merge.md](merge.md) and [track.md](track.md) name it: `slice-to-epic` for an Epic and its slices, `fix-to-main` for a standalone (R6.4) |
| `issue`     | the issue this board is about, as the table's first row                          |
| `epic`      | the Epic's `number`, `title`, `url` and `spec`; `null` in a standalone run        |
| `slices`    | step 2's rows, one per slice from *list children*, in step 2's order; `[]` in a standalone run |
| `runlog`    | the run log's lines, oldest first, each as its own string                        |
| `worktrees` | the Epic's worktree and its slices', or a standalone's own, as `{ "path": ..., "deferred": ... }` |

`waiting[]` is gone: the ranked list it carried is the order of
`slices[]`, and what each row was waiting for is that row's own
`attention` (R6.1, R4.2).

### `issue`, the first row

`issue` is the one key both kinds fill, and the template takes the
board's heading, its identity and its first row from it: the Epic in an
Epic or a slice run, the standalone issue in a standalone run. It
carries the four fields that name it, and then the same row fields a
slice carries, because the first row is a row (R6.2, R4.7):

| Key                        | What you write                                                       |
|----------------------------|----------------------------------------------------------------------|
| `number`, `title`, `url`   | the issue's own, with the provider file's *Issue URL*                 |
| `branch`                   | that issue's own branch, `epic/<n>-<name>` or `fix/<n>-<name>`        |
| `label`                    | its one `workflow:*` state, or `null`                                 |
| `attention`, `why`, `actionUrl` | step 2's table, read on this issue and its own pull request      |
| `pr`                       | the `epic-to-main` pull request, or a standalone's `fix-to-main` one; `null` where the run holds none (step 1) |
| `blocks`                   | `[]`: nothing in `slices[]` depends on the board's own issue          |

`branch` is the only branch the payload carries: `epic` has none of its
own (R6.4, ynghandback R4.9). `epic` is what only an Epic has beside
it: its spec folder and its slice set.

In a standalone run `epic` is `null` and `slices` is `[]` (R10,
ynghandback R9.1). Its board is then that one row, and the sections an
Epic's board builds from `slices[]` have nothing to show.

`epic.url` is the provider file's *Issue URL*. `epic.spec` is an
address the board can open from `<root>/.yngaiplaybook/`, where the
board sits: the spec folder in the Epic's worktree, written relative to
that folder, with a space in any segment written `%20` (R6.4,
ynghandback R4.8, R3.6). The repository-relative `docs/specs/<feature>/`
the issue names would be a dead link from there:

``` text
../<the Epic worktree's folder name>/docs/specs/<feature>/
```

### A slice

| Key                      | What you write                                             |
|--------------------------|------------------------------------------------------------|
| `number`, `title`, `url` | from *list children*, with the provider file's *Issue URL* |
| `label`                  | the issue's one `workflow:*` state, or `null`              |
| `attention`, `why`, `actionUrl` | step 2's                                            |
| `dispatchedAt`           | the instant it was last dispatched, from the run log       |
| `report`                 | the slice's last completion report, from the run log       |
| `progress`               | its latest interim report, from the run log                |
| `pr`                     | its pull request, from *pr status*                         |
| `dependsOn`              | the numbers on the issue's `Depends on:` line              |
| `blocks`                 | step 2's                                                   |
| `decisions`              | the open lines of the slice's review record                |

`label` is the issue's one `workflow:*` state (yngproviders R8). It is
what tells the template a slice is in flight, so it is the live read,
never the run log's reading of it (R5.2).

`dispatchedAt` is the UTC instant on the slice's last `dispatched` or
`re-dispatched` line in the run log (*Run log* in SKILL.md), and
`null` where it has not been dispatched. It is `null` too where that
line carries a date and nothing finer, as an older log's does: the
elapsed figure needs an instant, and the row then says *dispatched,
time unknown* rather than an age counted from midnight (R6.3, R5.2).

`report` is the run log's last `reported` line for `#<m>`:
`report.outcome` is the `STATUS` that line carries, `report.at` is that
line's date as the log writes it, and `report.summary` the report's
`SUMMARY`. `pr` is `number`, `url`, `state`, `checks` and `mergeable`
from *pr status*, where `pr.checks` is the provider's rollup — `none`,
`pending`, `passed` or `failed` — and `pr.mergeable` is `true` for its
`yes`, `false` for its `no` and `null` for its `unknown`. A slice with
no report line, or no pull request, carries `null` for that key.

Those three are three different things, and the payload keeps them
apart, each named by what it is (R6.5): `label` is the provider's
label, `report.outcome` the completion report's `STATUS`
([report.md](report.md)), and `pr.checks` the provider's checks rollup.
The payload's key is `outcome`; the report's own field in
[report.md](report.md) keeps its name.

`progress` is the slice's latest **interim report** (R14.5): the last
readable `progress` line for `#<m>` that comes after its last
`dispatched` or `re-dispatched` line, as
`{ "at": <its instant>, "step": <its step>, "note": <its one line> }`,
and `null` where this attempt has none. Nothing earlier than that
dispatch is carried: a re-dispatched slice's fresh worker has reported
nothing yet, and the attempt before would read as this one — the
inversion R6.7 already guards `dispatchedAt` against. A line logged
`progress unreadable` is no interim report: it stays in `runlog`,
where the person can see what arrived, and nothing is built from it
(R14.4). `at` is written in `generated`'s own form, which names its
zone, because the row derives an elapsed figure from it (R5.4, R7.3);
`step` and `note` are the worker's own words, and no phase, fraction
or guess is added to them (R14.6). The template shows it on an
in-flight row alone, and a slice with none still reads *nothing
reported yet* beside its dispatch instant (R5.2).

`decisions` and `report.summary` come from the completion reports this
run acted on: `decisions` is the report's `REVIEW RECORD`, which is
also the pull request description's. A slice whose report reached an
**earlier** run carries `[]` and `null`: nothing the run holds says
otherwise, and fetching them would be a provider call SKILL.md step 5
does not make.

`worktrees` comes from
`git --git-dir="<root>/.bare" worktree list --porcelain`: the Epic's
worktree and those on this Epic's slice branches, or, in a standalone
run, the one on `fix/<n>-<name>`. `deferred` is `true` where the run
log holds a `worktree removal deferred <path>` line with no later
`worktree removed` for that slice (*Sweep deferred removals* in
[track.md](track.md)); such a path is listed even when `worktree list`
no longer shows it.

Done when the payload holds every key of R6.1, in that order, under
`schema: 2`.

## 4. Render

The markup and style are a shipped file, and the run authors none of it
(R10, ynghandback R3.1): it substitutes the payload into the one empty
placeholder that file carries (ynghandback R3.2).

| Written from                | Placeholder's `id` |
|-----------------------------|--------------------|
| `<skill>/web/template.html` | `handback-data`    |

The placeholder keeps the `id` ynghandback R3.2 named, so the rename of
the page changed neither the substitution here nor anything that reads
a board back.

Write every payload and every half-built file to a temporary file
**outside** `.yngaiplaybook/`: `yngboard-<n>.html` is the only path
this feature adds there (R2.5).

### Escaping the payload

Every `<` in the payload is written `\u003c`, which JSON reads back as
the same character and no parser can read as a tag (R10, ynghandback
R3.3):

``` bash
escape() {  # escape <in> <out>
  awk 'BEGIN { bs = sprintf("%c", 92) }
       { n = split($0, part, "<")
         line = part[1]
         for (i = 2; i <= n; i++) { line = line bs "u003c" part[i] }
         print line }' "$1" > "$2"
}
```

The backslash comes from its own character code because a tool's escape
syntax can swallow it, silently and without failing: GNU `sed` reads
`\u` in a replacement as *uppercase the next character*, so
`sed 's/</\\u003c/g'` writes `003c`, and `gawk` 5.3 and later read
`"\\u003c"` in a string literal as `<` itself, which escapes nothing.
Either leaves a payload that still parses and is wrong in its strings.

### Substituting the payload

``` bash
substitute() {  # substitute <shipped file> <id> <escaped payload> <out>
  awk -v id="$2" -v data="$3" '
    { line = $0; sub(/\r$/, "", line) }
    line == "<script type=\"application/json\" id=\"" id "\"></script>" {
      print "<script type=\"application/json\" id=\"" id "\">"
      while ((getline payload < data) > 0) print payload
      close(data)
      print "</script>"
      found++
      next
    }
    { print }
    END { exit(found == 1 ? 0 : 1) }' "$1" > "$4"
}
```

It succeeds only if it met the placeholder exactly once: one
substitution, into the element ynghandback R3.2 names, and never into a
second copy of that tag.

``` bash
json=<the payload file>; esc=$(mktemp); out=$(mktemp)

escape "$json" "$esc"
substitute "<skill>/web/template.html" handback-data "$esc" "$out"
```

Where either `awk` failed, nothing is written: leave the board on disk
exactly as it is and return to the step that called you with the reason
`template placeholder not found`, as step 1 returns the operation that
failed.

Done when `$out` is the shipped template holding this payload, or
nothing was written and the step that called you has the reason.

## 5. Write

The board is overwritten whole: no history is kept, because the run log
is the history (R2.4).

Both paths here key on the board's own `<issue>`, never on `<log>`
(yngboardcommand R6.5):

``` bash
board="<root>/.yngaiplaybook/yngboard-<issue>.html"
mv "$out" "$board"
```

Then delete the files this board replaces, where they are still there
(R2.3):

``` bash
rm -f "<root>/.yngaiplaybook/ynghandback.html" \
      "<root>/.yngaiplaybook/ynghandback-<issue>.html"
```

Those are the two files 1.15.0 wrote for this issue: the page it wrote
at the hand-back, and the project index that listed every run's page.
Nothing writes either any more, and a file nothing updates is worse
than one that is either current or absent. Delete them after the board
is in place, and only for this board's own `<issue>`: another issue's
stale files belong to the run that writes that issue's board (R2.3).

A slice run arrives here twice, once for each board it writes
(*Who writes which board* above): its own first, then its Epic's.

Done when `yngboard-<issue>.html` holds this payload and neither stale
file is left beside it.

## 6. Open

With `<run-board>` `open`, and only at **this run's first** board write
(R3.3) — for a slice run, its own board, which step 5 writes first:

``` bash
yngv "<root>/.yngaiplaybook/yngboard-<issue>.html"
```

`yngv` is the viewer the installer put on the person's PATH
(yngorchestrator R13); it opens an `.html` file in the default browser.
When it is not on PATH, or it fails, say so and name the board's path:
the board is written either way, and the person opens it themselves.

The run remembers that it has opened one; nothing on disk records it.
Every later write in the run opens nothing, whatever is on screen: the
person's tab is reloaded, or `yngboard` opens it again (R9). A board
already on disk from an earlier run does not count — this run opens at
its own first write.

With `write`, open nothing, here or anywhere.

Done when the board is open, or the person has its path, or this run
has already opened one.
