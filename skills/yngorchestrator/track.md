# Track

Two paths. **On a report** runs once per completion report as it
arrives. **On a merge** runs at every start, after step 1 of
[SKILL.md](SKILL.md), and whenever a person says a slice PR merged.

`<n>` is the slice issue number, `<epic>` the Epic branch. In a
standalone run ([scoped.md](scoped.md)), `<n>` is the standalone
issue, `<epic>` reads as `main`, and the merge path is `fix-to-main`.
Every
command names its target by absolute path, and every `gh` command
carries `-R <owner>/<repo>` (*The project root* in
[SKILL.md](SKILL.md)), so it runs the same from any folder. Every
action below appends one line to the run log, in the format `SKILL.md`
defines; the event to write is given with each action.

You move labels, close issues and remove worktrees. Merging follows
the person's merge rule (Gate 2): when a PR is ready, you label it and
apply that rule through [merge.md](merge.md).

## On a report

### 1. Validate

The report must carry every field of [report.md](report.md), in
order, with STATUS one of its four values. Log `reported <status>`.

When a field is missing or STATUS is unknown, ask the worker once, with
SendMessage, to resend the full report. A second malformed report is
treated as `failed`, cause "malformed report".

Done when you hold a well-formed report, or have classed it `failed`.

### 2. Act on STATUS

**`done`**: confirm the PR is open, targets `<epic>`, and comes from
the slice branch:

``` bash
gh pr view <PR> -R <owner>/<repo> --json state,baseRefName,headRefName
```

Expect `OPEN`, `<epic>`, and the report's BRANCH. On any mismatch,
treat the report as `failed`, cause "PR not open into <epic>". Then:

``` bash
gh issue edit <n> -R <owner>/<repo> --add-label workflow:in-review --remove-label workflow:in-progress
gh issue comment <n> -R <owner>/<repo> --body "In review: <PR>

Open decisions:
<REVIEW RECORD, one per line, or none>"
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

  Log `re-dispatched`.
- Two attempts: hand back to a person.

  ``` bash
  gh issue edit <n> -R <owner>/<repo> --add-label workflow:ready-for-human --remove-label workflow:in-progress
  gh issue comment <n> -R <owner>/<repo> --body "Handed back after two attempts. Last report:

  <the full report>"
  ```

  Log `handed back`.

**`needs-human`**:

``` bash
gh issue edit <n> -R <owner>/<repo> --add-label workflow:ready-for-human --remove-label workflow:in-progress
gh issue comment <n> -R <owner>/<repo> --body "Needs a person: <ISSUES>"
```

Log `ready-for-human`.

Done when the issue's label matches the STATUS row above, its comment
is posted, and the run log has the line.

## On a merge

### 1. Find merged slices

``` bash
gh pr list -R <owner>/<repo> --base <epic> --state merged --json number,url,headRefName
```

Each `headRefName` of the form `slice/<n>-<name>` maps to issue `<n>`.
Keep those whose issue is still open
(`gh issue view <n> -R <owner>/<repo> --json state`).

Done when you have the list of merged slices with open issues, or know
it is empty.

### 2. Refresh the Epic worktree

``` bash
git -C "<epic worktree>" pull
```

### 3. Close each slice

Closing keywords fire only on the default branch (guide section 6,
*Slice completion*), so close the issue explicitly, naming the branch
it landed on:

``` bash
gh issue edit <n> -R <owner>/<repo> --remove-label workflow:in-review
gh issue close <n> -R <owner>/<repo> --comment "Merged into \`<epic>\` by <PR url>. The code is on the Epic branch and reaches main with the Epic."
```

Log `closed`.

### 4. Clean up

Find the slice worktree's absolute path with
`git --git-dir="<root>/.bare" worktree list`, then:

``` bash
git --git-dir="<root>/.bare" worktree remove "<slice worktree>"
git --git-dir="<root>/.bare" branch -d slice/<n>-<name>
```

Log `worktree removed`. When either command refuses (uncommitted
changes, an unmerged branch), leave the worktree and branch in place
and tell the person which command refused and why; they decide whether
to force it.

Done when every merged slice's issue is closed, its worktree and local
branch are gone or reported, and each has its run log lines.
