# Changelog

All notable changes to YNGAIPlaybook are documented here. The version in `VERSION` and in the header of `guides/epic-workflow.md` is kept in sync with the latest entry.

---

## [1.1.0] — 2026-10-08

The dispatcher, as an agent.

### Added
- `skills/orchestrate/` — the orchestrator skill (`/orchestrate`): plans an Epic into outcome-titled slices, dispatches only slices a person promoted to worker subagents in their own worktrees, acts on each completion report, and closes slices after a person merges. Steps in `plan.md`, `dispatch.md`, `track.md`; the report format in `report.md`.
- `agents/slice-worker.md` — the worker agent: carries one slice from its worktree to an open pull request into the Epic branch and ends with a completion report.
- `templates/orchestrator-config.yml` and `skills/orchestrate/merge.md` — merge rules: per path (`slice-to-epic`, `epic-to-main`, `fix-to-main`), `required` (a person merges, the default) or `auto` (the orchestrator merges once the work is done, checks pass and no decision is open). Read from `main` only.
- `docs/specs/orchestrator/` — the feature's requirements and decisions.

### Changed
- `guides/epic-workflow.md` — Gate 2 can be decided in advance per merge path (section 6, *Gate 2 by policy*); rules 8 and 12 updated to match.
- `guides/epic-workflow.md` section 25 — running the dispatcher as an orchestrator: install and run.

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
