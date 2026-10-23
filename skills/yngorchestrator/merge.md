# Merge by rule

Gate 2 is a person's decision. They make it per pull request, or in
advance per merge path, in
`<root>/.yngaiplaybook/yngorchestratorconfig.yml` (see
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

Read `<root>/.yngaiplaybook/yngorchestratorconfig.yml` as it is now,
every time, and no other file: a `config.yml` left in an older
`<root>/.yngorchestrator/` or `<root>/.orchestrator/` is never read. It
lives outside every worktree and branch, so only the person edits it
and no pull request can change it.

The rule is `required` when the file is absent, the path's key is
absent, or its value is anything other than `auto`.

Log `merge rule <path> <rule>`.

Done when you hold `required` or `auto` for this pull request. On
`required`, stop here: the pull request waits for the person at
`workflow:in-review`.

## 2. Check the conditions

Read the pull request with *pr status* first, on every provider
(R13.1). `auto` merges only when every one holds:

- the report's `STATUS` is `done` (for `epic-to-main`: every slice
  issue of the Epic is closed);
- the pull request is `OPEN`, its head is the expected branch, its base
  the expected base, and it is mergeable (`yes`);
- its checks are `passed`, or `none`: every check or pipeline passed,
  or the pull request has none;
- the review record is "none": an open decision is the person's.

When any one fails, the pull request is `required` after all. *Comment*
the reason on the pull request (`Auto-merge held: <condition>`), log
`merge held <condition>`, and stop.

Done when every condition holds, or the pull request is held with its
reason.

## 3. Merge

*Merge pr*: a merge commit (the guide merges rather than rebases shared
branches), and the head branch deleted (R13.2).

Log `merged <PR> auto`. In an Epic run, for a slice, run the *On a
merge* path of [track.md](track.md) now: it closes the issue and
removes the worktree. A slice or standalone run goes on with step 7 of
[scoped.md](scoped.md), which does the same for its one issue.

For `epic-to-main`, *read issue* for the Epic. The pull request's
closing reference closes it where the provider can; while it is still
open, *close* it with the comment ``Merged into `main` by <PR url>.``
(R12.2), and log `closed`.

Done when the pull request shows `MERGED` and its issue is closed.
