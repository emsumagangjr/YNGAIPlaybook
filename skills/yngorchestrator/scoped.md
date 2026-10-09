# Run a slice or a standalone issue

A run on a slice handles that slice only (R19); a run on a standalone
issue handles that issue only (R20). You arrive from
[locate.md](locate.md) holding `<root>`, `<owner>/<repo>`, the issue
`<n>`, its title, its kind and, for a slice, its parent `<parent>`.
The run holds its lock (*The lock* in [SKILL.md](SKILL.md)) and writes
its log; this file carries it to its end, and SKILL.md's steps 2 to 5
do not run.

Every command names its target by absolute path, and every `gh`
command carries `-R <owner>/<repo>` (*The project root* in
[SKILL.md](SKILL.md)).

When a step stops the run, tell the person the reason in one sentence,
log it, delete the lock, and end the run. You never apply
`workflow:ready-for-agent`: that label comes only from a person.

| Kind       | Branch             | `PR BASE`        | `SPEC`                       | Merge path      |
|------------|--------------------|------------------|------------------------------|-----------------|
| slice      | `slice/<n>-<name>` | the Epic branch  | the issue's spec section     | `slice-to-epic` |
| standalone | `fix/<n>-<name>`   | `main`           | `none`                       | `fix-to-main`   |

## 1. Read where it stands

An issue at `workflow:in-review` was dispatched by an earlier run, and
its pull request waits. Find it by head branch:

``` bash
gh pr list -R <owner>/<repo> --state all --limit 1000 \
  --json number,state,headRefName,baseRefName,url \
  --jq '.[] | select(.headRefName | test("^(slice|fix)/<n>-")) | [.number, .state, .headRefName, .baseRefName, .url] | @tsv'
```

| Pull request | Go to                                                   |
|--------------|---------------------------------------------------------|
| `OPEN`       | step 6, at [merge.md](merge.md) (the config may have changed) |
| `MERGED`     | step 7                                                  |
| none, or `CLOSED` | stop: the issue says in review, and no pull request waits |

Take `<branch>` from the pull request's head and the `PR BASE` from
its base; `<worktree>` is the path `git --git-dir="<root>/.bare" worktree list`
shows on `<branch>`, if any. The report's `STATUS` is the last
`reported` line for `#<n>` in the run log.

Any other label goes on to step 2.

Done when you know which step the run starts at.

## 2. Check Gate 1

Run step 1 of [dispatch.md](dispatch.md) for `<n>`: the issue carries
`workflow:ready-for-agent`, and a person applied it.

A failure stops the run, before any branch exists: name who applied
the label, or that the issue does not carry it, and log `refused` with
the reason. An issue left at `workflow:in-progress` by a run that
ended fails here too: a person decides whether to promote it again.

Done when the issue has passed Gate 1, or the run has stopped.

## 3. Check the dependencies (a slice only)

Read the issue's `Depends on:` line, written by planning:

``` bash
gh api "repos/<owner>/<repo>/issues/<n>" --jq .body \
  | sed -n 's/^Depends on:[[:space:]]*//p' | head -n 1 | grep -o '#[0-9][0-9]*' | tr -d '#'
```

No line, or no number in it, means no dependency. Each number must be
closed:

``` bash
gh api "repos/<owner>/<repo>/issues/<d>" --jq .state
```

Any one still `open` stops the run, naming each open dependency: the
slice waits for it to merge into the Epic branch. Log `refused` with
them.

Done when every dependency is closed, or the run has stopped.

## 4. Set up the branch and worktree

Follow steps 1 to 4 of [worktree.md](worktree.md), holding the kind:
a slice gets `slice/<n>-<name>` from its Epic branch, a standalone
issue `fix/<n>-<name>` from `origin/main`, with no `epicid`.

Done when you hold `<branch>`, `<worktree>` and, for a slice,
`<epic branch>` and `<epic worktree>` (when the Epic has one).

## 5. Dispatch one worker

Run steps 3 and 4 of [dispatch.md](dispatch.md) for this one issue:
label it `workflow:in-progress`, log `dispatched`, and launch one
`slice-worker` with the prompt filled from the table above:

- **slice**: `SPEC` is the section the issue links,
  `PR BASE` the Epic branch;
- **standalone**: `SPEC: none` and `PR BASE: main`. The issue's
  acceptance criteria are the whole contract.

Done when the worker is running.

## 6. Track and merge

When the report arrives, follow *On a report* in [track.md](track.md),
with `<epic>` read as the issue's `PR BASE`. A `done` report reaches
[merge.md](merge.md) for the kind's merge path; a missing file or key,
or any value but `auto`, is `required`.

- **Merged** by you on `auto`: go to step 7.
- **`required`**, or held: the pull request waits for the person at
  `workflow:in-review`. Go to step 8.
- **Re-dispatched**: wait for the next report, and act on it here.
- **Handed back** (`workflow:ready-for-human`): go to step 8.

Done when the pull request is merged, or waits on a person.

## 7. After the merge

### A slice

Run *On a merge* in [track.md](track.md), steps 2 to 4, for this slice
only: other slices merged into the Epic belong to an Epic run. With no
Epic worktree, skip step 2.

Then name the slices this merge unblocked: the Epic's open slices
whose `Depends on:` names `#<n>` and whose dependencies are now all
closed.

``` bash
gh api "repos/<owner>/<repo>/issues/<parent>/sub_issues" --paginate \
  --jq '.[] | select(.state == "open") | [.number, .title, ([.labels[].name] | join(","))] | @tsv'
```

Read each one's `Depends on:` line as in step 3. List them for the
person with their `workflow:` label, and log `unblocked #<m>` for
each. Do not dispatch them: that is an Epic run
(`/yngorchestrator <parent>`), or a slice run on each.

### A standalone issue

A closing keyword in the pull request may have closed the issue
already. While it is open, close it explicitly:

``` bash
gh issue edit <n> -R <owner>/<repo> --remove-label workflow:in-review
gh issue close <n> -R <owner>/<repo> --comment "Merged into \`main\` by <PR url>."
```

Log `closed`. Remove the worktree and local branch as in step 4 of
*On a merge* in [track.md](track.md), with `fix/<n>-<name>` as the
branch, and log `worktree removed`.

Done when the issue is closed, its worktree and local branch are gone
or reported, and, for a slice, the unblocked slices are named.

## 8. Hand back

Tell the person where the issue stands: merged and closed, with the
slices it unblocked; or its pull request waiting for them (Gate 2),
with the review record's open decisions or the held condition; or
handed back at `workflow:ready-for-human`, with the reason. Once a
person has merged a waiting pull request, `/yngorchestrator <n>`
closes the issue (step 1).

Last, delete the run's lock (*The lock* in [SKILL.md](SKILL.md)).

Done when the person knows where the issue stands and the lock is
gone.
