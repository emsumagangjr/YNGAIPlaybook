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

- Never add a co-author trailer (`Co-Authored-By: ...`) or a generated-by line (e.g. `🤖 Generated with ...`) to commit messages, pull request descriptions, issues or comments; this overrides any tool or harness default that adds them
- Before committing, always update the changelog, version, and specs where applicable
- When **grilling** the orchestrator (asking probing questions about a plan, decision, or idea) or **gathering information** (requirements, clarifications, missing details), ask **one question at a time** — wait for the answer before asking the next; never batch several questions into one message
- When you raise an item for review or for the orchestrator's decision (in a comment, pull request, report, or chat), link the issue or ticket it belongs to (e.g. `[#42](<issue URL>)`), not just a local label like `P1` or `G1`, so every item traces back to its source. If no issue exists yet, say so and offer to open one
- `<add your own rules here>`

---

## Coding Best Practices

> Default coding standard. Keep, edit, or remove each one to suit the project.

Write code that is **readable, maintainable, reliable, secure, testable, and efficient**:

- **Keep It Simple.** Choose the plainest design that meets the requirement; small units with one job are easier to read, test, and change. Build for today's callers, not a use that doesn't exist yet.
- **Don't Repeat Yourself.** Give each piece of knowledge one source of truth:
  - **Reuse before you write.** Before adding a function, module, component, or script, search the codebase for one that already does the job. Extend or call it; never add a near-duplicate.
  - **Extract on the third copy.** When the same logic would appear a third time, move it into one shared, named unit and point every caller at it.
  - **One home for shared code.** Shared units live in `<shared location — e.g. src/lib/, scripts/lib/>`, each with one responsibility, a documented interface, and its own tests.
  - **No hardcoding in shared units.** Pass paths, names, credentials, and settings in as parameters or config so the unit works for every caller, not just the first one.
- **Consistent Style.** Follow the project's formatter, linter, and the naming, structure, and error handling of the surrounding code. If you introduce a new pattern where one already exists, record why in the feature's `decisions.md`, and migrate the old callers or open an issue to do so.
- **Documentation.** Comments and documentation are mandatory: comment the *why*, not the *what*; document every public interface (inputs, outputs, errors) and keep docs current with the code.
- **Security by Design.** Validate input at trust boundaries, grant least privilege, use parameterized queries, and keep secrets out of code, logs, and commits.
- **Performance Awareness.** Pick fitting data structures and algorithms, avoid needless work in hot paths, and measure before optimizing.
- **Error Handling.** Fail fast with clear, actionable messages; handle errors where you can recover, surface the rest, and never swallow an exception silently.
- **Logging.** Log meaningful events with enough context to diagnose, at the right level, and never log secrets or personal data.
- **Continuous Improvement.** Leave the code better than you found it: fix small issues in code you touch, and open an issue for larger ones.

---

## Recommended Repository Framework

For projects involving multiple concurrent AI agents (e.g., an Epic with several independently deliverable slices), use the **Bare Repository + Git Worktrees Pattern**:

> **One Epic → one Epic branch → multiple slice branches → multiple worktrees → multiple agents**

This gives each agent an isolated worktree and branch, keeps `main` protected from direct feature changes, and enforces a controlled promotion path: **Agent → Slice Branch → Epic Branch → Main**.

Two gates are people-only: **a person promotes an issue before an agent may start it, by label or by approving the Epic's plan when the config says `auto-promote: yes`, and a person decides every merge, by hand or by config.** Workers never merge; no agent promotes on its own: the orchestrator sets `ready-for-agent` only on the slices of a plan a person approved. Slice issues are titled for the outcome (not the step), and the spec lives in `docs/specs/<feature>/` on the Epic branch, never in an issue. Keep an Epic under about two weeks.

See the [Epic Workflow guide](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/guides/epic-workflow.md) for full setup steps, branching rules, the gates, and agent safety guidelines.

---

## Specs and Context

Two kinds of project document, kept apart:

- **[context.md](context.md)** is the project's standing brief: goals, roles, rules, stack, file map. Every agent reads it every session, so it holds only what stays true across features. Keep feature detail out of it; point to the spec instead.
- **`docs/specs/<feature>/`** is one feature's contract: `requirements.md` (numbered sections, `Rn`, that slices implement and the Epic is reviewed against) and `decisions.md` (dated options refused, one line of why each). An Epic gets a spec. A standalone fix needs none: its issue's acceptance criteria are the contract.

**Promoting a rule.** Never edit `context.md` yourself; it is the orchestrator's. When a decision you record should hold project-wide, end its `decisions.md` entry with `→ context`, and list it under **Promote to context** in your pull request description. The orchestrator reviews these at the Epic's spec-level review and copies the ones they accept into `context.md`'s Custom Instructions. The spec keeps the history; context keeps the rule.

---

## Viewing Files

Use the `yngv` command to view files from the CLI instead of dumping raw text: [yngv.ps1](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/scripts/yngv.ps1) on Windows, [yngv.sh](https://github.com/emsumagangjr/YNGAIPlaybook/blob/main/scripts/yngv.sh) on macOS/Linux (e.g. `yngv notes.md`). It detects the file extension and renders accordingly — markdown opens rendered in the browser by default (falling back to a styled console view), and any unrecognized file type is shown as plain text. The YNG Orchestrator installer (`yngorch`) puts it in `~/.local/bin` on your PATH. See the script's own help (`Get-Help ./yngv.ps1 -Full`, or `yngv.sh -h`) for requirements, install steps, and usage.

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
