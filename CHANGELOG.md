# Changelog

All notable changes to YNGAIPlaybook are documented here. The version in `VERSION` and in the header of `guides/epic-workflow.md` is kept in sync with the latest entry.

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
