# Dispatch a slice

Run steps 1 to 3 for each slice in turn, then step 4 once for all of
them. Every command names its target by absolute path (*The project
root* in [SKILL.md](SKILL.md)), so the session's own folder does not
matter.

## 1. Check provenance (Gate 1)

The issue must carry `workflow:ready-for-agent` now, and a person must
have applied it. Read who applied it from the issue timeline:

``` bash
gh api repos/<owner>/<repo>/issues/<n>/timeline --paginate \
  --jq '.[] | select(.event=="labeled" and .label.name=="workflow:ready-for-agent")
        | [.actor.login, .actor.type, (.performed_via_github_app.slug // "-"), .created_at] | @tsv'
```

Events come oldest first, so the last line is the application that
counts. It passes when all three hold:

- `actor.type` is `User`;
- the login is no bot account (none ending in `[bot]`);
- `performed_via_github_app` is empty (`-`).

On a failure, leave the slice untouched: tell the person the issue, who
applied the label and why it failed, log `refused` with that reason,
and move to the next slice. A slice or standalone run
([scoped.md](scoped.md)) has no next slice: it stops.

This check sees accounts, not intent. When you act through the person's
own token, a label you applied reads as theirs and passes, which is why
you never apply `workflow:ready-for-agent` yourself: that label comes
only from a person.

Done when the slice has passed, or been refused and reported.

## 2. Create the worktree

A slice or standalone run skips this step: [worktree.md](worktree.md)
has already set up its branch and worktree.

Name the branch `slice/<n>-<name>` and the directory
`slice-<epic>-<name>`, where `<epic>` is the Epic worktree's name
without `epic-` and `<name>` is a short kebab-case form of the slice's
outcome. Branch from the Epic branch and record the Epic on the branch:

``` bash
git --git-dir="<root>/.bare" worktree add -b slice/<n>-<name> "<root>/slice-<epic>-<name>" <epic branch>
git --git-dir="<root>/.bare" config branch.slice/<n>-<name>.epicid <epic n>
```

When the project root has a `.shared/` folder, link its files into the
new worktree with the `yngshared` script beside `.bare/` (the guide's
*Shared private files* section has the manual loop when it is absent):

``` powershell
& "<root>\yngshared.ps1" -link "<root>\slice-<epic>-<name>"     # Windows
```

``` bash
"<root>/yngshared.sh" --link "<root>/slice-<epic>-<name>"       # macOS/Linux
```

Done when `git --git-dir="<root>/.bare" worktree list` shows the
worktree on its slice branch and
`git --git-dir="<root>/.bare" config --get branch.slice/<n>-<name>.epicid`
prints the Epic.

## 3. Hand it out

``` bash
gh issue edit <n> -R <owner>/<repo> --add-label workflow:in-progress --remove-label workflow:ready-for-agent
```

Log `dispatched` to the run log.

Done when the issue shows `workflow:in-progress` alone among its
`workflow:` labels.

## 4. Launch the workers

Fill one prompt per slice from this template. Every value comes from
the issue and from step 2; the worker reads nothing else to start.

``` text
ISSUE:        #<n> <title>
CRITERIA:     <the issue's acceptance criteria, verbatim>
SPEC:         docs/specs/<feature>/requirements.md, section <Rn>
WORKTREE:     <root>/slice-<epic>-<name>, as an absolute path
BRANCH:       slice/<n>-<name>
PR BASE:      <the Epic branch>
LEAD-IN:      diagnose | design the seam | none
REPORT:       <absolute path of skills/yngorchestrator/report.md>
```

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
