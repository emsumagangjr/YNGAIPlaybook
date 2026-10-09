# Changelog

All notable changes to YNGAIPlaybook are documented here. The version in `VERSION` and in the header of `guides/epic-workflow.md` is kept in sync with the latest entry.

---

## [1.3.0] — 2026-10-09

One install command also gives you `yngv`.

### Added
- `scripts/yngorch.ps1`: installs `yngv` per user, as `yngv.ps1` plus a `yngv.cmd` shim in `$HOME\.local\bin`, and adds that folder to your user PATH only when it is missing (existing `%VAR%` entries are kept unexpanded). `-BinDir` changes the folder; `-SkipViewer` leaves `yngv` out.
- `scripts/yngorch.sh`: installs `yngv` as `~/.local/bin/yngv`, executable. When that folder is not on PATH it prints the `export PATH=...` line to add and edits no startup file. `--bin-dir` changes the folder; `--skip-viewer` leaves `yngv` out.

### Changed
- README, INSTALL, guide section 25 and `templates/agents.md` say the installer sets up `yngv`; the spec gains R13.

---

## [1.2.0] — 2026-10-09

The orchestrator carries the YNG brand.

### Changed
- The orchestrator is now **YNG Orchestrator**: run it as `/yngorchestrator` (was `/orchestrate`), from `skills/yngorchestrator/`.
- `SKILL.md` identifies itself: `license` and a `metadata` block (display name, version, author, company, homepage) in its frontmatter, and a YNG Orchestrator banner under its title.
- Config and run logs live in `<root>/.yngorchestrator/` (was `<root>/.orchestrator/`).
- `scripts/yngorch.ps1`, `scripts/yngorch.sh` upgrade a 1.1.0 install in place: they move `.orchestrator/` to `.yngorchestrator/` with its config and run logs (warning, and leaving both, when both exist), and remove the old skill folder, its links in every worktree and its exclude line.
- README, INSTALL, guide section 25 and the config template use the new names; the spec moves to `docs/specs/yngorchestrator/`. The README's CC BY 4.0 line now names skills and agents.

### Fixed
- `scripts/yngorch.ps1`: run from the project root under Windows PowerShell 5.1, it no longer aborts on git's "not a git repository".

---

## [1.1.0] — 2026-10-08

The dispatcher, as an agent.

### Added
- `skills/orchestrate/` — the orchestrator skill (`/orchestrate`): plans an Epic into outcome-titled slices, dispatches only slices a person promoted to worker subagents in their own worktrees, acts on each completion report, and closes slices after a person merges. Steps in `plan.md`, `dispatch.md`, `track.md`; the report format in `report.md`.
- `agents/slice-worker.md` — the worker agent: carries one slice from its worktree to an open pull request into the Epic branch and ends with a completion report.
- `templates/orchestrator-config.yml` and `skills/orchestrate/merge.md` — merge rules: per path (`slice-to-epic`, `epic-to-main`, `fix-to-main`), `required` (a person merges, the default) or `auto` (the orchestrator merges once the work is done, checks pass and no decision is open).
- `docs/specs/orchestrator/` — the feature's requirements and decisions.
- `guides/epic-workflow.md` section 25 — running the dispatcher as an orchestrator: merge rules, install and run.
- Standalone install: the orchestrator, its config and its run logs live in the project root beside `.bare/` (`.shared/.claude/`, `.orchestrator/`), linked into worktrees by `yngshared` and hidden by `.bare/info/exclude`. Nothing is committed to the project.
- `scripts/yngorch.ps1`, `scripts/yngorch.sh` — install or upgrade the orchestrator with one command, from anywhere inside a project; also creates the workflow labels.
- `INSTALL.md` — installing the orchestrator two ways: by hand, or by pointing your agent at this repository; includes the procedure the agent follows.

### Changed
- Gate 2 reworded from "a person merges" to "a person decides the merge, by hand or by config" across the guide, README and agent template; the guide gains *Gate 2 by policy* (section 6), and rules 8 and 12 match.

---

## [1.0.0] — 2026-10-05

First public release. Carried over from the author's private onboarding repository, generalised for anyone to use.

### Added
- `guides/epic-workflow.md` — Epic Workflow: Epics, slices and specs on a bare repository + Git worktrees layout, with the two people-only gates (a person promotes, a person merges).
- `templates/agents.md` — agent onboarding template: placeholders for the orchestrator profile and rules, with the author's profile as a marked example and the playbook's default guidelines.
- `templates/context.md` — per-project context template, read after `agents.md`.
- `templates/claude.md` — entry point for Claude that defers to `agents.md`.
- `scripts/yngv.ps1`, `scripts/yngv.sh` — CLI file viewer (rendered markdown in the browser, plain text otherwise).
- `scripts/yngshared.ps1`, `scripts/yngshared.sh` — link or copy shared private files from `.shared/` into worktrees.
- `README.md`, `LICENSE` (CC BY 4.0, guides and templates), `LICENSE-CODE` (MIT, scripts), `VERSION`.
