# Track

Two paths. **On a report** runs once per completion report as it
arrives. **On a merge** runs at every start, after step 1 of
[SKILL.md](SKILL.md), and whenever a person says a slice PR merged.

`<n>` is the slice issue number, `<epic>` the Epic branch. In a
standalone run ([scoped.md](scoped.md)), `<n>` is the standalone
issue, `<epic>` reads as `main`, and the merge path is `fix-to-main`.
Every
command names its target by absolute path, and every operation (*The
provider* in [SKILL.md](SKILL.md)) targets `<issues repo>` for an issue
or `<code repo>` for a pull request (*Two repositories*), so it runs the
same from any folder. Every
action below appends one line to the run log, in the format `SKILL.md`
defines; the event to write is given with each action.

You move states, close issues and remove worktrees. Merging follows
the person's merge rule (Gate 2): when a PR is ready, you label it and
apply that rule through [merge.md](merge.md).

## On a report

### 1. Drain, then validate

A worker's message has reached you, so drain every open progress
channel first (*Interim reports* in [SKILL.md](SKILL.md)): this
slice's last interim reports reach the log, and the board, ahead of
the report that ends them, and the slices still out get theirs logged
while their workers are still working. This slice's own channel is
closed at the end of step 2, once you have acted on the report.

The report must carry every field of *Completion report* in
[report.md](report.md), in order, with STATUS one of its four values.
Log `reported <status>`.

When a field is missing or STATUS is unknown, ask the worker once, with
SendMessage, to resend the full report. A second malformed report is
treated as `failed`, cause "malformed report".

Done when you hold a well-formed report, or have classed it `failed`.

### 2. Act on STATUS

**`done`**: confirm the PR is open, targets `<epic>`, and comes from
the slice branch, with *pr status*: expect `OPEN`, the base `<epic>`,
and the head the report's BRANCH. On any mismatch, treat the report as
`failed`, cause "PR not open into <epic>". Then *set state*
`workflow:in-review`, and *comment* on the issue:

``` text
In review: <PR>

Open decisions:
<REVIEW RECORD, one per line, or none>
```

Log `in-review <PR>`. Then follow [merge.md](merge.md) for the
`slice-to-epic` path (`fix-to-main` in a standalone run).

**`blocked` / `failed`**: count the slice's `dispatched` and
`re-dispatched` lines in the run log.

- One attempt so far: re-dispatch into the same worktree and branch,
  with the dispatch prompt from [dispatch.md](dispatch.md) plus one
  added field carrying what the first attempt learned:

  ``` text
  PREVIOUS:     STATUS, ISSUES and COMMITS of the last report, and what
                you can add (a dependency now merged, a decision made)
  ```

  Post the `Dispatched:` comment again, as in step 3 of
  [dispatch.md](dispatch.md), naming the same branch and worktree
  folder (R44.2). Open a fresh progress channel for the new attempt
  and name it in `PROGRESS:` (step 4 of [dispatch.md](dispatch.md)):
  what the first attempt reported is not this one's (yngboard R14.5).
  Log `re-dispatched`, with the UTC instant that line carries (*Run
  log* in [SKILL.md](SKILL.md)).
- Two attempts: hand back to a person. *Set state*
  `workflow:ready-for-human`, and *comment* on the issue:

  ``` text
  Handed back after two attempts. Last report:

  <the full report>
  ```

  Log `handed back`.

**`needs-human`**: *set state* `workflow:ready-for-human`, and
*comment* on the issue `Needs a person: <ISSUES>`.

Log `ready-for-human`.

Delete this attempt's progress channel last, whichever row acted: the
slice is in flight no longer, or a re-dispatch has opened a fresh one
(*Interim reports* in [SKILL.md](SKILL.md)).

Done when the issue's state matches the STATUS row above, its comment
is posted, the run log has the line, and this attempt's channel is
gone.

## On a merge

### 1. Find merged slices

*List prs* for the head `^slice/[0-9]+-`, keeping those `MERGED`
into the base `<epic>`. Each head of the form `slice/<n>-<name>` maps
to issue `<n>`. Keep those whose issue is still open (*read issue*).

Done when you have the list of merged slices with open issues, or know
it is empty.

### 2. Refresh the Epic worktree

``` bash
git -C "<epic worktree>" pull
```

### 3. Close each slice

Closing keywords fire only on the default branch (guide section 6,
*Slice completion*), so close the issue explicitly (R12.2), naming the
branch it landed on: *set state* `none`, then *close* with the
comment:

``` text
Merged into `<epic>` by <PR url>. The code is on the Epic branch and reaches main with the Epic.
```

Log `closed`.

### 4. Clean up

Find the slice worktree's absolute path with
`git --git-dir="<root>/.bare" worktree list`, as `<slice worktree>`.

**A run sitting in it defers the removal** (R61.1). A run in its own
instance sits in the worktree it would remove, and the instance stays
open after the hand-back, holding the folder (Windows refuses to remove
a folder in use). The session sits in it when the worktree holding the
session's folder is `<slice worktree>`; Git prints both paths in the
same form:

``` bash
[ "$(git rev-parse --show-toplevel 2>/dev/null)" = "<slice worktree>" ] && echo inside
```

On `inside`, do not run the commands below. Log
`worktree removal deferred <slice worktree>`, and tell the person the
worktree and its local branch are removed by a later run started
outside it: `/yngorchestrator continue`, a bare `/yngorchestrator`, or
an Epic run (*Sweep deferred removals* below).

**Any other run removes it at once**:

``` bash
git --git-dir="<root>/.bare" worktree remove "<slice worktree>"
git --git-dir="<root>/.bare" branch -d slice/<n>-<name>
```

Log `worktree removed`. When either command refuses (uncommitted
changes, an unmerged branch), leave the worktree and branch in place
and tell the person which command refused and why; they decide whether
to force it.

Done when every merged slice's issue is closed, its worktree and local
branch are gone, reported or deferred, and each has its run log lines.

## Sweep deferred removals

Runs in a session that is not in a deferred worktree (R61.2): every
`/yngorchestrator continue` and bare `/yngorchestrator`, from step 2
of [locate.md](locate.md), and every Epic run, in step 1 of
[SKILL.md](SKILL.md). It needs only `<root>`: no provider, no issue.

### 1. Find the deferred removals

A removal is deferred while a run log holds a
`#<n> worktree removal deferred <path>` line with no later
`#<n> worktree removed` line. Read every log:

``` bash
for log in "<root>/.yngaiplaybook/yngorchestratorruns"/*.md; do
  [ -f "$log" ] || continue
  awk -v name="$(basename "$log" .md)" '
    / worktree removal deferred / { p = $0; sub(/.* worktree removal deferred /, "", p); d[$2] = p; next }
    / worktree removed$/          { delete d[$2] }
    END { for (n in d) print name "\t" n "\t" d[n] }' "$log"
done
```

Each line is `<log>`, `#<n>` and the worktree's `<path>`. Skip one
whose `<path>` holds the session (the check in step 4 of *On a merge*
above): this session is the one sitting in it.

Done when you hold the deferred removals, or know there are none.

### 2. Remove each one

For each `<log>`, only while `yngorchestratorruns/<log>.lock` is
absent: a lock means a run is working on that log, so its removals
wait for the next sweep. Take that lock as *The lock* in
[SKILL.md](SKILL.md) says, so no run starts on the log while you write
it, and delete it once that log's removals are done. A lock this run
already holds (an Epic run sweeping its own log) counts as absent, and
stays held.

For each of the log's removals, take the branch from the worktree in
`git --git-dir="<root>/.bare" worktree list --porcelain` (its
`branch refs/heads/<branch>` line), and remove both as step 4 of *On a
merge* does:

``` bash
git --git-dir="<root>/.bare" worktree remove "<path>"
git --git-dir="<root>/.bare" branch -d <branch>
```

Append `<date> #<n> worktree removed` to `yngorchestratorruns/<log>.md`.

A `<path>` the list no longer shows is no longer a worktree: removed
by hand, or by an earlier removal Windows refused, which unregisters
the worktree and deletes its files but leaves the folder it could not
delete. Remove that leftover folder, empty only, and the local branch,
`slice/<n>-` or `fix/<n>-` as `git --git-dir="<root>/.bare" branch
--list` shows it, each only if it is still there:

``` bash
[ -d "<path>" ] && rmdir "<path>"
git --git-dir="<root>/.bare" branch -d <branch>
```

Then log `worktree removed` the same way.

When any command refuses (the instance still holds the folder,
uncommitted changes, an unmerged branch, a leftover folder not empty),
log nothing: the removal stays deferred, and the next sweep tries
again (R61.3). Never force a removal. Tell the person which worktree,
which command refused and why; for a folder in use, that closing the
run's instance lets the next sweep remove it.

Done when every deferred removal whose log was free is removed, or
reported and still deferred, and every lock the sweep took is gone.

## A label and a report that disagree

A run that stops between a worker's report and the *set state* it
calls for leaves a slice whose `workflow:*` label and whose last
report in the run log describe different things (ynghandback R7.1).
Only a person can say which is right, so the slice's row on the run
board carries `conflict` ([board.md](board.md)).

These are the pairs that agree. Each row is a slice's last `reported`
line in the run log — its value is the completion report's `STATUS`
([report.md](report.md)) — the line *On a report* writes next when it
acts on that report, and the label that then agrees with both:

| Last `reported` line                                  | The line that follows it | The label that agrees                                             |
|-------------------------------------------------------|--------------------------|-------------------------------------------------------------------|
| `reported done`                                       | `in-review <PR>`         | `workflow:in-review`, or none once the merge has closed the issue |
| `reported blocked`, `reported failed`, first attempt  | `re-dispatched`          | `workflow:in-progress`                                            |
| `reported blocked`, `reported failed`, second attempt | `handed back`            | `workflow:ready-for-human`                                        |
| `reported needs-human`                                | `ready-for-human`        | `workflow:ready-for-human`                                        |

They disagree when either holds:

1. the slice's last `reported` line is followed by none of the lines
   above: a run stopped between the report and the *set state* it
   calls for;
2. the slice's last such line and the issue's `workflow:*` label name
   different states: the label was changed outside the run.

The **label wins**: it is the provider's record and the gate's audit
trail, and the only thing that can be authoritative (R7.2). Act on it,
here and everywhere else. The report is neither silently dropped nor
silently preferred: it is shown beside the label, with the date of its
run-log line (R7.3), and the disagreement is the slice's `conflict`
value on the board (R7.4).

Done when a slice whose readings disagree is known to be a `conflict`
row, and the run has acted on its label.
