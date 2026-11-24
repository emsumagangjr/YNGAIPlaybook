# Write the hand-back page

The hand-back page is one HTML file for one Epic, written at the
hand-back and opened in the person's browser: what is waiting on them,
in the order step 5 of [SKILL.md](SKILL.md) ranked it (ynghandback R1).
This file is four things in order — **gather, rank, render, open** — and
a run-log line at the end.

It is a rendering, not a second source of truth. That step worked out
what waits and in what order; here you write that down, into the shipped
template, and open it. A page that disagrees with the list the person
has just read is a defect (R1.2, R3.5).

You arrive from step 5 of [SKILL.md](SKILL.md), once, at the
hand-back, holding what the run already holds: `<root>`, `<log>` (*Run
log* in SKILL.md), `<handback-page>` (step 3 of
[locate.md](locate.md)), `<host>`, `<code repo>`, `<issues repo>`, the
Epic `<n>` with its title, branch, worktree and spec folder, and step
5's own list. `<skill>` is the folder holding this file and SKILL.md.

The page never acts (R11). Nothing here adds a control, a form or a
request of any kind to it: every waiting row carries the provider
address where the person acts, and the next run reads what they did, as
it already does.

## When a page is written, and when none is

| `<handback-page>` | What this file does                                   |
|-------------------|-------------------------------------------------------|
| `open` (default)  | writes the page, then opens it (steps 1 to 5)         |
| `write`           | writes the page and opens nothing (steps 1 to 4)      |
| `no`              | writes no page: go to step 6 with `handback-page: no` |

Once per run, here, and never on a tracked event: an Epic of eight
slices would otherwise open eight browser windows (R14.1, R14.2). A run
that stopped with a reason never reaches this file, and writes no page:
the page says what is waiting at a hand-back, and there was none
(R14.4).

## 1. Gather

The payload is live data. Gather it from four operations, on this run's
own Epic and its slices, and on nothing else (R10.1, R10.2):

| What you need                                     | Operation                         |
|---------------------------------------------------|-----------------------------------|
| the Epic's slices, their titles and labels        | *list children* `<n>`             |
| each slice's body, for its `Depends on:` line     | *read issue* `<m>`                |
| each slice's pull request                         | *list prs*, head `^slice/[0-9]+-` |
| a pull request's state, checks, mergeable, number | *pr status* `<PR>`                |

These four are SKILL.md step 5's own inputs: it ranks its list from the
same reads. Add no operation to them, and make none about an Epic this
run is not running. Where the run already made one of these reads in
this run, and nothing it has done since could have changed the answer,
use what it read: the page shows that step's data, not a second reading
of it.

The **run log** is the narrative spine, and is read from
`<root>/.yngaiplaybook/yngorchestratorruns/<log>.md`, never from the
provider (R10.1). It gives `runlog`, each slice's last report, the
conditions that held a merge, and the deferred worktree removals. It
records events, not current truth — a label changed by hand, a check
gone red, a pull request someone else merged are in none of it — so
where the log and a live read differ, the live read is what the page
shows. For a label and a report, R7 settles it: step 2's `conflict`
row.

**A failed operation writes nothing.** When any of the four fails — a
rate limit, an expired login, an outage — leave the existing
`ynghandback-<log>.html` and the project index exactly as they are,
and go to step 6 with the reason `<operation> failed`. Tell the person
which operation failed, that the page on disk is unchanged, and that
it carries its own timestamp. SKILL.md step 5's prose list still
stands — it was printed before this step, from the data the run has —
so name the failed operation beside it, and say that list may be
incomplete. Do not retry, and never write a page from part of the
data: an honestly dated page from yesterday beats a freshly dated page
that is wrong where the person cannot see it (R10.3, R10.4).

Done when you hold the four reads and the run log, or the write has
stopped with the operation that failed.

## 2. Rank

`waiting[]` is the page's first and largest section, and the run ranks
it: the template renders the rows in the order you give them and
re-orders nothing (R3.4, R5.1).

One row per thing waiting on a person, on open slices only, with the
kinds of SKILL.md step 5's list (R5.2), and the address where that
person acts (R5.4):

| `kind`     | A row for                                                         | `url`            |
|------------|-------------------------------------------------------------------|------------------|
| `merge`    | a slice at `workflow:in-review` whose pull request is `OPEN`      | the pull request |
| `held`     | a slice whose last `merge held <condition>` has no later `merged` | the pull request |
| `human`    | a slice at `workflow:ready-for-human`                             | the issue        |
| `promote`  | an open slice still waiting for Gate 1                            | the issue        |
| `decision` | a slice with an open review decision and an `OPEN` pull request   | the pull request |
| `conflict` | a slice whose label and its last report disagree                  | the issue        |

A `promote` row is a slice still waiting for Gate 1: it carries none
of `workflow:ready-for-agent`, `workflow:in-progress`,
`workflow:in-review` or `workflow:ready-for-human`. A `conflict` row
is a slice whose label and its last report disagree, which *A label
and a report that disagree* in [track.md](track.md) names pair by
pair.

`why` is one sentence, in SKILL.md step 5's own words: for `merge`,
that the pull request is open for review (Gate 2), with its checks; for
`held`, the condition that held the merge; for `human`, the reason —
two attempts, `needs-human`, or routed to a person by the plan; for
`promote`, that it waits for Gate 1; for `decision`, the open
question, as the review record phrases it; for `conflict`, both
readings, with the date of the report's run-log line, and that the
label is the one the run acts on (R7.2, R7.3).

A row's `issue` is the slice's own number, whichever address its
`url` carries. A `url` is never lent across kinds: a pull request
standing in for an issue is worse than no link at all (R3.6).

`blocks` is every open slice whose `Depends on:` line names this row's
issue, by number, lowest first; `[]` when the row holds nothing up
(R5.3).

Then rank, in SKILL.md step 5's order:

1. the rows holding up the most slices first — most `blocks` first;
   equal counts by issue number, lowest first, and two rows on one
   issue in the order of the table above;
2. then, while any row sits after a row on a slice its own `blocks`
   names, move it directly before that row: a slice waiting on a
   person comes ahead of the items it holds up. `Depends on:` has no
   cycles, so this ends.

The same inputs always give the same order, and that order is SKILL.md
step 5's (R1.2).

Done when `waiting[]` is built and ranked, or is empty — which the
template renders as one line, so write `[]` and add nothing.

## 3. Build the payload

Every key of R4.1, in that order, schema `1`. An absent value is
`null`, an absent list `[]` (R4.2).

| Key         | What you write                                                                   |
|-------------|----------------------------------------------------------------------------------|
| `schema`    | `1`                                                                              |
| `generated` | now, in UTC, in the lock's form: `date -u +%Y-%m-%dT%H:%M:%SZ` (R4.3)            |
| `live`      | `true`: this payload was gathered from the provider (R10.5)                      |
| `mergePath` | `slice-to-epic`, the path [merge.md](merge.md) reads for an Epic's slices (R4.7) |
| `epic`      | the Epic's `number`, `title`, `branch`, `url` and `spec`                         |
| `waiting`   | step 2's ranked rows                                                             |
| `slices`    | one entry per slice from *list children*, in number order                        |
| `runlog`    | the run log's lines, oldest first, each as its own string                        |
| `worktrees` | the Epic's worktree and its slices', as `{ "path": ..., "deferred": ... }`       |

`epic.url` is the provider file's *Issue URL*. `epic.spec` is an
address the page can open from `<root>/.yngaiplaybook/`, where the
page sits: the spec folder in the Epic's worktree, written relative to
that folder, with a space in any segment written `%20` (R4.8, R3.6).
The repository-relative `docs/specs/<feature>/` the issue names would
be a dead link from there:

``` text
../<the Epic worktree's folder name>/docs/specs/<feature>/
```

A slice's entry:

| Key                      | What you write                                             |
|--------------------------|------------------------------------------------------------|
| `number`, `title`, `url` | from *list children*, with the provider file's *Issue URL* |
| `label`                  | the issue's one `workflow:*` state, or `null`              |
| `report`                 | the slice's last report, from the run log                  |
| `pr`                     | its pull request, from *pr status*                         |
| `dependsOn`              | the numbers on the issue's `Depends on:` line              |
| `decisions`              | the open lines of the slice's review record (R4.5)         |

`label` is the issue's one `workflow:*` state (yngproviders R8).
`report` is the run log's last `reported` line for `#<m>`:
`report.status` is the `STATUS` that line carries, `report.at` is
that line's date as the log writes it, and `report.summary` the
report's `SUMMARY`. `pr` is `number`, `url`, `state`, `checks` and
`mergeable` from *pr status*, where `pr.checks` is the provider's
rollup — `none`, `pending`, `passed` or `failed` — and `pr.mergeable`
is `true` for its `yes`, `false` for its `no` and `null` for its
`unknown`. A slice with no report line, or no pull request, carries
`null` for that key.

Those three are three different things, and the payload keeps them
apart, each named by what it is (R4.4, R16.3): `label` is the provider's
label, `report.status` the completion report's `STATUS`
([report.md](report.md)), and `pr.checks` the provider's checks rollup.

`decisions` and `report.summary` come from the completion reports
this run acted on: `decisions` is the report's `REVIEW RECORD`, which
is also the pull request description's (R4.5). A slice whose report
reached an **earlier** run carries `[]` and `null`: nothing the run
holds says otherwise, and fetching them would be a provider call step
5 does not make (R10.2).

`worktrees` comes from
`git --git-dir="<root>/.bare" worktree list --porcelain`: the Epic's
worktree and those on this Epic's slice branches. `deferred` is `true`
where the run log holds a `worktree removal deferred <path>` line with
no later `worktree removed` for that slice (*Sweep deferred removals*
in [track.md](track.md)); such a path is listed even when `worktree
list` no longer shows it.

Done when the payload holds every key of R4.1, in that order.

## 4. Render

The page's markup and style are the shipped template, and the run
authors none of them (R3.1). Substitute the payload into the
template's one empty placeholder (R3.2), and write the result to
`<root>/.yngaiplaybook/ynghandback-<log>.html`, whole: no history is
kept, because the run log is the history (R2.1, R2.3).

Write the payload to a temporary file **outside** `.yngaiplaybook/`:
`ynghandback.html` and `ynghandback-<log>.html` are the only paths
this feature adds there (R2.4).

``` bash
json=<the payload file>; esc=$(mktemp); out=$(mktemp)
tpl="<skill>/web/template.html"
page="<root>/.yngaiplaybook/ynghandback-<log>.html"

# Every < in the payload is written `\u003c`, which JSON reads back as
# the same character and no parser can read as a tag (R3.3).
sed 's/</\\u003c/g' "$json" > "$esc"

awk -v data="$esc" '
  { line = $0; sub(/\r$/, "", line) }
  line == "<script type=\"application/json\" id=\"handback-data\"></script>" {
    print "<script type=\"application/json\" id=\"handback-data\">"
    while ((getline payload < data) > 0) print payload
    close(data)
    print "</script>"
    found++
    next
  }
  { print }
  END { exit(found == 1 ? 0 : 1) }' "$tpl" > "$out" && mv "$out" "$page"
```

That `awk` writes no page unless it met the placeholder exactly once:
one substitution, into the element R3.2 names, and never into a second
copy of that tag. When it fails, leave the page and the project index
as they are and go to step 6 with the reason
`template placeholder not found`.

Done when `ynghandback-<log>.html` is the shipped template holding this
run's payload, or nothing was written and step 6 has the reason.

## 5. Open

With `<handback-page>` `open`, open the page:

``` bash
yngv "<root>/.yngaiplaybook/ynghandback-<log>.html"
```

`yngv` is the viewer the installer put on the person's PATH
(yngorchestrator R13); it opens an `.html` file in the default browser
(R13.1, R13.6). When it is not on PATH, or it fails, say so and name
the page's path: the page is written either way, and the person opens
it themselves.

With `write`, open nothing.

Either way, name the page's path in one line beside SKILL.md step
5's list.
That list stays first and stays whole: it is what reaches the person
over Remote Control, where a `file://` path is useless (R1.3).

Done when the page is open, or the person has its path.

## 6. Log the line

One line, and one only, appended to
`<root>/.yngaiplaybook/yngorchestratorruns/<log>.md` in the format
*Run log* in [SKILL.md](SKILL.md) defines, before step 5 of SKILL.md
deletes the lock (R14.5):

``` text
<date> #<n> handback page written
<date> #<n> handback page skipped <reason>
```

| What happened                                     | The event                                                |
|---------------------------------------------------|----------------------------------------------------------|
| the page was written (step 4)                     | `handback page written`                                  |
| `<handback-page>` is `no`                         | `handback page skipped handback-page: no`                |
| a gathered operation failed (step 1)              | `handback page skipped <operation> failed`               |
| the placeholder was not met exactly once (step 4) | `handback page skipped template placeholder not found`   |

Done when the run log holds the line, and step 5 of SKILL.md can delete
the lock.