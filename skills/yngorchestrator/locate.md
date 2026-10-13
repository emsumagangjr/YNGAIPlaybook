# Locate the issue

You find the project root, resolve its code repo and issues repo,
check that the issue belongs to this project, and tell what kind of
issue it is. Nothing here changes a branch, a worktree or an issue,
except a reopen the person said yes to.

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

Then check the root has been migrated to `<root>/.yngaiplaybook/`
(R25). Test only whether the folders exist; open nothing in them:

``` bash
if [ ! -d "$root/.yngaiplaybook" ] &&
   { [ -d "$root/.yngorchestrator" ] || [ -d "$root/.orchestrator" ]; }; then
  echo "unmigrated"
fi
```

On `unmigrated`, stop before the lock, before reading the issue, and
before touching anything. Name the old folder you found, and tell the
person to re-run `yngorch` (`.ps1` or `.sh`) from the playbook: it
moves the config and the run logs into `<root>/.yngaiplaybook/`. Then
they start the run again. Never move, copy or read the old folder
yourself.

A root with neither folder is a fresh install: go on. The config is
then absent (every merge path `required`), and the lock step creates
`yngorchestratorruns/`.

Done when `<root>` is an absolute path whose `.bare/` exists, and the
root holds `.yngaiplaybook/` or no older folder.

## 2. Read the argument

`<issue>` takes three forms:

| Form           | Example                                       | Issue number |
|----------------|-----------------------------------------------|--------------|
| number         | `39`                                          | `39`         |
| `#` and number | `#39`                                         | `39`         |
| URL            | `https://github.com/<owner>/<repo>/issues/39` | `39`         |

Anything else stops the run, a pull request URL (`/pull/39`) included:
the orchestrator runs on issues. A number is the issues repo's; step 3
checks the repository a URL names.

With no argument, and the session inside a worktree, the issue is the
Epic recorded on the current branch:

``` bash
git config --get "branch.$(git branch --show-current).epicid"
```

With no argument at the root, or no `epicid` recorded, ask the person
for the issue.

Done when you hold an issue number `<n>`.

## 3. Resolve the repositories

The run works in two repositories (*Two repositories* in
[SKILL.md](SKILL.md)). Resolve both here, before the lock, and hold
them for the run.

**The code repo** is `origin`'s repository:

``` bash
git --git-dir="<root>/.bare" remote get-url origin
```

Take `<code repo>` from it: the last two path parts, without `.git`,
from either `https://github.com/<owner>/<repo>.git` or
`git@github.com:<owner>/<repo>.git`.

**The issues repo** is the config's top-level `issues:` key, read now,
at the start of every run, from
`<root>/.yngaiplaybook/yngorchestratorconfig.yml` and no other file.
Take the value without a trailing comment, surrounding quotes or
spaces:

``` bash
issues=$(sed -n 's/^issues:[[:space:]]*//p' \
    "<root>/.yngaiplaybook/yngorchestratorconfig.yml" 2>/dev/null | head -n 1 |
  sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//; s/^["'\'']\(.*\)["'\'']$/\1/')
```

| `issues:`                                   | `<issues repo>`               |
|---------------------------------------------|-------------------------------|
| no file, no key, or an empty value          | `<code repo>`                 |
| `<code repo>` itself (compared without case) | `<code repo>`                 |
| any other `<owner>/<repo>`                  | that value                    |
| anything else                               | stop                          |

`<owner>/<repo>` means two non-empty parts joined by one `/`, each of
letters, digits, `-`, `_` and `.`:

``` bash
printf '%s\n' "$issues" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'
```

A value that fails this stops the run before the lock, before reading
the issue, and before touching anything: name the value and the config
file, and tell the person to correct or remove the key.

From here every issue command carries `-R <issues repo>` and every code
command `-R <code repo>`; no `gh` call is left to its default. Without
an `issues:` value the two are the same repository, and the run is
what it was before the key existed.

**The Gate 1 setting**, `<auto-promote>`, is the config's top-level
`auto-promote:` key, read now from the same file, at the start of
every run (R33). It is the person's advance decision on Gate 1, as
`merge:` is on Gate 2 ([merge.md](merge.md)); the two never stand in
for each other. Take the value as for `issues:`:

``` bash
ap=$(sed -n 's/^auto-promote:[[:space:]]*//p' \
    "<root>/.yngaiplaybook/yngorchestratorconfig.yml" 2>/dev/null | head -n 1 |
  sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//; s/^["'\'']\(.*\)["'\'']$/\1/')
case "$(printf '%s' "$ap" | tr '[:upper:]' '[:lower:]')" in
  yes|true) autopromote=yes ;;
  *)        autopromote=no ;;
esac
```

`yes` or `true`, in any case, is `yes`. No file, no key, an empty
value or any other value is `no`, and never stops the run: with `no`
the run is what it was before the key existed. Hold `<auto-promote>`
for the whole run; a change to the file takes effect at the next run.
It decides two things only: how [plan.md](plan.md) labels the slices
it creates, and whether step 1 of [dispatch.md](dispatch.md) accepts a
plan promotion.

**A URL argument** must name the issues repo (compare without case).
A URL naming any other repository, the code repo included when it
differs, stops the run, naming both the URL's repository and the
issues repo.

Read the issue:

``` bash
gh api "repos/<issues repo>/issues/<n>" \
  --jq '{state, state_reason, title, labels: [.labels[].name], pr: (.pull_request != null), subs: .sub_issues_summary.total}'
```

A `404` stops the run: issue `<n>` does not exist in `<issues repo>`.
`pr: true` stops it too: `<n>` is a pull request, not an issue.

Done when you hold `<code repo>`, `<issues repo>` and
`<auto-promote>`, the issue exists
in the issues repo, and you hold its state, state reason, title,
labels and sub-issue count.

## 4. Tell the kind

``` bash
parent=$(gh api "repos/<issues repo>/issues/<n>/parent" --jq .number 2>/dev/null) || parent=
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
  gh pr list -R <code repo> --state all --limit 1000 \
    --json number,state,headRefName,url \
    --jq '.[] | select(.headRefName | test("^[^/]+/<n>-")) | [.number, .state, .headRefName, .url] | @tsv'
  ```

A closed Epic whose slices are still open is inconsistent. Say so, and
list those slices:

``` bash
gh api "repos/<issues repo>/issues/<n>/sub_issues" --paginate \
  --jq '.[] | select(.state == "open") | [.number, .title] | @tsv'
```

Then ask whether to reopen the issue and continue. Only on the
person's yes:

``` bash
gh issue reopen <n> -R <issues repo>
```

Any other answer ends the run with the issue left closed.

Done when the issue is open, or the run has ended with it closed.

## 6. Hand on

The run stays within the issue's boundary:

- **Epic**: the run drives the Epic. Follow
  [worktree.md](worktree.md), holding `<root>`, `<code repo>`,
  `<issues repo>`, `<auto-promote>`, the Epic `<n>` and its title: it finds or creates
  the Epic branch and worktree, checks the spec, and hands on to step
  1 of [SKILL.md](SKILL.md);
- **slice**: the run handles that slice only (R19);
- **standalone**: the run handles that issue only (R20).

For a slice or a standalone issue, follow [scoped.md](scoped.md),
holding `<root>`, `<code repo>`, `<issues repo>`, `<auto-promote>`,
`<n>`, its title, its kind and, for a slice, its parent. It checks Gate 1 before it
reaches [worktree.md](worktree.md), so no branch is created for an
issue a person has not promoted.

Done when the run continues as an Epic run, a slice run or a
standalone run.
