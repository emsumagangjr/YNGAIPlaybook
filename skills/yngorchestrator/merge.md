# Merge by rule

Gate 2 is a person's decision. They make it per pull request, or in
advance per merge path, in `<root>/.yngorchestrator/config.yml` (see
*The project root* in [SKILL.md](SKILL.md)). This step reads
that decision for one pull request and either merges or hands it to the
person.

`slice-to-epic: auto` is what lets you carry an Epic through on your
own: each merge lands a slice on the Epic branch, which closes it and
unblocks the slices that depend on it, so dispatch continues without
waiting for a person.

## The config

``` yaml
merge:
  slice-to-epic: required   # required | auto
  epic-to-main: required
  fix-to-main: required
```

| Path            | Pull request                      |
|-----------------|-----------------------------------|
| `slice-to-epic` | `slice/*` into its Epic branch    |
| `epic-to-main`  | `epic/*` into `main`              |
| `fix-to-main`   | `fix/*` into `main` (section 16)  |

`required`: a person merges. `auto`: you merge, when every condition in
step 2 holds.

## 1. Read the rule

Read `<root>/.yngorchestrator/config.yml` as it is now, every time. It
lives outside every worktree and branch, so only the person edits it
and no pull request can change it.

The rule is `required` when the file is absent, the path's key is
absent, or its value is anything other than `auto`.

Log `merge rule <path> <rule>`.

Done when you hold `required` or `auto` for this pull request. On
`required`, stop here: the pull request waits for the person at
`workflow:in-review`.

## 2. Check the conditions

`auto` merges only when every one holds:

- the report's `STATUS` is `done` (for `epic-to-main`: every slice
  issue of the Epic is closed);
- the pull request is open, comes from the expected branch, targets the
  expected base, and is mergeable:

  ``` bash
  gh pr view <PR> -R <owner>/<repo> --json state,headRefName,baseRefName,mergeable
  ```

  expecting `OPEN`, the branch, the base, and `MERGEABLE`;
- every check passed, or the pull request has none:

  ``` bash
  gh pr checks <PR> -R <owner>/<repo>
  ```

- the review record is "none": an open decision is the person's.

When any one fails, the pull request is `required` after all. Comment
the reason on it
(`gh pr comment <PR> -R <owner>/<repo> --body "Auto-merge held: <condition>"`), log
`merge held <condition>`, and stop.

Done when every condition holds, or the pull request is held with its
reason.

## 3. Merge

Merge with a merge commit (the guide merges rather than rebases shared
branches) and delete the head branch:

``` bash
gh pr merge <PR> -R <owner>/<repo> --merge --delete-branch
```

Log `merged <PR> auto`. In an Epic run, for a slice, run the *On a
merge* path of [track.md](track.md) now: it closes the issue and
removes the worktree. A slice or standalone run goes on with step 7 of
[scoped.md](scoped.md), which does the same for its one issue.

Done when the pull request shows `MERGED` and its issue is closed.
