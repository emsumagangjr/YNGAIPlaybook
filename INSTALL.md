# Installing the YNG Orchestrator

How to set up the YNG Orchestrator (`/yngorchestrator` and its slice worker) in
your project. There are two ways:

- [**Ask your agent**](#ask-your-agent): give it this repository's URL and
  it does the setup, checking with you before any change that matters.
- [**Manual**](#manual): run the commands yourself.

Both end in the same place. Nothing is committed to your project:
everything goes in the project root, beside `.bare/`, outside every
worktree (guide, section 25). The playbook's files for your project
(issues repo, auto-promote, merge rules, run logs) live in `<root>/.yngaiplaybook/`, explained by
the `README.md` the installer writes there
([template](templates/yngaiplaybookreadme.md)). This folder is not the
per-machine playbook copy in `~/.yngaiplaybook`.

------------------------------------------------------------------------

## Before you start

You need these once per machine:

| Need | Check |
|------|-------|
| Git | `git --version` |
| GitHub CLI, logged in | `gh auth status` |
| Claude Code | `claude --version` |
| Windows only: Developer Mode, for the links | Settings → System → For developers |

When the project keeps its issues in a separate GitHub repository (its
*issues repo*, see [After installing](#after-installing)), the account
`gh` is logged in with needs access to both repositories.

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
a new project, add your repository: `...into a new project for
https://github.com/you/myproject`. When the project's issues live in a
separate repository, name it too: `...; its issues are in you/tracker`.

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

1.  **Check the machine.** Run `git --version` and `gh auth status`. On
    Windows, check that Developer Mode is on:

    ``` powershell
    (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock').AllowDevelopmentWithoutDevLicense
    ```

    `1` means on. When something is missing, report it with the fix
    from [Before you start](#before-you-start) and stop.

2.  **Find the project's layout.** From the current folder, run
    `git rev-parse --path-format=absolute --git-common-dir`:

    | Result | Layout | Next |
    |--------|--------|------|
    | Ends in `.bare` | Ready | Step 3 |
    | Ends in `.git` | A normal clone | Propose [Convert an existing clone](#convert-an-existing-clone) |
    | Error, and the person named a repository | New project | Propose [Set up a new project](#set-up-a-new-project) |
    | Error, and no repository named | Unknown | Ask the person which repository |

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
    (`yngorchestratorruns/`), and a `README.md` explaining them, which
    the installer rewrites every time. Upgrading from 1.1.0-1.4.0, it
    moves `<root>/.yngorchestrator/` (1.2.0-1.4.0) or
    `<root>/.orchestrator/` (1.1.0) into `<root>/.yngaiplaybook/`, config
    and run logs kept, one `moved` line per item; from 1.1.0, when the
    skill was `/orchestrate`, it also removes the old skill folder, its
    links in every worktree and its exclude line. When
    `<root>/.yngaiplaybook/` already exists, or both old folders do, it
    moves and writes nothing there and warns: report it, naming the
    folders.

    It also installs `yngv`, the file viewer, for the person, in
    `~/.local/bin` (Windows: `yngv.ps1` and a `yngv.cmd` shim, with the
    folder added to their user PATH when missing). On macOS/Linux a
    `note` line with an `export PATH=...` line means the folder is not
    on PATH: give the person that line, and leave their shell startup
    file alone. When the person does not want `yngv`, add `-SkipViewer`
    / `--skip-viewer`.

    When the person named an issues repo, add `-IssuesRepo
    <owner>/<repo>` / `--issues-repo <owner>/<repo>`, in that form, not
    a URL. The installer writes the config's `issues:` key only when it
    has no value yet (a `wrote` line for `issues:`); a `kept` line for
    `issues:` naming a different repository means the config already holds one,
    which the installer never overwrites: report both to the person,
    and change the config only as they answer. The labels go to the
    flag's repository either way.

5.  **Report.** Tell the person:
    - The project root, the playbook version (`VERSION`) installed, and
      what the installer created or kept, the issues repo included.
    - Where `yngv` went, and whether they must open a new terminal or
      add the PATH line first.
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

    It also puts `yngv`, the file viewer, in `~/.local/bin`. On Windows
    it adds that folder to your user PATH; on macOS/Linux it prints the
    `export PATH=...` line to add when the folder is not on PATH. Open a
    new terminal afterwards. Add `-SkipViewer` / `--skip-viewer` to
    leave `yngv` out, and `-IssuesRepo <owner>/<repo>` /
    `--issues-repo <owner>/<repo>` when your issues live in a separate
    repository ([After installing](#after-installing)).

Then continue with [After installing](#after-installing).

------------------------------------------------------------------------

## Set up a new project

Create the repository with a first commit, so `main` exists, then lay
it out:

``` bash
gh repo create you/myproject --private --add-readme
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
    requests stay in `origin`'s repository; the issues, their labels and
    Gate 1 go to the issues repo. Add the top-level key, or install
    with `-IssuesRepo` / `--issues-repo`, which writes it when it has no
    value yet and creates the labels there:

    ``` yaml
    issues: you/tracker   # <owner>/<repo>; absent or empty: origin's repo
    ```

    Issue numbers, and the `<n>` in every branch name, are then the
    issues repo's. From the code repository, the orchestrator and its
    workers name every issue by full reference, `you/tracker#42`, with
    or without the key: a fix pull request says `Closes you/tracker#42`
    and closes the issue when it merges into `main`. A value that is
    not `<owner>/<repo>` stops the next run, naming it (guide, section
    25).

2.  **Start an Epic:** create its issue, in the issues repo when you
    have one, with the `epic` label. Start
    Claude Code anywhere in the project, at its root or in any
    worktree, and run `/yngorchestrator <n>`. It proposes the Epic
    branch, `epic/<n>-<name>` from `origin/main`, and creates it with
    its worktree, `epic<n>-<name>`, once you confirm the name, linked,
    with the Epic recorded on the branch and a ``Branch: `<branch>` ``
    line added to the issue. With no spec on the branch yet, it stops
    and names where the spec belongs: write
    `docs/specs/<feature>/requirements.md` and `decisions.md` in the
    Epic worktree, commit and push (guide, section 9).

3.  **Run it:** run `/yngorchestrator <n>` again, from anywhere in the
    project. It plans the slices and waits for your approval. Promote
    the slices an agent may take to `workflow:ready-for-agent` on
    GitHub yourself (Gate 1), then run `/yngorchestrator <n>` again.
    With `auto-promote: yes`, your approval of the plan is that
    promotion for the agent slices, and the run dispatches them at
    once.

    The command takes any issue: `<n>`, `#<n>` or the issue's URL.
    Inside a worktree, with no argument, it takes the Epic recorded on
    the current branch. On an Epic it drives the whole Epic; on a slice
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
