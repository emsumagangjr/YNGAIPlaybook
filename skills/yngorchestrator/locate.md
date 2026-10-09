# Locate the issue

You find the project root, check that the issue belongs to this
project, and tell what kind of issue it is. Nothing here changes a
branch, a worktree or an issue, except a reopen the person said yes to.

The session may have started at the project root, in any worktree, or
in any folder below one. It stays there: every command below names its
target by absolute path, so the result is the same from each.

When a step stops the run, tell the person the reason in one sentence
and end the run.

## 1. Find the root

`<root>` is the folder holding `.bare/`. Inside a worktree, Git names
it; at the root itself, which is outside Git, the folder is the root:

``` bash
if common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  root=$(dirname "$common")        # <root>/.bare -> <root>
elif [ -d .bare ]; then
  root=$(pwd -P)                   # session started at the root
fi
```

Check `"$root/.bare"` is a folder. When `root` is unset, or Git's
common dir is not a `.bare` folder, stop: the session is not inside a
project laid out as the guide's bare repository and worktrees.

Done when `<root>` is an absolute path whose `.bare/` exists.

## 2. Read the argument

`<issue>` takes three forms:

| Form           | Example                                       | Issue number |
|----------------|-----------------------------------------------|--------------|
| number         | `39`                                          | `39`         |
| `#` and number | `#39`                                         | `39`         |
| URL            | `https://github.com/<owner>/<repo>/issues/39` | `39`         |

Anything else stops the run, a pull request URL (`/pull/39`) included:
the orchestrator runs on issues.

With no argument, and the session inside a worktree, the issue is the
Epic recorded on the current branch:

``` bash
git config --get "branch.$(git branch --show-current).epicid"
```

With no argument at the root, or no `epicid` recorded, ask the person
for the issue.

Done when you hold an issue number `<n>`.

## 3. Check the repository

`origin`'s repository is the project's:

``` bash
git --git-dir="<root>/.bare" remote get-url origin
```

Take `<owner>/<repo>` from it: the last two path parts, without
`.git`, from either `https://github.com/<owner>/<repo>.git` or
`git@github.com:<owner>/<repo>.git`. Every `gh` command of the run
carries `-R <owner>/<repo>`.

A URL argument must name the same `<owner>/<repo>` (compare without
case). Another repository stops the run, naming both.

Read the issue:

``` bash
gh api "repos/<owner>/<repo>/issues/<n>" \
  --jq '{state, state_reason, title, labels: [.labels[].name], pr: (.pull_request != null), subs: .sub_issues_summary.total}'
```

A `404` stops the run: issue `<n>` does not exist in `<owner>/<repo>`.
`pr: true` stops it too: `<n>` is a pull request, not an issue.

Done when the issue exists in `origin`'s repository and you hold its
state, state reason, title, labels and sub-issue count.

## 4. Tell the kind

``` bash
parent=$(gh api "repos/<owner>/<repo>/issues/<n>/parent" --jq .number 2>/dev/null) || parent=
```

Judge by the exit status, not the output: on a `404` (no parent),
`gh` still prints the error body to standard output.

| Signals                                    | Kind           |
|--------------------------------------------|----------------|
| `epic` label, or sub-issues, and no parent | **Epic**       |
| a parent, no `epic` label, no sub-issues   | **slice**      |
| none of them                               | **standalone** |

Any other mix conflicts: an `epic` label or sub-issues together with a
parent. Stop, show the person the signals you found, and ask which
kind the issue is. Continue only on their answer.

Done when the issue has one kind, from the signals or from the person.

## 5. Check the state

An open issue goes on to step 6.

A closed issue is not refused. Show the person its state:

- closed, with its `state_reason`;
- its branch, matching `*/<n>-*`, local or on `origin`:

  ``` bash
  git --git-dir="<root>/.bare" for-each-ref --format='%(refname:short)' \
    "refs/heads/*/<n>-*" "refs/remotes/origin/*/<n>-*"
  ```

- its pull requests, found by head branch (a merged branch may be
  deleted, so match the name, not the ref):

  ``` bash
  gh pr list -R <owner>/<repo> --state all --limit 1000 \
    --json number,state,headRefName,url \
    --jq '.[] | select(.headRefName | test("^[^/]+/<n>-")) | [.number, .state, .headRefName, .url] | @tsv'
  ```

A closed Epic whose slices are still open is inconsistent. Say so, and
list those slices:

``` bash
gh api "repos/<owner>/<repo>/issues/<n>/sub_issues" --paginate \
  --jq '.[] | select(.state == "open") | [.number, .title] | @tsv'
```

Then ask whether to reopen the issue and continue. Only on the
person's yes:

``` bash
gh issue reopen <n> -R <owner>/<repo>
```

Any other answer ends the run with the issue left closed.

Done when the issue is open, or the run has ended with it closed.

## 6. Hand on

The run stays within the issue's boundary:

- **Epic**: the run drives the Epic. Go on with step 1 of
  [SKILL.md](SKILL.md), holding `<root>`, `<owner>/<repo>` and the
  Epic `<n>`;
- **slice**: the run handles that slice only (R19);
- **standalone**: the run handles that issue only (R20).

This skill does not yet run a slice or a standalone issue on its own.
For those two kinds, tell the person the kind you found and stop.

Done when the run continues as an Epic run, or has stopped with the
kind named.
