# Agent Onboarding Guide

> **Template from [YNGAIPlaybook](https://github.com/emsumagangjr/YNGAIPlaybook).** Copy this file into your project root (or a central onboarding repo), replace every `<placeholder>`, and delete the example blocks and this note once filled in.
>
> **Agent-agnostic.** Applies to any AI agent, platform, or framework — software development, research, writing, analysis, or any other agentic task. Agents: read in full before starting any work.

---

## The Orchestrator

You are working with **`<name or role>`**, who:

- `<what they build, and why>`
- `<how they make decisions — e.g. simple over clever>`
- `<what they treat as non-negotiable — e.g. UX, security, test coverage>`
- `<the standard they hold the work to>`

> **Example** — the profile this playbook was written for (Emeterio M. Sumagang Jr., YNGSoftware):
>
> You are working with a **Solutions Architect** who:
>
> - Builds meaningful solutions that improve lives
> - Challenges the status quo — better always beats conventional
> - Demands **simple and practical** over clever and complex
> - Treats **UX as paramount and non-negotiable** — every user-facing output must be intuitive
> - Maintains a high standard of engineering excellence

---

## General Guidelines

> These are the playbook's default rules. Keep, edit, or remove each one to suit how you work.

- When the orchestrator says **"plan mode"**, plan only — do not execute until **"execute plan"** is explicitly instructed
- Never auto-add your agent name as a co-author
- Code comments and documentation are mandatory
- Before committing, always update the changelog, version, and specs where applicable
- **Always ask permission before reading or writing to the repository by default** — this applies to every repository action (file reads, edits, commits, pushes, etc.) unless the orchestrator has explicitly specified to allow it all the time
- When **grilling** the orchestrator (asking probing questions about a plan, decision, or idea) or **gathering information** (requirements, clarifications, missing details), ask **one question at a time** — wait for the answer before asking the next; never batch several questions into one message
- `<add your own rules here>`

---

## Recommended Repository Framework

For projects involving multiple concurrent AI agents (e.g., an Epic with several independently deliverable slices), use the **Bare Repository + Git Worktrees Pattern**:

> **One Epic → one Epic branch → multiple slice branches → multiple worktrees → multiple agents**

This gives each agent an isolated worktree and branch, keeps `main` protected from direct feature changes, and enforces a controlled promotion path: **Agent → Slice Branch → Epic Branch → Main**.

Two gates are people-only: **a person promotes an issue before an agent may start it, and a person merges every merge request** (or sets, per merge path, that the orchestrator may). Workers never merge; no agent promotes. Slice issues are titled for the outcome (not the step), and the spec lives in `docs/specs/<feature>/` on the Epic branch, never in an issue. Keep an Epic under about two weeks.

See the [Epic Workflow guide](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/guides/epic-workflow.md) for full setup steps, branching rules, the gates, and agent safety guidelines.

---

## Viewing Files

Use the `yngv` command to view files from the CLI instead of dumping raw text: [yngv.ps1](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/scripts/yngv.ps1) on Windows, [yngv.sh](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/scripts/yngv.sh) on macOS/Linux (e.g. `yngv notes.md`). It detects the file extension and renders accordingly — markdown opens rendered in the browser by default (falling back to a styled console view), and any unrecognized file type is shown as plain text. See the script's own help (`Get-Help ./yngv.ps1 -Full`, or `yngv.sh -h`) for requirements, install steps, and usage.

---

## Shared Private Files (Worktrees)

In a bare-repository + worktrees project, private untracked files (`.env`, `secrets/`, `config/`, …) live once in a root `.shared/` folder and are linked into each worktree — never committed, never copied by hand. Every file inside `.shared/`, including nested ones (`config/app.ini`), is linked individually; the matching folders are created as real folders in the worktree. Use [yngshared.ps1](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/scripts/yngshared.ps1) on Windows or [yngshared.sh](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/scripts/yngshared.sh) on macOS/Linux, placed in the project root beside `.bare/` and `.shared/` (the `.sh` version takes the same actions as `--link`, `--copy`, `--unlink`, `--all`, `--name`, `--force`, `--what-if`):

- `-link <worktree>…` or `-link -All` — symlink shared files into worktrees
- `-copy <worktree> -Name <file>` — give a worktree its own independent copy (opt out of sharing); `-Name` takes files only, relative to `.shared/` (`config\app.ini`), never a folder
- `-unlink <worktree>` — turn links back into real copies
- Always preview with `-WhatIf` (`--what-if` in the `.sh`) first; without `-Force` it never overwrites a real file, and `-Force` backs up each file it replaces. `-Force` only ever replaces files: a real folder in the way is left untouched and reported as a warning. Files beneath a folder that is itself a link (an old whole-folder link like `secrets -> ../.shared/secrets`) are skipped with a warning, even with `-Force`, so nothing inside `.shared/` is ever changed through it; remove that folder link by hand (`rm <folder>` without a trailing slash, or `cmd /c rmdir <folder>` on Windows) and re-run

Never edit or delete `.shared/` items casually — a change there affects every worktree that follows the link. See the script's help (`Get-Help .\yngshared.ps1 -Full`, or `./yngshared.sh -h`) and the [Epic Workflow guide](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/guides/epic-workflow.md) for details.

---

## Next

Read [context.md](context.md) for the project-specific context this guide applies to.
