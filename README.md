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
- **Where do people stay in control?** At two gates. **A person promotes** an issue before an agent may start it, and **a person decides every merge**, by hand or by config (`required` or `auto` per merge path). Everything between can run unattended.

```text
Agent → Slice Branch → Epic Branch → main
         (Gate 1: a person promotes)   (Gate 2: a person decides the merge, by hand or by config)
```

## What's inside

```text
YNGAIPlaybook/
├── INSTALL.md             ← install the YNG Orchestrator: by hand, or ask your agent
├── guides/
│   └── epic-workflow.md   ← the main guide: Epics, slices, specs, gates, worktrees
├── templates/             ← copy these into your own project
│   ├── agents.md          ← agent onboarding: who you are, your rules
│   ├── context.md         ← per-project context
│   ├── yngorchestratorconfig.yml ← merge rules (lives in your project's .yngaiplaybook/, uncommitted)
│   ├── yngaiplaybookreadme.md ← the README yngorch writes into your project's .yngaiplaybook/
│   └── claude.md          ← entry point for Claude, defers to agents.md
├── skills/
│   └── yngorchestrator/   ← YNG Orchestrator, the dispatcher as an agent: plan, dispatch, track; any issue, from anywhere
├── agents/
│   └── slice-worker.md    ← the worker it dispatches: one slice, worktree to PR
└── scripts/
    ├── yngv.ps1 / .sh       ← view files from the CLI (markdown rendered in the browser); yngorch puts it on your PATH
    ├── yngshared.ps1 / .sh  ← share private files (.env, secrets) across worktrees, and the agent's files with the root
    └── yngorch.ps1 / .sh    ← install or upgrade the YNG Orchestrator in a project, uncommitted, plus yngv for you
```

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
6. **Let an agent orchestrate** (optional): follow [INSTALL.md](INSTALL.md), by hand or by telling your agent "Install the YNG Orchestrator from https://github.com/emsumagangjr/YNGAIPlaybook into this project, following its INSTALL.md". It installs the orchestrator beside `.bare/`, with nothing committed to your project; run it again to upgrade. Its merge rules and run logs live in `.yngaiplaybook/` in your project root (`yngorchestratorconfig.yml`, `yngorchestratorruns/`), with a `README.md` that explains each file ([template](templates/yngaiplaybookreadme.md)). Then run `/yngorchestrator <issue>` from anywhere in the project: its root or any worktree. The issue can be an Epic, a slice or a standalone issue; it finds or creates the issue's branch and worktree. On an Epic it plans the slices and dispatches the ones you promote to parallel workers; on a slice or a standalone issue it runs that one issue only. It hands back the pull requests for you to merge, or merges them itself on the paths your config sets to `auto`.

## Roadmap

- **More skills** — reusable, agent-runnable plays for the remaining steps the guide describes (triage, diagnose, implement, code review, and more). The YNG Orchestrator is the first.

## License

- Guides, templates, skills and agents: [CC BY 4.0](LICENSE). Share and adapt freely, with credit to Emeterio M. Sumagang Jr. · YNGSoftware.
- Scripts in `scripts/`: [MIT](LICENSE-CODE).

See [CHANGELOG.md](CHANGELOG.md) for release history.
