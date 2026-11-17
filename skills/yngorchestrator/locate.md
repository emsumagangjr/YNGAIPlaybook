# Locate the issue

You find the project root, read its provider and host, resolve its
code repo and issues repo,
check that the issue belongs to this project, tell what kind of
issue it is, and decide where the run goes: here, when the session is
in the issue's own worktree, or into an instance of its own there
([launch.md](launch.md), R46). Nothing here changes a branch, a
worktree or an issue, except a reopen the person said yes to.

The session may have started at the project root, in any worktree, or
in any folder below one. Every command below names its target by
absolute path, so the result is the same from each; only steps 2 and
5 look at the session's own folder.

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

The argument is `<issue>`, `continue`, or nothing: a bare
`/yngorchestrator` is `continue` (R50.3). `continue` is read below,
after the forms of `<issue>`.

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

### `continue`

`continue` resumes a run without its number (R50). In a worktree, the
current branch names the issue:

``` bash
branch=$(git branch --show-current 2>/dev/null)
n=$(printf '%s\n' "$branch" | sed -nE 's#^(epic|fix|slice)/([0-9]+)-.*#\2#p')
```

That is `<n>`, the issue of `epic/<n>-`, `fix/<n>-` or `slice/<n>-`.
The session is then in that issue's own worktree, so step 5 runs it
here, and the lock's procedure resumes it from the run log's last line
(*The lock* in [SKILL.md](SKILL.md)); a slice's lock and log are its
Epic's.

From the root, or a worktree whose branch names no issue (`main`),
there is no `<n>` yet: step 3 picks the run, once the provider is
known (*Pick a run* there).

Done when you hold an issue number `<n>`, or know step 3 picks it.

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

**The launcher**, `<launcher>`, is `launcher:`, in lower case (R47.1,
R55): `herdr-app` (the Herdr desktop app), `herdr` (the herdr CLI) or
`terminal` choose one; no file, no key, an empty value or any other
value leaves it to detection in step 3 of [launch.md](launch.md). It
never stops the run.

**The agent**, `<agent>`, is `agent:`, in lower case; no file, no key
or an empty value is `claude` (R49):

``` bash
agent=$(value agent | tr '[:upper:]' '[:lower:]'); agent=${agent:-claude}
```

Any other value stops the run before the lock and before touching
anything: name the value and the config file, say `claude` is the only
agent the orchestrator runs on today, and that other agents come with
[#61](https://github.com/emsumagangjr/YNGAIPlaybook/issues/61). Remove
the key or set it to `claude`.

**Pick a run** (`continue` with no `<n>`, step 2). The active runs are
the open issues with a run log (R50.2). Each log is
`yngorchestratorruns/<m>.md`, `<m>` an Epic's or a standalone issue's
number (*Run log* in [SKILL.md](SKILL.md)):

``` bash
ls "<root>/.yngaiplaybook/yngorchestratorruns" 2>/dev/null | sed -n 's/\.md$//p'
```

For each `<m>`, *read issue* `<m>`, and keep it when it is `open`. Its
kind is Epic when *mark epic* says so or *list children* `<m>` gives
any, else standalone. It is **running** while `<m>.lock` exists, else
**idle**. Show one line per run, running runs first, then by number:

``` text
#98   running  Epic        Provider abstraction    2026-11-14 #104 dispatched
#122  idle     standalone  Own instance per run    2026-11-13 #122 in-review <PR>
```

Each line is the number, running or idle, the kind, the title and the
log's last line. Then:

- **none**: say there is no active run, and ask the person for the
  issue;
- **one**: take it, without asking;
- **more**: ask the person which one.

The chosen run's number is `<n>`. It goes on like any other: step 5
sends it to its own instance, through the lock check of
[launch.md](launch.md) (R48), unless the session is in its worktree.

**A URL argument** must name `<host>` and the issues repo (compare both
without case). A URL naming any other host or repository, the code
repo included when it differs, stops the run, naming both the URL's
host and repository and the run's.

*Read issue* `<n>`. *Not found* stops the run: issue `<n>` does not
exist in `<issues repo>`. *A pull request* stops it too: `<n>` is a
pull request, not an issue.

Done when you hold `<provider>`, its provider file, `<host>`,
`<code repo>`, `<issues repo>`, `<auto-promote>`, `<launcher>`,
`<agent>` and `<n>`, the issue exists
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

## 5. Run here or launch

`<log>` follows the kind (*Run log* in [SKILL.md](SKILL.md)): an
Epic's own number, a slice's parent, a standalone issue's own number.

The session is in the issue's **own worktree** when the branch of the
worktree holding the session's folder fits the kind (`epic/`,
`slice/`, `fix/`) and names `<n>`:

``` bash
git branch --show-current 2>/dev/null | grep -Eq "^(epic|slice|fix)/<n>-"
```

| Session                     | The run                                                   |
|-----------------------------|-----------------------------------------------------------|
| in the issue's own worktree | runs here, as the dispatcher (R46.2): take the lock (*The lock* in [SKILL.md](SKILL.md)) and go on to step 6 |
| anywhere else               | **launches** (R46.1): follow steps 1 and 2 of [launch.md](launch.md), which check the lock without taking it and bring the run back to step 6 |

No flag chooses between them: where the session is decides. A launch
that fails runs here after all (step 5 of [launch.md](launch.md)).

Done when the run holds the lock here, or goes on to launch.

## 6. Check the state

An open issue goes on to step 7.

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

## 7. Hand on

The run stays within the issue's boundary:

- **Epic**: the run drives the Epic. Follow
  [worktree.md](worktree.md), holding `<root>`, `<provider>` and its
  provider file, `<host>`, `<code repo>`, `<issues repo>`,
  `<auto-promote>`, the Epic `<n>` and its title: it finds or creates
  the Epic branch and worktree, checks the spec, and hands on to step
  1 of [SKILL.md](SKILL.md). A run that launches stops after
  worktree.md's step 4 and goes to step 3 of [launch.md](launch.md)
  with `<branch>` and `<worktree>`: the instance it opens checks the
  spec;
- **slice**: the run handles that slice only (R19);
- **standalone**: the run handles that issue only (R20).

For a slice or a standalone issue, follow [scoped.md](scoped.md),
holding `<root>`, `<provider>` and its provider file, `<host>`,
`<code repo>`, `<issues repo>`, `<auto-promote>`, `<n>`, its title, its
kind, for a slice its parent, and whether the run launches. It checks
Gate 1 before it reaches [worktree.md](worktree.md), so no branch is
created for an issue a person has not promoted, and a run that
launches goes to [launch.md](launch.md) from there.

Done when the run continues as an Epic run, a slice run or a
standalone run, here or in its own instance.
