# Dispatch a slice

Run steps 1 to 3 for each slice in turn, then step 4 once for all of
them. Every command names its target by absolute path (*The project
root* in [SKILL.md](SKILL.md)), so the session's own folder does not
matter. Every command here is an issue command: `gh` carries
`-R <issues repo>` (*Two repositories* in [SKILL.md](SKILL.md)).

## 1. Check provenance (Gate 1)

The issue must carry `workflow:ready-for-agent` now, and a person must
have promoted it: by applying the label, or, with `<auto-promote>`
`yes`, by approving the plan that created it ([plan.md](plan.md)).
Read who applied the label from the issue timeline:

``` bash
gh api repos/<issues repo>/issues/<n>/timeline --paginate \
  --jq '.[] | select(.event=="labeled" and .label.name=="workflow:ready-for-agent")
        | [.actor.login, .actor.type, (.performed_via_github_app.slug // "-"), .created_at] | @tsv'
```

Events come oldest first, so the last line is the application that
counts. It passes when either route holds.

**A person's label.** All three hold:

- `actor.type` is `User`;
- the login is no bot account (none ending in `[bot]`);
- `performed_via_github_app` is empty (`-`).

When the run log `<log>` has a `promoted by plan approval` line for
`#<n>`, the first application on the timeline is the one this
orchestrator made when it created the slice, not a person's, even
though it may read as theirs. This route then counts only a later
application.

**Plan approval** (R36.2). All four hold:

- `<auto-promote>` is `yes` now, as read at the start of this run;
- the issue is a sub-issue of the Epic being run, so its parent is
  `<log>` (the parent is read as in step 4 of [locate.md](locate.md);
  a standalone run's `<log>` is the issue itself, which has no
  parent);
- `<root>/.yngaiplaybook/yngorchestratorruns/<log>.md` has the line
  `<date> #<n> promoted by plan approval`:

  ``` bash
  grep -Eq "^[^ ]+ #<n> promoted by plan approval$" \
    "<root>/.yngaiplaybook/yngorchestratorruns/<log>.md"
  ```

- the timeline shows exactly one application of the label: the one
  made at creation. A label applied again later, after a dispatch or
  a hand-back, is judged by the person's-label route alone.

A standalone issue, or a slice created by hand, has no such line: it
passes only by a person's label, whatever `<auto-promote>` says. With
`<auto-promote>` `no`, this route is closed and the line counts for
nothing (R36.3-4). On a pass by plan approval, log
`gate 1 by plan approval`.

On a failure, leave the slice untouched: tell the person the issue, who
applied the label and why it failed, log `refused` with that reason,
and move to the next slice. A slice or standalone run
([scoped.md](scoped.md)) has no next slice: it stops.

This check sees accounts, not intent. When you act through the person's
own token, a label you applied reads as theirs and passes, which is why
you never apply `workflow:ready-for-agent` yourself: that label comes
only from a person. The one exception is [plan.md](plan.md) creating
an approved agent slice with `<auto-promote>` `yes`, and that
application passes only by the plan-approval route above, never as a
person's label.

Done when the slice has passed, or been refused and reported.

## 2. Create the worktree

A slice or standalone run skips this step: [worktree.md](worktree.md)
has already set up its branch and worktree.

Name the branch `slice/<n>-<name>` and the directory
`epic<epic n>-slice<n>-<name>` (R43), where `<epic n>` is the number
of the Epic being run, the slice's parent issue, never read from the
Epic worktree's folder name, and `<name>` is a short kebab-case form of
the slice's outcome. Both numbers are unpadded, as the branches write
them. Branch from the Epic branch and record the Epic on the branch:

``` bash
git --git-dir="<root>/.bare" worktree add -b slice/<n>-<name> "<root>/epic<epic n>-slice<n>-<name>" <epic branch>
git --git-dir="<root>/.bare" config branch.slice/<n>-<name>.epicid <epic n>
```

Record the new branch on the slice's issue, as in *Nowhere* in step 4
of [worktree.md](worktree.md) (R44.1): a `Branch:` line after a blank
line at the end of its body, unless the body already has one.

``` bash
body=$(gh api "repos/<issues repo>/issues/<n>" --jq '.body // ""')
if ! printf '%s\n' "$body" | grep -q '^Branch:'; then
  printf '%s\n\nBranch: `%s`\n' "$body" "slice/<n>-<name>" \
    | gh issue edit <n> -R <issues repo> --body-file -
fi
```

When the project root has a `.shared/` folder, link its files into the
new worktree with the `yngshared` script beside `.bare/` (the guide's
*Shared private files* section has the manual loop when it is absent):

``` powershell
& "<root>\yngshared.ps1" -link "<root>\epic<epic n>-slice<n>-<name>"     # Windows
```

``` bash
"<root>/yngshared.sh" --link "<root>/epic<epic n>-slice<n>-<name>"       # macOS/Linux
```

Done when `git --git-dir="<root>/.bare" worktree list` shows the
worktree on its slice branch,
`git --git-dir="<root>/.bare" config --get branch.slice/<n>-<name>.epicid`
prints the Epic, and the issue body has a `Branch:` line.

## 3. Hand it out

``` bash
gh issue edit <n> -R <issues repo> --add-label workflow:in-progress --remove-label workflow:ready-for-agent
```

Then comment on the issue, naming the branch and the worktree's folder
(R44.2). `<branch>` is the slice's branch (step 2), or, in a slice or
standalone run, the one [worktree.md](worktree.md) set up; `<folder>`
is the worktree's folder name below `<root>`, not its full path:

``` bash
gh issue comment <n> -R <issues repo> --body 'Dispatched: branch `<branch>`, worktree `<folder>`'
```

The comment goes on every dispatch, in Epic, slice and standalone runs
alike, and again on a re-dispatch ([track.md](track.md)).

Log `dispatched` to the run log.

Done when the issue shows `workflow:in-progress` alone among its
`workflow:` labels and carries this dispatch's `Dispatched:` comment.

## 4. Launch the workers

Fill one prompt per slice from this template. Every value comes from
the issue and from step 2; the worker reads nothing else to start.

``` text
ISSUE:        <issues repo>#<n> <title>
CRITERIA:     <the issue's acceptance criteria, verbatim>
SPEC:         docs/specs/<feature>/requirements.md, section <Rn>
WORKTREE:     <root>/epic<epic n>-slice<n>-<name>, as an absolute path
BRANCH:       slice/<n>-<name>
PR BASE:      <the Epic branch>
LEAD-IN:      diagnose | design the seam | none
REPORT:       <absolute path of skills/yngorchestrator/report.md>
```

`ISSUE` carries the full reference, `<issues repo>#<n>`, even when the
issues repo is the code repo: the worker reads the issue with `-R` from
it, and names it so in its commits and pull request.

A standalone run ([scoped.md](scoped.md)) fills `SPEC: none`,
`PR BASE: main`, and its `fix/<n>-<name>` branch and worktree: the
issue's acceptance criteria are the whole contract.

`LEAD-IN` is `diagnose` for a bug, `design the seam` for a refactor and
`none` otherwise, unless the issue's `Lead-in:` line (written by
planning) names a different one.

Launch each as a `slice-worker` subagent (Claude Code: the Agent tool
with `subagent_type: slice-worker`, the filled template as `prompt`).
Put every launch for this round in one message, so independent slices
run in parallel. Each worker's final message is its completion report;
step 4 of `SKILL.md` acts on it.

Done when every slice handed out in step 3 has a worker running.
