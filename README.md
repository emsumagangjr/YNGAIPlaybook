# YNGAIPlaybook

**Your Next-Generation Agentic Workflow.**

The playbook for running AI coding agents in parallel: one Epic, isolated worktrees, two human gates.

By Emeterio M. Sumagang Jr. · [YNGSoftware](https://www.yngsoftware.com)

---

## What this is

A practical, agent-agnostic guide to building software with several AI coding agents at once (Claude Code, Codex, Cursor, pi, or anything else that edits files and runs commands) without them stepping on each other or on you.

It answers three questions:

- **How is the work split?** A feature is an **Epic**. It is cut into **slices**, each one independently deliverable outcome. The **spec** lives in the repo beside the code, not in an issue.
- **How do agents work in parallel safely?** Each slice gets its own branch and its own Git **worktree**, all sharing one bare repository. Agents never touch each other's files.
- **Where do people stay in control?** At two gates. **A person promotes** an issue before an agent may start it, by its label or, with `auto-promote: yes`, by approving the Epic's plan, and **a person decides every merge**, by hand or by config (`required` or `auto` per merge path). Everything between can run unattended.

```text
Agent → Slice Branch → Epic Branch → main
         (Gate 1: a person promotes)   (Gate 2: a person decides the merge, by hand or by config)
```

## Supported providers

The guide works with any Git host. The YNG Orchestrator and its slice worker work with these git providers, through each provider's own tool:

| Provider  | Hosting                              | Tool and sign-in |
|-----------|--------------------------------------|------------------|
| GitHub    | github.com, GitHub Enterprise Server | `gh`, logged in to the host |
| GitLab    | gitlab.com, GitLab self-managed      | `glab`, logged in to the host |
| Bitbucket | bitbucket.org (Cloud only)           | `curl`, with an API token in `BITBUCKET_EMAIL` and `BITBUCKET_API_TOKEN` ([INSTALL.md](INSTALL.md#bitbucket-api-token)) |

**Planned:** Azure DevOps, Bitbucket Data Center, Jira as an issue tracker, Gitea/Forgejo, and an issues repo on a different provider from the code.

More providers will be added: each is one file in `skills/yngorchestrator/providers/` ([Adding a provider](skills/yngorchestrator/providers/README.md#adding-a-provider)). The installer works out your project's provider from `origin`, or takes it from `-Provider` / `--provider`, and records it in the config ([INSTALL.md](INSTALL.md#supported-providers)).

## What's inside

```text
YNGAIPlaybook/
├── INSTALL.md             ← install the YNG Orchestrator: by hand, or ask your agent
├── guides/
│   └── epic-workflow.md   ← the main guide: Epics, slices, specs, gates, worktrees
├── templates/             ← copy these into your own project
│   ├── agents.md          ← agent onboarding: who you are, your rules
│   ├── context.md         ← per-project context
│   ├── yngorchestratorconfig.yml ← issues repo, auto-promote and merge rules (lives in your project's .yngaiplaybook/, uncommitted)
│   ├── yngaiplaybookreadme.md ← the README yngorch writes into your project's .yngaiplaybook/
│   └── claude.md          ← entry point for Claude, defers to agents.md
├── skills/
│   └── yngorchestrator/   ← YNG Orchestrator, the dispatcher as an agent: plan, dispatch, track, hand back; any issue, from anywhere
├── agents/
│   └── slice-worker.md    ← the worker it dispatches: one slice, worktree to PR
└── scripts/
    ├── yngv.ps1 / .sh       ← view files from the CLI (markdown rendered in the browser, and HTML opened as it is, new in 1.15.0); yngorch puts it on your PATH
    ├── yngshared.ps1 / .sh  ← share private files (.env, secrets) across worktrees, and the agent's files with the root
    └── yngorch.ps1 / .sh    ← install or upgrade the YNG Orchestrator in a project, uncommitted, plus yngv for you
```

## Prerequisites

You need, once per machine:

- **Git** — `git --version`.
- **The CLI for your Git host, logged in.** The workflow reads issues and opens pull (merge) requests through it.
- **An AI coding agent** that edits files and runs commands (Claude Code, Codex, Cursor, pi, ...). For the YNG Orchestrator: Claude Code (`claude --version`), and on Windows, Developer Mode for the links (see [INSTALL.md](INSTALL.md)).

Known Git host CLIs:

| Host | CLI | Check | Log in | Install: Windows | Install: macOS | Install: Linux |
|------|-----|-------|--------|------------------|----------------|----------------|
| GitHub | [`gh`](https://cli.github.com) | `gh auth status` | `gh auth login` | `winget install --id GitHub.cli -e` | `brew install gh` | [cli.github.com](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |
| GitLab | [`glab`](https://gitlab.com/gitlab-org/cli) | `glab auth status` | `glab auth login` | `winget install --id GLab.GLab -e` | `brew install glab` | [gitlab.com/gitlab-org/cli](https://gitlab.com/gitlab-org/cli#installation) |
| `jq` (the orchestrator on GitLab and Bitbucket) | [`jq`](https://jqlang.org) | `jq --version` | — | `winget install jqlang.jq` | `brew install jq` | `sudo apt install jq` |
| Bitbucket Cloud | `curl` and an API token (no CLI) | `curl --version`, and `BITBUCKET_EMAIL`, `BITBUCKET_API_TOKEN` set | create the token and set both variables ([INSTALL.md](INSTALL.md#bitbucket-api-token)) | built into Windows 10 and later | built in | your package manager, e.g. `sudo apt install curl` |
| Azure DevOps | [`az`](https://learn.microsoft.com/cli/azure/) + `azure-devops` extension | `az account show` | `az login` | `winget install --id Microsoft.AzureCLI -e` | `brew install azure-cli` | [learn.microsoft.com](https://learn.microsoft.com/cli/azure/install-azure-cli-linux) |
| Gitea, Forgejo, Codeberg | [`tea`](https://gitea.com/gitea/tea) | `tea login list` | `tea login add` | `winget install --id Gitea.tea -e` | `brew install tea` | [gitea.com/gitea/tea](https://gitea.com/gitea/tea/releases) |
| Git itself | `git` | `git --version` | — | `winget install --id Git.Git -e` | `brew install git` | your package manager, e.g. `sudo apt install git` |

For Azure DevOps, add the extension after installing: `az extension add --name azure-devops`.

The guide works with any of these hosts. The YNG Orchestrator and its slice worker work with GitHub, GitLab and Bitbucket Cloud ([Supported providers](#supported-providers)); the install checks only your provider's tool.

### For the agent

Before the first step that needs Git or the host's tool, check both with the commands above, for the host of the project's `origin` (`git remote get-url origin`), and only that host's tool. When one is missing, tell the person which, offer to install it with the command for their platform, and install only after they say yes. Logging in is interactive: ask the person to run the log-in command themselves (in Claude Code, `! gh auth login` or `! glab auth login`), then check again. For Bitbucket, the person creates the API token and sets the two variables themselves; check only that both are set, and never print them.

## Install

Check the [Prerequisites](#prerequisites) first. Then pick one of two ways; both end in the same place, and nothing is committed to your project.

### Ask your agent

Start Claude Code in your project folder, or in the folder where a new project should go, and tell it:

```text
Install the YNG Orchestrator from https://github.com/emsumagangjr/YNGAIPlaybook into this project, following its INSTALL.md.
```

For a new project, add its repository URL: `...into a new project for https://github.com/you/myproject`. The agent checks your setup, tells you what it will change, and installs only after you say yes.

### By hand

1. **Get the playbook**, once per machine:

   ```powershell
   git clone https://github.com/emsumagangjr/YNGAIPlaybook.git $HOME\.yngaiplaybook   # Windows
   ```

   ```bash
   git clone https://github.com/emsumagangjr/YNGAIPlaybook.git ~/.yngaiplaybook      # macOS/Linux
   ```

2. **Put your project in the bare-repository layout**, once per project: see step 3 of [Quick start](#quick-start), or INSTALL.md's [new project](INSTALL.md#set-up-a-new-project) and [existing clone](INSTALL.md#convert-an-existing-clone). Skip this when your project already has `.bare/`.

3. **Run the installer**, from anywhere inside the project:

   ```powershell
   & $HOME\.yngaiplaybook\scripts\yngorch.ps1      # Windows
   ```

   ```bash
   ~/.yngaiplaybook/scripts/yngorch.sh             # macOS/Linux
   ```

   It works out your provider from `origin`, installs the orchestrator beside `.bare/`, writes `.yngaiplaybook/` with its config, and puts `yngv` on your PATH. Open a new terminal afterwards.

4. **Check it:** run `/yngorchestrator continue` in Claude Code from the project root. It lists the runs in progress, or tells you there are none.

### Upgrade

Pull the playbook, then run the installer again. Your config and run logs are kept, and the old config is backed up to `yngorchestratorconfig.yml.bak`:

```powershell
git -C $HOME\.yngaiplaybook pull; & $HOME\.yngaiplaybook\scripts\yngorch.ps1      # Windows
```

```bash
git -C ~/.yngaiplaybook pull && ~/.yngaiplaybook/scripts/yngorch.sh               # macOS/Linux
```

Or tell your agent: *Reinstall the YNG Orchestrator from https://github.com/emsumagangjr/YNGAIPlaybook into this project, following its INSTALL.md.*

[INSTALL.md](INSTALL.md) has every option: providers, a separate issues repository, the Bitbucket API token, and what the installer changes.

## Quick start

1. **Read the guide:** [guides/epic-workflow.md](guides/epic-workflow.md).
2. **Onboard your agents:** copy `templates/agents.md` and `templates/context.md` into your project root, fill in the placeholders, and point your agent at `agents.md` (for Claude, add `templates/claude.md` as `CLAUDE.md`).
3. **Set up the workspace:** create a bare repository with a `main` worktree, as in sections 7 and 8 of the guide:

   ```bash
   mkdir myproject && cd myproject
   git clone --bare <repository-url> .bare
   git --git-dir=.bare config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
   git --git-dir=.bare fetch origin
   git --git-dir=.bare worktree add main main
   ```

4. **Start an Epic and its slices** (sections 9 and 10), then give each agent one slice worktree.
5. **Share private files** across worktrees with `scripts/yngshared.ps1` (Windows) or `scripts/yngshared.sh` (macOS/Linux).
6. **Let an agent orchestrate** (optional): install the YNG Orchestrator as in [Install](#install). It installs the orchestrator beside `.bare/`, with nothing committed to your project; run it again to upgrade. Its config (`auto-promote:`, the `merge:` rules and `handback-page:`, [template](templates/yngorchestratorconfig.yml)), its run logs and its hand-back pages live in `.yngaiplaybook/` in your project root (`yngorchestratorconfig.yml`, `yngorchestratorruns/`, `ynghandback.html` and `ynghandback-<n>.html`), with a `README.md` that explains each file ([template](templates/yngaiplaybookreadme.md)). Then run `/yngorchestrator <issue>` from anywhere in the project: its root or any worktree. Each run opens its own agent instance in the issue's worktree, in a Herdr app space or a herdr workspace when the [Herdr app or herdr](https://herdr.dev) (optional) is running, else in a new terminal window, and the installer asks which to use; `/yngorchestrator continue` picks a run up again without its number. The issue can be an Epic, a slice or a standalone issue; it finds or creates the issue's branch and worktree, naming a new worktree for its issue (`epic100-authentication` for `epic/100-authentication`, `epic100-slice101-oauth` for its slice `slice/101-oauth`, `fix140-login-redirect` for `fix/140-login-redirect`), and records the branch and worktree on the issue. On an Epic it plans the slices and dispatches the ones you promote to parallel workers (with `auto-promote: yes`, approving the plan promotes the agent slices, and dispatch starts at once); on a slice or a standalone issue it runs that one issue only. It hands back the pull requests for you to merge, or merges them itself on the paths your config sets to `auto`. Each hand-back also writes a **hand-back page**, `.yngaiplaybook/ynghandback-<n>.html`, and opens it in your browser (`handback-page: open`, the default): one self-contained HTML file per Epic or standalone issue, listing what is waiting on you in the order the run ranked it. It is an addition to the list the run prints, never a replacement, since that printed list is what reaches you over Remote Control, where a `file://` path is no use to you. Open any page later with `yngv`, which opens HTML in your browser from 1.15.0 on:

   ```bash
   yngv <root>/.yngaiplaybook/ynghandback.html
   ```

7. **Keep issues in their own repository** (optional): when your issues belong apart from the code (a public tracker for a private codebase, say), name that repository, on the same provider as the code, in the config's `issues:` key as its path (`<owner>/<repo>` on GitHub, `<group>[/<subgroup>...]/<project>` on GitLab, `<workspace>/<repo>` on Bitbucket), or install with `-IssuesRepo <path>` (`--issues-repo` in `yngorch.sh`), which writes the key only when it has no value yet. The orchestrator then works the issues in that repository and the code, branches and pull requests in `origin`'s, and names every issue by its full reference, `<owner>/<repo>#<n>`, so links from the code repository reach the right issue ([guide, section 25](guides/epic-workflow.md#25-running-the-dispatcher-as-the-yng-orchestrator)).

## Roadmap

- **More skills** — reusable, agent-runnable plays for the remaining steps the guide describes (triage, diagnose, implement, code review, and more). The YNG Orchestrator is the first.

## License

- Guides, templates, skills and agents: [CC BY 4.0](LICENSE). Share and adapt freely, with credit to Emeterio M. Sumagang Jr. · YNGSoftware.
- Scripts in `scripts/`: [MIT](LICENSE-CODE).

See [CHANGELOG.md](CHANGELOG.md) for release history.
