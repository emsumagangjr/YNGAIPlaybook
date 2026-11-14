# Open the run's own instance

Every Epic, slice and standalone run has its own agent instance, open
in the issue's own worktree (R46). A session anywhere else finds or
creates that worktree, opens a new instance there with
`/yngorchestrator <n>` already sent, and ends. This file is that
hand-off. [locate.md](locate.md) sends you here, in two parts:

- **Check** (steps 1 and 2), from step 5 of locate.md, once the
  issue's kind is known and the session is not in the issue's own
  worktree;
- **Open** (steps 3 to 5), once the worktree exists: from step 7 of
  locate.md for an Epic, after steps 1 to 4 of
  [worktree.md](worktree.md); from [scoped.md](scoped.md) for a slice
  or a standalone issue, after its Gate 1 check and its step 4.

You hold `<root>`, the provider file, `<code repo>`, `<issues repo>`,
`<n>`, its title, its kind, `<log>` (*Run log* in
[SKILL.md](SKILL.md)), `<launcher>` and `<agent>` (step 3 of
locate.md).

**The launcher never takes the lock** (R48). It only reads it, here
in step 1: the instance it opens takes the lock itself, through its
own locate.md. Until then the run holds no lock, so wherever a step
says to delete the lock, there is none to delete. Between the check
and the launch the run writes only what setting up the worktree
writes (worktree.md step 4) and the run log's `refused`, `launched`
and `launch-failed` lines.

Every command names its target by absolute path. A command whose
argument starts with `/` runs with `MSYS_NO_PATHCONV=1` in front, so
Git Bash on Windows passes `/yngorchestrator <n>` on as it is.

## 1. Check the lock

The lock is `<root>/.yngaiplaybook/yngorchestratorruns/<log>.lock`:
for a slice, its Epic's lock (R21.2).

``` bash
lock="<root>/.yngaiplaybook/yngorchestratorruns/<log>.lock"
[ -f "$lock" ] && cat "$lock"
```

| Lock        | Then                                                         |
|-------------|--------------------------------------------------------------|
| absent      | go on to step 2                                              |
| present, and a herdr workspace on the lock's worktree | focus that workspace and end the run: nothing new starts |
| present, no such workspace | stop with the lock message (*The lock* in [SKILL.md](SKILL.md)): show its path and contents, and leave it |

The lock's worktree is the one holding its `session:` folder:

``` bash
session=$(sed -n 's/^session:[[:space:]]*//p' "$lock")
held=$(git -C "$session" rev-parse --show-toplevel 2>/dev/null)
```

No `held` (the folder is gone, or is the root, outside Git) means no
such workspace, and so does herdr not running (the test in step 3,
whatever `launcher:` says). Otherwise list every pane with
`herdr pane list` and read its JSON. A pane whose `cwd` is `held` or a folder below it names the
workspace, its `workspace_id`. herdr reports Windows paths
(`F:\proj\epic98-x\`), Git Bash may give `/f/proj/epic98-x`: compare
both after `norm`, which also drops a trailing slash and, on Windows,
case:

``` bash
norm() {
  p=$1; command -v cygpath >/dev/null 2>&1 && p=$(cygpath -m "$p")
  p=${p%/}
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) p=$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]') ;;
  esac
  printf '%s\n' "$p"
}
```

With a match:

``` bash
herdr workspace focus <workspace_id>
```

Tell the person, in one sentence, that a run on `#<log>` already holds
the lock and its workspace is now in front. Only a person deletes a
lock, as before.

Done when the lock is absent, or the run has focused the workspace or
stopped.

## 2. Go on to the worktree

Return to step 6 of [locate.md](locate.md), holding that this run
launches. It checks the state as before and hands on: an Epic through
steps 1 to 4 of [worktree.md](worktree.md), a slice or a standalone
issue through [scoped.md](scoped.md), whose Gate 1 check comes before
any branch is created. Each comes back to step 3 here with
`<branch>` and `<worktree>`.

Done when you hold `<worktree>` on `<branch>`, or the run has stopped.

## 3. Pick the launcher

`<launcher>` is the config's `launcher:` (step 3 of locate.md):

| `launcher:`                 | Launcher                                              |
|-----------------------------|-------------------------------------------------------|
| `herdr`                     | herdr                                                 |
| `terminal`                  | a new terminal window                                 |
| absent, empty or any other  | herdr when it is installed and its server is running, else a terminal window |

herdr counts as running when `herdr status server --json` succeeds and
its JSON says `"running":true`:

``` bash
command -v herdr >/dev/null 2>&1 &&
  herdr status server --json 2>/dev/null | grep -q '"running":[[:space:]]*true'
```

Done when you hold one launcher.

## 4. Open the instance

`<name>` is the branch's name after `<prefix><n>-` (`yngproviders` for
`epic/98-yngproviders`), and the window's title is `#<n> <name>`
(R47.4). The command the instance starts with is
`/yngorchestrator <n>`, `<n>` as the issues repo writes it. `<agent>`
is `claude` (R49), the only agent until
[#61](https://github.com/emsumagangjr/YNGAIPlaybook/issues/61).

### herdr

Create a workspace on the worktree, named after the issue, in front:

``` bash
herdr workspace create --cwd "<worktree>" --label "#<n> <name>" --focus
```

Read `.result.workspace.workspace_id` and `.result.root_pane.pane_id`
from its JSON. Start the agent in that pane, with the command as its
first prompt. The agent's name is `yng<n>-<time>`, in lower case, so
it is unique among herdr's live agents and fits herdr's
`[a-z][a-z0-9_-]{0,31}`:

``` bash
MSYS_NO_PATHCONV=1 herdr agent start "yng$(printf '%s' '<n>' | tr '[:upper:]' '[:lower:]')-$(date +%H%M%S)" \
  --kind claude --pane "<pane id>" -- "/yngorchestrator <n>"
```

| Result                     | Means                                                    |
|----------------------------|----------------------------------------------------------|
| exit 0, `agent_started`    | launched                                                 |
| `agent_not_ready`, blocked during startup | launched: the agent is up and asks a question first, such as whether to trust a new worktree's folder. Tell the person to answer it in the workspace; the command runs after |
| any other error            | a launch failure (step 5), with herdr's message; close the workspace you created (`herdr workspace close <workspace_id>`) |

### A terminal window

| System                                  | Window                          |
|-----------------------------------------|---------------------------------|
| Windows (`uname -s` is `MINGW*`, `MSYS*`, `CYGWIN*`) | Windows Terminal, `wt.exe` |
| macOS (`Darwin`)                        | Terminal.app, through `osascript` |
| any other                               | `$TERMINAL`; unset, a launch failure |

``` bash
# Windows: a new window, titled, in the worktree. cmd /k finds claude.exe
# or a claude.cmd shim, and keeps the window open.
MSYS_NO_PATHCONV=1 wt.exe -w new new-tab -d "$(cygpath -w "<worktree>")" \
  --title "#<n> <name>" cmd /k claude "/yngorchestrator <n>"

# macOS
osascript -e "tell application \"Terminal\" to do script \"cd '<worktree>' && claude '/yngorchestrator <n>'\"" \
          -e 'tell application "Terminal" to activate'

# Any other system: the shell stays after the agent exits.
nohup "$TERMINAL" -e sh -c 'cd "$1" && claude "$2"; exec "${SHELL:-sh}"' \
  sh "<worktree>" "/yngorchestrator <n>" >/dev/null 2>&1 &
```

A missing program (`wt.exe`, `osascript`, `$TERMINAL`) or a command
that fails is a launch failure (step 5).

Either way, the workspace or window stays open when the run ends,
with its hand-back list on screen (R47.5).

Done when the instance is open, or the launch has failed.

## 5. Log and end

On a launch, append to `yngorchestratorruns/<log>.md` (*Run log* in
[SKILL.md](SKILL.md)):

``` text
<date> #<n> launched herdr <workspace_id> "#<n> <name>"
<date> #<n> launched terminal <program>
```

Tell the person, in one sentence, where the run now is: the herdr
workspace or the new window, and its worktree. Then this session's
run ends; it holds no lock to delete.

On a **launch failure**, give the reason in one sentence, log
`launch-failed <reason>`, and run as the dispatcher in this session
(R47.6):

1. take the lock (*The lock* in [SKILL.md](SKILL.md)); a lock present
   now stops the run with the lock message;
2. go on in place: an Epic at step 5 of [worktree.md](worktree.md); a
   slice or a standalone issue at step 5 of [scoped.md](scoped.md), or,
   when its step 1 sent you here, at the step its table names.

Done when the run is open in its own instance and this session has
ended, or it runs here after a failure.
