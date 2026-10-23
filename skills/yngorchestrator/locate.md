# Locate the issue

You find the project root, read its provider and host, resolve its
code repo and issues repo,
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

A URL is an issue's web address on the provider (the provider file's
*Issue URL*): `https://<url host>/<url repo>/issues/<n>`, where GitLab
puts `/-` before `/issues`, and Bitbucket's browser address adds a
title slug after the number (`/issues/39/fix-the-login-page`). Drop
that slug, then split the URL without knowing the provider yet:

``` bash
url=$(printf '%s\n' "$arg"      | sed -E 's#^(https://bitbucket\.org/[^/]+/[^/]+/issues/[0-9]+)/[^/]+/?$#\1#')
url_n=$(printf '%s\n' "$url"    | sed -nE 's#^https://[^/]+/.+/issues/([0-9]+)/?$#\1#p')
url_host=$(printf '%s\n' "$url" | sed -nE 's#^https://([^/]+)/.+/issues/[0-9]+/?$#\1#p')
url_repo=$(printf '%s\n' "$url" | sed -nE 's#^https://[^/]+/(.+)/issues/[0-9]+/?$#\1#p' | sed 's#/-$##')
```

Anything else stops the run, a pull request URL (`/pull/39`,
`/-/merge_requests/39`, `/pull-requests/39`) included: the
orchestrator runs on issues. A number is the issues repo's; step 3
checks the host and repository a URL names.

With no argument, and the session inside a worktree, the issue is the
Epic recorded on the current branch:

``` bash
git config --get "branch.$(git branch --show-current).epicid"
```

With no argument at the root, or no `epicid` recorded, ask the person
for the issue.

Done when you hold an issue number `<n>`.

## 3. Resolve the provider and the repositories

The run works through one provider, on one host, in two repositories
(*The provider* and *Two repositories* in [SKILL.md](SKILL.md)).
Resolve them here, before the lock, and hold them for the run.

Every key below is a top-level key of
`<root>/.yngaiplaybook/yngorchestratorconfig.yml`, read now, at the
start of every run, from that file and no other. Take a value without
a trailing comment, surrounding quotes or spaces:

``` bash
cfg="<root>/.yngaiplaybook/yngorchestratorconfig.yml"
value() {
  sed -n "s/^$1:[[:space:]]*//p" "$cfg" 2>/dev/null | head -n 1 |
    sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//; s/^["'\'']\(.*\)["'\'']$/\1/'
}
```

**The provider**, `<provider>`, is `provider:`, in lower case; no file,
no key or an empty value is `github` (R14.1). The supported providers
are the provider files beside this skill, `<skill>` being the folder
that holds this file and [SKILL.md](SKILL.md):

``` bash
provider=$(value provider | tr '[:upper:]' '[:lower:]'); provider=${provider:-github}
supported=$(ls "<skill>/providers" | sed -n 's/\.md$//p' | grep -vix readme | tr '\n' ' ')
printf '%s\n' $supported | grep -qx -- "$provider"
```

A provider with no file stops the run before the lock, before reading
the issue, and before touching anything: name the value, the config
file and the supported list (R2.2). Otherwise load
`<skill>/providers/<provider>.md`, the run's **provider file**, and no
other provider's file (R7.2). Its *Facts* and operations hold for the
whole run.

**The host**, `<host>`, is `host:`; no key or an empty value is the
provider file's *Cloud host* (R14.1). A host is a name with an
optional port, no scheme and no path:

``` bash
host=$(value host); host=${host:-<the provider file's cloud host>}
printf '%s\n' "$host" | grep -Eq '^[A-Za-z0-9.-]+(:[0-9]+)?$'
```

A value that fails this stops the run before the lock, naming it and
the config file.

**The code repo** is `origin`'s repository:

``` bash
git --git-dir="<root>/.bare" remote get-url origin
```

Take `<code repo>` from it: the whole path after the host, without
`.git`, from either the HTTPS form (`https://<host>/<path>.git`, an
optional user before the host) or the SSH form
(`git@<host>:<path>.git`, `ssh://git@<host>[:port]/<path>.git`):

``` bash
code=$(git --git-dir="<root>/.bare" remote get-url origin |
  sed -E 's#^[a-z+]+://([^@/]+@)?[^/]+/##; s#^[^@/:]+@[^:/]+:##; s#\.git$##; s#/$##')
```

On GitLab the path keeps every subgroup (`<group>/<subgroup>/<project>`).
A path that fails the provider file's *Path form*, its `grep -E`
pattern held as `$form` (`printf '%s\n' "$code" | grep -Eq -- "$form"`),
stops the run: name
`origin`'s URL and the provider.

**The issues repo** is `issues:` (`issues=$(value issues)`):

| `issues:`                                    | `<issues repo>`               |
|----------------------------------------------|-------------------------------|
| no file, no key, or an empty value           | `<code repo>`                 |
| `<code repo>` itself (compared without case) | `<code repo>`                 |
| any other path in the provider's form        | that value                    |
| anything else                                | stop                          |

The form is the provider file's *Path form* (R11.2), `<owner>/<repo>`
on GitHub, checked with `$form` as for the code repo:

``` bash
printf '%s\n' "$issues" | grep -Eq -- "$form"
```

A GitLab path keeps its nested groups (`<group>/<subgroup>/<project>`)
and passes GitLab's form. A value that fails stops the run before the
lock, before reading the issue, and before touching anything: name the
value, the provider and the config file, and tell the person to
correct or remove the key. The issues repo is on the same provider and
host as the code repo (R11.1).

From here every issue operation targets `<issues repo>` and every pull
request operation `<code repo>`, on `<host>`; none is left to a tool's
default. Without an `issues:` value the two are the same repository,
and the run is what it was before the key existed.

**The Gate 1 setting**, `<auto-promote>`, is `auto-promote:` (R33). It
is the person's advance decision on Gate 1, as `merge:` is on Gate 2
([merge.md](merge.md)); the two never stand in for each other:

``` bash
case "$(value auto-promote | tr '[:upper:]' '[:lower:]')" in
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

**A URL argument** must name `<host>` and the issues repo (compare both
without case). A URL naming any other host or repository, the code
repo included when it differs, stops the run, naming both the URL's
host and repository and the run's.

*Read issue* `<n>`. *Not found* stops the run: issue `<n>` does not
exist in `<issues repo>`. *A pull request* stops it too: `<n>` is a
pull request, not an issue.

Done when you hold `<provider>`, its provider file, `<host>`,
`<code repo>`, `<issues repo>` and `<auto-promote>`, the issue exists
in the issues repo, and you hold its state, state reason, title, body
and labels.

## 4. Tell the kind

Read the signals: *read parent* `<n>`; whether it is an Epic (*mark
epic*, to test); and whether it has children (*list children* `<n>`).

| Signals                                    | Kind           |
|--------------------------------------------|----------------|
| `epic`, or children, and no parent         | **Epic**       |
| a parent, no `epic`, no children           | **slice**      |
| none of them                               | **standalone** |

Any other mix conflicts: `epic` or children together with a parent.
Stop, show the person the signals you found, and ask which kind the
issue is. Continue only on their answer.

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
  deleted, so match the name, not the ref): *list prs* for the head
  `^[^/]+/<n>-`.

A closed Epic whose slices are still open is inconsistent. Say so, and
list those slices: *list children* `<n>`, keeping the `open` ones.

Then ask whether to reopen the issue and continue. Only on the
person's yes, *reopen* it.

Any other answer ends the run with the issue left closed.

Done when the issue is open, or the run has ended with it closed.

## 6. Hand on

The run stays within the issue's boundary:

- **Epic**: the run drives the Epic. Follow
  [worktree.md](worktree.md), holding `<root>`, `<provider>` and its
  provider file, `<host>`, `<code repo>`, `<issues repo>`,
  `<auto-promote>`, the Epic `<n>` and its title: it finds or creates
  the Epic branch and worktree, checks the spec, and hands on to step
  1 of [SKILL.md](SKILL.md);
- **slice**: the run handles that slice only (R19);
- **standalone**: the run handles that issue only (R20).

For a slice or a standalone issue, follow [scoped.md](scoped.md),
holding `<root>`, `<provider>` and its provider file, `<host>`,
`<code repo>`, `<issues repo>`, `<auto-promote>`, `<n>`, its title, its
kind and, for a slice, its parent. It checks Gate 1 before it
reaches [worktree.md](worktree.md), so no branch is created for an
issue a person has not promoted.

Done when the run continues as an Epic run, a slice run or a
standalone run.
