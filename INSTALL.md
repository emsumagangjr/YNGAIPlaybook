# Installing the YNG Orchestrator

How to set up the YNG Orchestrator (`/yngorchestrator` and its slice worker) in
your project. There are two ways:

- [**Ask your agent**](#ask-your-agent): give it this repository's URL and
  it does the setup, checking with you before any change that matters.
- [**Manual**](#manual): run the commands yourself.

Both end in the same place. Nothing is committed to your project:
everything goes in the project root, beside `.bare/`, outside every
worktree (guide, section 25). The playbook's files for your project
(provider, issues repo, auto-promote, merge rules, run logs) live in `<root>/.yngaiplaybook/`, explained by
the `README.md` the installer writes there
([template](templates/yngaiplaybookreadme.md)). This folder is not the
per-machine playbook copy in `~/.yngaiplaybook`.

------------------------------------------------------------------------

## Supported providers

The orchestrator works with your project's git provider through that
provider's own tool:

| Provider  | Hosting                              | Tool and sign-in |
|-----------|--------------------------------------|------------------|
| GitHub    | github.com, GitHub Enterprise Server | `gh`, logged in to the host |
| GitLab    | gitlab.com, GitLab self-managed      | `glab`, logged in to the host |
| Bitbucket | bitbucket.org (Cloud only)           | `curl`, with an API token in `BITBUCKET_EMAIL` and `BITBUCKET_API_TOKEN` ([Bitbucket API token](#bitbucket-api-token)) |

**Planned:** Azure DevOps, Bitbucket Data Center, Jira as an issue
tracker, Gitea/Forgejo, and an issues repo on a different provider
from the code.

More providers will be added. Each one is a single file,
`skills/yngorchestrator/providers/<provider>.md`: the orchestrator runs
on a provider once its file is there
([Adding a provider](skills/yngorchestrator/providers/README.md#adding-a-provider)).

The installer works the provider out for you: from the config's
`provider:` when it has one, else from `origin`'s host (`github.com`,
`gitlab.com` and `bitbucket.org` by name; any other host by whether
`gh` or `glab` is logged in to it). When it cannot tell, it stops,
writing nothing, and asks for `-Provider` / `--provider`. It records
the provider and host in the config's `provider:` and `host:` keys.

------------------------------------------------------------------------

## Before you start

You need these once per machine:

| Need | Check |
|------|-------|
| Git | `git --version` |
| Your provider's tool, signed in (only that one) | GitHub: `gh auth status --hostname <host>` · GitLab: `glab auth status --hostname <host>` · Bitbucket: `curl --version`, and the [API token](#bitbucket-api-token) variables set |
| GitLab and Bitbucket only: `jq` (GitHub's `gh` has `--jq` built in) | `jq --version`; install with `winget install jqlang.jq` (Windows), `brew install jq` (macOS) or `sudo apt install jq` (Linux) |
| Claude Code | `claude --version` |
| Windows only: Developer Mode, for the links | Settings → System → For developers |
| Optional: the Herdr desktop app or the herdr CLI ([herdr.dev](https://herdr.dev)), so each run opens in a Herdr app space or a herdr workspace instead of a new terminal window | `herdr-app --version` or `herdr --version`; the installer prints which it found, and asks which to use |

`<host>` is your provider's host: `github.com`, `gitlab.com`, or your
own server's name. To log in: `gh auth login --hostname <host>` or
`glab auth login --hostname <host>`.

When the project keeps its issues in a separate repository on the same
provider (its *issues repo*, see [After installing](#after-installing)),
the account you are signed in with needs access to both repositories.

### Bitbucket API token

Bitbucket Cloud has no CLI the orchestrator uses; it calls Bitbucket's
API with `curl`, signed in with your Atlassian account's email and an
API token. Create the token in your Atlassian account settings
(Security → API tokens → *Create API token with scopes*, app
Bitbucket), with these scopes:

| Scope | For |
|-------|-----|
| `read:repository:bitbucket`, `write:repository:bitbucket` | the repository, its branches, the merge's branch deletion |
| `read:pullrequest:bitbucket`, `write:pullrequest:bitbucket` | opening, checking, commenting on and merging pull requests |
| `read:issue:bitbucket`, `write:issue:bitbucket` | reading issues, their state, comments, creating and closing them |
| `read:user:bitbucket` | the installer's check, `GET /2.0/user` |
| `admin:repository:bitbucket` | only to create a new repository through the API ([Set up a new project](#set-up-a-new-project)) |

Then set the two variables for your user, and open a new terminal.
PowerShell:

``` powershell
[Environment]::SetEnvironmentVariable('BITBUCKET_EMAIL', 'you@example.com', 'User')
[Environment]::SetEnvironmentVariable('BITBUCKET_API_TOKEN', (Read-Host 'API token'), 'User')
```

bash (add both lines to `~/.bashrc` or `~/.zshrc`, or your secret
manager's equivalent):

``` bash
export BITBUCKET_EMAIL='you@example.com'
export BITBUCKET_API_TOKEN='<the token>'
```

**Warning: the workflow takes over the issues repo's components.** On
Bitbucket an issue's workflow state is its component (`needs-triage`,
`ready-for-agent`, ...), and an issue holds one. Setting a state
replaces whatever component the issue had, so a project that uses
components for something else (areas, teams) loses that use. The
installer prints a `note` when it finds components other than the
workflow's.

The token stays in these two variables only. Nothing in the playbook
writes it to the config, the project, a run log, a comment or a
report, or prints it; the installer hands it to `curl` on its standard
input, never on its command line.

Your project must use the playbook's layout: a bare repository in
`.bare/`, with one folder per worktree (guide, sections 7 and 8). Both
ways below can set this up for you.

------------------------------------------------------------------------

## Ask your agent

Start Claude Code in your project folder, or in the folder where the
project should go, and tell it:

``` text
Install the YNG Orchestrator from https://github.com/emsumagangjr/YNGAIPlaybook into this project, following its INSTALL.md.
```

To upgrade to the latest version, or to repair an install, say
*reinstall*:

``` text
Reinstall the YNG Orchestrator from https://github.com/emsumagangjr/YNGAIPlaybook into this project, following its INSTALL.md.
```

In place of the URL you can give a playbook clone you already have,
such as `F:\YNGAIPlaybook\main`; the agent uses it exactly as it is. For
a new project, add your repository's URL, on any supported provider:
`...into a new project for https://gitlab.com/you/myproject`. With a
URL the agent needs no more; with only a name, or nothing, it asks you
the provider, then the host when it is self-hosted, then the owner,
group or workspace. When the project's issues live in a separate
repository, name it too: `...; its issues are in you/tracker`.

It checks your setup, tells you what it will change, waits for your
approval, installs, and reports back. Reinstalling keeps your run logs
and every setting in your config, and adds the settings new in this
version, after backing the config up to
`yngorchestratorconfig.yml.bak`. Next, set `auto-promote:` and your
merge rules, and start an Epic
([After installing](#after-installing)).

### For the agent doing the install

You are installing or reinstalling the orchestrator in the person's
project; both follow these steps. Finish when the installer has run
without warnings, or when you have reported what blocks it. You never
commit to the project, change its branches, or move or delete an
existing folder.

1.  **Check the machine.** Run `git --version`. On Windows, check that
    Developer Mode is on:

    ``` powershell
    (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock').AllowDevelopmentWithoutDevLicense
    ```

    `1` means on. Then check the provider's tool, and only that one,
    once step 2 has settled the provider and host: `gh auth status
    --hostname <host>` (GitHub), `glab auth status --hostname <host>`
    (GitLab), or, for Bitbucket, `curl --version` and that
    `BITBUCKET_EMAIL` and `BITBUCKET_API_TOKEN` are both set (test that
    they are non-empty; never print them). For GitLab and Bitbucket,
    also `jq --version`. When something is missing,
    report it with the fix from [Before you start](#before-you-start)
    and stop.

2.  **Find the project's layout and provider.** From the current
    folder, run `git rev-parse --path-format=absolute --git-common-dir`:

    | Result | Layout | Next |
    |--------|--------|------|
    | Ends in `.bare` | Ready | Step 3 |
    | Ends in `.git` | A normal clone | Propose [Convert an existing clone](#convert-an-existing-clone) |
    | Error, and the person named a repository | New project | Propose [Set up a new project](#set-up-a-new-project) |
    | Error, and no repository named | Unknown | Ask the person which repository |

    Work the provider and host out; ask only when they cannot be:
    - The config, `<root>/.yngaiplaybook/yngorchestratorconfig.yml`,
      has `provider:`: that provider, on its `host:` or else its cloud
      host.
    - Otherwise, the host of `origin` (`git remote get-url origin`) or
      of the repository URL the person named: `github.com` is GitHub,
      `gitlab.com` is GitLab, `bitbucket.org` is Bitbucket. For any
      other host, run `gh auth status --hostname <host>` and `glab auth
      status --hostname <host>`: exactly one logged in names the
      provider. A Bitbucket host other than `bitbucket.org` is
      Bitbucket Data Center: planned, not supported; report it and
      stop.
    - Otherwise (a new project named by name only, or nothing, or a
      host neither or both tools are logged in to), ask the person,
      one question at a time: the provider (GitHub, GitLab or
      Bitbucket); the host, only when it is self-hosted; then, for a
      new project, the owner, group or workspace. Pass the answer to
      the installer as `-Provider` / `--provider` (step 4).

    Proposing means showing the folders and commands you will create
    and run, then waiting for the person's yes. The existing clone
    stays exactly where and as it is.

3.  **Get the playbook.** When the person gave a local path, that
    folder is the playbook: use it as it is, with no pull or checkout.
    Otherwise keep one copy per machine, outside every project, in
    `~/.yngaiplaybook` (Windows: `$HOME\.yngaiplaybook`), and bring it
    up to date:

    ``` bash
    git clone https://github.com/emsumagangjr/YNGAIPlaybook.git ~/.yngaiplaybook   # first time
    git -C ~/.yngaiplaybook pull --ff-only                                          # later
    ```

    Use the branch the person names (`git -C ~/.yngaiplaybook checkout
    <branch>`); otherwise `main`. When `scripts/yngorch.ps1` is
    missing, the branch predates the orchestrator: report it and stop.

4.  **Install.** From inside the project, run the installer from the
    playbook for the shell you have: `scripts/yngorch.ps1` in
    PowerShell, `scripts/yngorch.sh` in bash (on Windows, with
    `MSYS=winsymlinks:nativestrict` set). Done when its output ends
    with `Done. Next:` and has no `warning` line. A warning names its
    cause; report it.

    The installer overwrites the skill and worker and keeps the config,
    so a reinstall runs the same command. On a reinstall it keeps every
    setting in the config and adds only the settings and keys the
    template has and the config lacks, changing no line of the person's:
    a `backed up` line for the copy it makes first,
    `yngorchestratorconfig.yml.bak`, then one `added` line each; or a
    `kept` line `(yours, nothing new)`. A key it cannot add line by line
    is a `warning` giving the line to paste: report it, with that line,
    and add it only as the person answers. A `note` that a key is not in
    the template is not a warning: pass it on. The project's playbook files
    go in `<root>/.yngaiplaybook/`: the config
    (`yngorchestratorconfig.yml`), the run logs and locks
    (`yngorchestratorruns/`), the run boards a run writes as it goes
    (`yngboard-<n>.html`), and a `README.md` explaining them, which
    the installer rewrites every time. Upgrading from 1.1.0-1.4.0, it
    moves `<root>/.yngorchestrator/` (1.2.0-1.4.0) or
    `<root>/.orchestrator/` (1.1.0) into `<root>/.yngaiplaybook/`, config
    and run logs kept, one `moved` line per item; from 1.1.0, when the
    skill was `/orchestrate`, it also removes the old skill folder, its
    links in every worktree and its exclude line. When
    `<root>/.yngaiplaybook/` already exists, or both old folders do, it
    moves and writes nothing there and warns: report it, naming the
    folders.

    It also installs two commands for the person, in `~/.local/bin`:
    `yngv`, the file viewer, and `yngboard`, which opens a worktree's
    run board with it (Windows: `yngv.ps1` and `yngboard.ps1`, each
    with a `.cmd` shim, with the folder added to their user PATH when
    missing). `-BinDir <path>` / `--bin-dir <path>` puts both
    somewhere else. On macOS/Linux a `note` line with an
    `export PATH=...` line means the folder is not on PATH: give the
    person that line, and leave their shell startup file alone. When
    the person wants neither, add `-SkipViewer` / `--skip-viewer`,
    which leaves out `yngboard` too: `yngboard` opens a board with
    `yngv`.

    **The provider.** When step 2 settled the provider by asking, add
    `-Provider github|gitlab|bitbucket` / `--provider
    github|gitlab|bitbucket`; it skips the installer's own detection.
    Otherwise run without it. The installer settles the provider
    before it writes anything, and prints one line for each key:
    `wrote provider: gitlab (detected from origin)` or `(from
    -Provider)` / `(from --provider)`, or `kept provider: gitlab (yours)`; then `wrote host:
    <host> (from origin)`, `wrote host: gitlab.com (gitlab's cloud
    host)` when there is no origin, or `kept host: <host> (yours)`. It
    writes each key only when it has no value yet. It stops, with
    nothing written, in three cases; report each to the person:
    - It cannot tell the provider: there is no origin remote, or
      neither or both of `gh` and `glab` are logged in to the host (it
      names what each check returned). Ask the person the provider and
      run again with `-Provider` / `--provider`.
    - `-Provider` / `--provider`, or the config's `provider:`, is not
      one of `github`, `gitlab`, `bitbucket`.
    - The provider is Bitbucket on a host other than `bitbucket.org`
      (Bitbucket Data Center): planned, not supported.

    A `-Provider` / `--provider` that differs from the config's
    `provider:` is a `warning` naming both: the config wins and is not
    changed; report it, and change the config only as the person
    answers.

    It then checks the provider's tool, and only that one, on the host.
    A failed check is a `warning` naming what failed (the tool missing,
    not logged in, or the Bitbucket variables unset or refused); the
    install goes on, skips the workflow states, and you report the fix
    from [Before you start](#before-you-start). On GitHub and GitLab it
    creates the workflow labels in the issues repo. Bitbucket's API
    cannot create components or milestones, so on Bitbucket the
    installer always warns until they exist, naming each missing
    component (`needs-triage`, `ready-for-agent`, ...) and the `epic`
    milestone and the repository's settings page
    (`https://bitbucket.org/<workspace>/<repo>/admin`, Repository
    settings → Issues, with the issue tracker on). Give the person
    that list to create by hand, then run the installer again; it is
    done when that warning is gone.

    When the person named an issues repo, add `-IssuesRepo <path>` /
    `--issues-repo <path>`, with the provider's path, not a URL:
    `<owner>/<repo>` on GitHub, `<workspace>/<repo>` on Bitbucket,
    `<group>[/<subgroup>...]/<project>` on GitLab, on the same provider
    as the code; any other form stops the install before anything is
    written. The installer writes the config's `issues:` key only when
    it has no value yet (a `wrote` line for `issues:`); a `kept` line
    for `issues:` naming a different repository means the config
    already holds one, which the installer never overwrites: report
    both to the person, and change the config only as they answer. The workflow states go to the flag's
    repository either way.

5.  **Report.** Tell the person:
    - The project root, the playbook version (`VERSION`) installed, and
      what the installer created or kept, the issues repo included.
    - Where `yngv` and `yngboard` went, and whether they must open a
      new terminal or add the PATH line first.
    - Which herdr products the installer found (its `found` or `note`
      lines), and the `launcher:` it kept or wrote. Run by you, the
      installer cannot ask, so it prints a `note` instead: ask the
      person which launcher they want (`herdr-app`, the Herdr desktop
      app; `herdr`, the herdr CLI; or `terminal`), recommending the
      first one found, and run it again with `-Launcher` /
      `--launcher <value>`. Without a `launcher:`, each run detects one.
    - On a first install: `auto-promote:` is `no` and their merge
      rules are all `required`. Ask whether they want plan approval to
      promote the agent slices (`auto-promote: yes`) and any merge path
      set to `auto`, and edit
      `<root>/.yngaiplaybook/yngorchestratorconfig.yml` only as they
      answer.
    - The next steps from [After installing](#after-installing).

------------------------------------------------------------------------

## Manual

1.  **Get the playbook**, once per machine:

    ``` powershell
    git clone https://github.com/emsumagangjr/YNGAIPlaybook.git $HOME\.yngaiplaybook
    ```

    To upgrade later: `git -C $HOME\.yngaiplaybook pull`, then step 3
    again.

2.  **Put your project in the layout**, once per project:
    [new project](#set-up-a-new-project) or
    [existing clone](#convert-an-existing-clone). Skip this if your
    project already has `.bare/`.

3.  **Install**, from anywhere inside the project:

    ``` powershell
    & $HOME\.yngaiplaybook\scripts\yngorch.ps1      # Windows
    ```

    ``` bash
    ~/.yngaiplaybook/scripts/yngorch.sh             # macOS/Linux
    ```

    It also puts two commands in `~/.local/bin`: `yngv`, the file
    viewer, and `yngboard`, which opens this worktree's run board with
    it (*What a run leaves you* below). On Windows it adds that folder
    to your user PATH; on macOS/Linux it prints the
    `export PATH=...` line to add when the folder is not on PATH. Open a
    new terminal afterwards. `-BinDir <path>` / `--bin-dir <path>` puts
    both somewhere else. Add `-SkipViewer` / `--skip-viewer` to
    leave `yngv` out, and `yngboard` with it, and `-IssuesRepo <path>` / `--issues-repo <path>`
    (the provider's path, as in `issues:` below) when your issues live
    in a separate repository on the same provider
    ([After installing](#after-installing)). In a terminal, when it finds the Herdr app or herdr, it asks which launcher to use; add `-Launcher` / `--launcher <value>` to choose without being asked.

    The installer works out your provider
    ([Supported providers](#supported-providers)). When it stops
    asking for one (no `origin` remote, or a self-hosted server it
    cannot name), run it again with `-Provider github|gitlab|bitbucket`
    (`--provider` in `yngorch.sh`):

    ``` powershell
    & $HOME\.yngaiplaybook\scripts\yngorch.ps1 -Provider gitlab
    ```

    ``` bash
    ~/.yngaiplaybook/scripts/yngorch.sh --provider gitlab
    ```

    It writes `provider:` and `host:` into the config only when they
    have no value yet; a flag that differs from the config is a
    warning, and the config wins. On Bitbucket, create the issue
    components and the `epic` milestone it names by hand, in the
    repository's settings, then run it again.

Then continue with [After installing](#after-installing).

------------------------------------------------------------------------

## Set up a new project

Create the repository with a first commit, so `main` exists, then lay
it out. When the repository already exists, skip the creation (the
agent reports it) and clone it.

**1. Create the repository**, on your provider:

GitHub (on GitHub Enterprise Server, prefix `GH_HOST=<host>`):

``` bash
gh repo create you/myproject --private --add-readme
```

GitLab (on a self-managed server, prefix `GITLAB_HOST=<host>`;
`you` may be a group path such as `team/sub`):

``` bash
glab repo create you/myproject --private --readme
```

Bitbucket Cloud, with the [API token](#bitbucket-api-token) variables
set: create the repository through the API, with its issue tracker on,
then commit its first README to `main` through the API too (the
*create repo* operation of the Bitbucket provider file), so no git
sign-in is needed yet. The credentials go to `curl` on its standard
input, never on its command line:

``` bash
curl -sS -f -K - -X POST -H 'Content-Type: application/json' \
  -d '{"scm": "git", "is_private": true, "has_issues": true}' \
  https://api.bitbucket.org/2.0/repositories/myworkspace/myproject <<EOF
user = "$BITBUCKET_EMAIL:$BITBUCKET_API_TOKEN"
EOF
scratch=$(mktemp -d)
printf '# myproject\n' > "$scratch/README.md"
curl -sS -f -K - -X POST \
  -F "README.md=@$scratch/README.md" -F branch=main -F 'message=Initial commit' \
  https://api.bitbucket.org/2.0/repositories/myworkspace/myproject/src <<EOF
user = "$BITBUCKET_EMAIL:$BITBUCKET_API_TOKEN"
EOF
rm -rf "$scratch"
```

Git signs in to bitbucket.org later, at the bare clone below and at
every push. With Git Credential Manager (Git for Windows' default), it
prompts once and stores the sign-in. Otherwise use your account email
as the username and the same API token as the password, or use an SSH
key and the SSH clone URL (`git@bitbucket.org:myworkspace/myproject.git`).

**2. Lay it out**, the same on every provider, with your repository's
clone URL (`https://github.com/you/myproject.git`,
`https://gitlab.com/you/myproject.git`,
`https://bitbucket.org/myworkspace/myproject.git`, or your server's):

``` bash
mkdir myproject && cd myproject
git clone --bare https://github.com/you/myproject.git .bare
git --git-dir=.bare config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git --git-dir=.bare fetch origin
git --git-dir=.bare worktree add main main
```

## Convert an existing clone

Lay the project out in a new folder beside your clone, and keep the
clone until you have checked the new one:

1.  In the old clone, push every branch you want to keep.
2.  Run the commands from [Set up a new project](#set-up-a-new-project),
    from `mkdir` on, with your repository's URL and a new folder name
    (for example `myproject-ws`).
3.  Copy the untracked private files (`.env`, secrets, local config)
    from the old clone into the new folder's `.shared/`. `yngshared`
    links them into every worktree (guide, section 19).

------------------------------------------------------------------------

## After installing

1.  **Set your gates** in
    `<root>/.yngaiplaybook/yngorchestratorconfig.yml`: `auto-promote:`
    for Gate 1 and the `merge:` rules for Gate 2. The file documents
    every key, with worked examples
    ([config template](templates/yngorchestratorconfig.yml)), and the
    folder's `README.md` lists every file there and every key
    ([template](templates/yngaiplaybookreadme.md)). For example, to have
    your approval of an Epic's plan start its agent slices, let the
    orchestrator merge slices into the Epic, and keep `main` for you:

    ``` yaml
    auto-promote: yes
    merge:
      slice-to-epic: auto
      epic-to-main: required
      fix-to-main: required
    ```

    Plan approval never promotes a slice only a person may do, a
    standalone issue, or a slice created by hand (guide, section 6,
    *Gate 1 by plan approval*).

    **Name your issues repo**, only when the issues live apart from the
    code: a public tracker for a private codebase, say, or a code
    repository with its issues turned off. Code, branches and pull
    requests stay in `origin`'s repository; the issues, their workflow
    states and Gate 1 go to the issues repo, on the same provider and
    host. Add the top-level key, or install with `-IssuesRepo` /
    `--issues-repo`, which writes it when it has no value yet and sets
    up the workflow states there:

    ``` yaml
    issues: you/tracker   # the provider's path; absent or empty: origin's repo
    ```

    Issue numbers, and the `<n>` in every branch name, are then the
    issues repo's. From the code repository, the orchestrator and its
    workers name every issue by full reference, `you/tracker#42`, with
    or without the key: a fix pull request names its issue with the
    provider's closing reference (`Closes you/tracker#42` on GitHub),
    and the issue closes when it merges into `main`; where the provider
    does not close it, the orchestrator does. The value is the
    provider's path: `<owner>/<repo>` on GitHub, `<workspace>/<repo>`
    on Bitbucket, `<group>[/<subgroup>...]/<project>` on GitLab. Any
    other form stops the next run, naming it (guide, section 25).

    **Where runs open.** Each run works in its own agent instance, in
    its issue's own worktree. Started anywhere else, it opens that
    instance for you, named after the project and worktree
    (`YNGAIPlaybook · epic98-yngproviders`): in a Herdr desktop app
    space, a herdr CLI workspace, or a new terminal window (Windows
    Terminal, Terminal.app, or `$TERMINAL`). The Herdr app and the
    herdr CLI are separate products, both optional
    ([herdr.dev](https://herdr.dev)). Three keys, all yours:

    ``` yaml
    launcher: herdr-app  # herdr-app | herdr | terminal; absent: the Herdr app when its window is open,
                         #   else the herdr CLI when its server runs, else a terminal window
    agent: claude        # the only agent today; any other value stops the run
    remote-control: yes  # yes | no; absent: yes. Each launched instance starts with Remote Control
    ```

    On an install with no `launcher:` yet, `yngorch` asks which to use
    when it finds herdr or the Herdr app, and writes your answer;
    `-Launcher` / `--launcher <value>` sets it without asking. It never
    changes a value you set, and never writes `agent:` or
    `remote-control:`.

    **What a run leaves you.** Every run ends by telling you what is
    waiting on you. As it goes, it also writes a **run board**: one
    self-contained HTML file per run log, in
    `<root>/.yngaiplaybook/` beside the config and the run logs.
    `yngboard-<n>.html` is one run log's board, `<n>` being that log's
    number — an Epic's number, or a standalone issue's own — and it is
    rewritten at every run-log event, with one table showing every
    slice, where each one is, what each needs from you, and the latest
    line each working agent has reported. The board is an addition to
    the list the run prints, never a replacement: that printed list is
    what reaches you over Remote Control, where a `file://` path is no
    use to you. It is also run-only: nothing watches the provider and
    nothing refreshes a board between runs, so it is current as of the
    last event of the last run, which is what its timestamp says. One
    key, yours:

    ``` yaml
    run-board: write  # write | open | no; absent, empty or any other value: write
    ```

    - `write` — the run writes the board at every event and opens
      nothing. The default. Leave a browser tab on the board and
      reload it, or type `yngboard`.
    - `open` — the run writes the same board, and opens it in your
      default browser once, at that run's first write.
    - `no` — the run writes no board at all.

    `handback-page:` is the setting's former name, from 1.15.0, and is
    still honoured: with no `run-board:` key beside it, its value is
    read in `run-board`'s place and nothing ever rewrites it; set
    both, and `run-board:` wins. `yngorch` adds `run-board:` at
    `write` only when your config carries neither key, and never
    changes a value you set.

    To open a board, type `yngboard`, which the installer puts on your
    PATH beside `yngv`:

    ``` bash
    yngboard
    ```

    It takes no argument, `-h` / `--help` aside, which prints its own
    header. In a worktree whose branch names an issue
    (`epic/<n>-`, `slice/<n>-` or `fix/<n>-`) it opens that log's
    board — a slice's board is its Epic's — and at the project root,
    or on `main`, it opens the most recently written one; with none
    written for that log it says so in one line and names the run that
    would write one. It opens a file and nothing else: no provider
    call, no regeneration, no write. It hands the board to `yngv`, and
    `YNGV_HTML_BROWSER=no` makes it name the board's path and open
    nothing. `yngv` opens a board by path too, and prints any file's
    own source in the terminal with `-Console` / `-c`:

    ``` bash
    yngv <root>/.yngaiplaybook/yngboard-<n>.html
    ```

    Nothing outside a run regenerates a board or calls the provider,
    and `yngorch` gains no command or flag for it: a board too old to
    trust is refreshed by starting a run (guide, section 25, *Run
    board*).

2.  **Start an Epic:** create its issue, in the issues repo when you
    have one, marked as an Epic: the `epic` label on GitHub and
    GitLab, the `epic` milestone on Bitbucket. Start
    Claude Code anywhere in the project, at its root or in any
    worktree, and run `/yngorchestrator <n>`. It proposes the Epic
    branch, `epic/<n>-<name>` from `origin/main`, and creates it with
    its worktree, `epic<n>-<name>`, once you confirm the name, linked,
    with the Epic recorded on the branch and a ``Branch: `<branch>` ``
    line added to the issue. Then it opens the Epic's own instance in
    that worktree, with `/yngorchestrator <n>` already sent, and the
    session you started in ends. With no spec on the branch yet, it stops
    and names where the spec belongs: write
    `docs/specs/<feature>/requirements.md` and `decisions.md` in the
    Epic worktree, commit and push (guide, section 9).

3.  **Run it:** run `/yngorchestrator <n>` again, from anywhere in the
    project. It plans the slices and waits for your approval. Promote
    the slices an agent may take to `workflow:ready-for-agent`
    yourself, signed in as you (Gate 1): the label on GitHub and
    GitLab, the `ready-for-agent` component on Bitbucket. Then run
    `/yngorchestrator <n>` again.
    With `auto-promote: yes`, your approval of the plan is that
    promotion for the agent slices, and the run dispatches them at
    once.

    The command takes any issue: `<n>`, `#<n>` or the issue's URL.
    Run it again while the run is going and it brings that run's Herdr
    app space or herdr workspace to the front instead of starting another. To pick a run
    up without its number, run `/yngorchestrator continue`, or just
    `/yngorchestrator`: in an issue's worktree it resumes that issue's
    run there; from the root or `main/` it lists the active runs and
    goes straight to the only one. On an Epic it drives the whole Epic; on a slice
    it runs that one slice to its merge into the Epic; on a standalone
    issue it works on a `fix/` branch from `main` and opens a pull
    request into `main` (guide, section 25).

    Each worktree it creates names its issue: `epic<n>-<name>` for an
    Epic, `epic<e>-slice<n>-<name>` for a slice of Epic `<e>`, and
    `fix<n>-<name>` for a standalone issue, beside the branches
    `epic/<n>-<name>`, `slice/<n>-<name>` and `fix/<n>-<name>`. Each
    dispatch comments the branch and worktree on the issue. Worktrees
    you already have keep their folders and still work (guide,
    section 3).

To upgrade, update the playbook copy and run the installer again. It
keeps every setting in your config and adds the settings new in this
version, changing no line of yours, after copying the config to
`.yngaiplaybook/yngorchestratorconfig.yml.bak`; it prints one line per
setting added.
