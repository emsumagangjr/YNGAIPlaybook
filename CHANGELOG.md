# Changelog

All notable changes to YNGAIPlaybook are documented here. The version in `VERSION` and in the header of `guides/epic-workflow.md` is kept in sync with the latest entry.

---

## [1.10.0] — 2026-10-14

A worktree's folder names its issue, and a slice's folder names its Epic too; the issue records its branch and worktree.

### Added
- When the orchestrator creates a branch for an issue, it adds a ``Branch: `<branch>` `` line to the end of the issue body, unless the body has one, so later runs find the branch by name. A branch that already existed adds nothing.
- Each dispatch to a worker comments ``Dispatched: branch `<branch>`, worktree `<folder>` `` on the issue, once per dispatch.

### Changed
- A worktree the orchestrator creates is named for its issue: `epic<n>-<name>` for an Epic, `epic<e>-slice<n>-<name>` for a slice, with `<e>` its parent issue's number, and `fix<n>-<name>` for a standalone issue. Numbers are the issues repo's, unpadded, as the branch writes them; a tracker with keyed IDs puts the key in as written. Branch names are unchanged. `worktree.md` (Epic, slice and standalone runs) and step 2 of `dispatch.md` both use these names.
- Existing worktrees keep their folders: branches and worktrees are found by branch, so a folder named the older way (`epic-<name>`, `slice-<epic>-<name>`, `fix-<name>`) works as before. Nothing renames or moves a worktree.
- The guide, INSTALL and README use the new names in every section, example, tree, table and command, and the guide's examples use plain issue numbers (`epic/100-authentication` in `epic100-authentication`, `slice/101-oauth` in `epic100-slice101-oauth`, `fix/140-login-redirect` in `fix140-login-redirect`). Section 3 describes the naming, keeps one note for trackers with keyed IDs, and says older folders still work. The spec gains R43-R45.

---

## [1.9.0] — 2026-10-14

A reinstall keeps every setting in your config and adds the new ones.

### Added
- When `.yngaiplaybook/yngorchestratorconfig.yml` exists, `yngorch` (`.ps1` and `.sh`) brings it up to date with its template: each setting the template has and the file lacks is added whole, with its comments, just above the worked examples (at the end of a file without them), and each missing key under a setting active in the file is added after that block's last key, with the template's trailing comment. Nothing already in the file is changed, removed or reordered, and its line endings stay as they are. A setting kept with its key commented out stays so; one deleted, header and key, comes back at its default. Re-running adds nothing.
- Before its first change, `yngorch` copies the config to `yngorchestratorconfig.yml.bak` beside it, replacing an older backup; with nothing to add it writes none. It prints a `backed up` line and one `added` line per setting or key, or `kept ... (yours, nothing new)`.
- A key it cannot add line by line (its parent's value on the parent's own line, the parent set twice, or the keys under it indented with a tab or unevenly) is a `warning` naming the reason and the exact line to paste by hand. An active key the template does not have stays as it is, with a `note` that the orchestrator ignores it.
- The upgrade is one routine per script over a list of template and config pairs, so a config file added later needs no new upgrade code. Every config template keeps one `# --- Setting: <name> ---` header per top-level key and its worked examples below a `# ====` banner.

### Changed
- When an old `.yngorchestrator/` or `.orchestrator/` stops the migration, the config is not upgraded either, and a `skipped` line says so.
- The config template's header, each setting's *Changed by* line, the folder's README (its layout now shows `yngorchestratorconfig.yml.bak`), INSTALL and guide section 25 describe the upgrade and the backup. The spec gains R39-R42.

---

## [1.8.0] — 2026-10-13

A person can give Gate 1 by approving an Epic's plan, when the config says so.

### Added
- The config gains a top-level `auto-promote: yes | no` key, Gate 1's advance decision, beside the `merge:` rules for Gate 2. Absent, or any value other than `yes` or `true` (any case), it is `no`, and every project without the key works as before. The orchestrator reads it fresh at the start of every run.
- With `auto-promote: yes`, approving an Epic's plan promotes the slices it routes to an agent: they are created `workflow:ready-for-agent` and dispatched in the same run, with no second invocation. The plan table says so above it. On a re-plan, only the new slices the person approved are promoted.
- Each slice promoted by plan approval gets a comment (`Promoted by plan approval (auto-promote: yes), <date>. ...`) and a run-log line (`<date> #<n> promoted by plan approval`).

### Changed
- Dispatch's Gate 1 check passes a slice by either route: a person applied the last `workflow:ready-for-agent`; or `auto-promote:` is `yes` now, the slice is a sub-issue of the Epic being run, and the Epic's run log has its plan-promotion line. The label the orchestrator set at creation never counts as a person's, and a plan promotion is used once: a slice labelled again later needs a person's label. A pass by plan approval logs `gate 1 by plan approval`.
- Plan approval never promotes a slice on the guide's *Never promoted to `ready-for-agent`* list (it is created `workflow:ready-for-human` and listed in the hand-back ahead of what it holds up), a standalone issue, or a slice created by hand. Switching back to `no` withdraws every plan promotion.
- `templates/yngorchestratorconfig.yml` documents every key (what it decides, its values, default, when it is read, who changes it), glosses its terms, and ends with two worked examples: the default and hands-off. The folder's README template gives every key the same facts as a table.
- `yngorch` describes the `workflow:ready-for-agent` label as set by a person or by plan approval, and its closing lines name `auto-promote` beside the merge rules.
- Guide section 6 gains *Gate 1 by plan approval*, beside *Gate 2 by policy*; section 25 gains *Auto-promote*. README and INSTALL mention `auto-promote:` where they mention `merge:`, and `templates/agents.md` names plan approval as the second way a person promotes. The spec gains R33-R38.

---

## [1.7.0] — 2026-10-13

A project can keep its issues in a separate GitHub repository from its code.

### Added
- The config gains a top-level `issues: <owner>/<repo>` key naming the project's **issues repo**; code, branches and pull requests stay in `origin`'s repository, the **code repo**. Absent, empty, or naming the code repo, the two are one repository, as before. `templates/yngorchestratorconfig.yml` documents it, commented out, and `templates/yngaiplaybookreadme.md` gives it a line.
- `yngorch` takes `-IssuesRepo <owner>/<repo>` (`.ps1`) and `--issues-repo <owner>/<repo>` (`.sh`). It writes the `issues:` key only when the config has no value yet, and reports an existing value without overwriting it. Any other form, a URL included, stops the install before anything is written.

### Changed
- `yngorch` creates the labels in the issues repo: the flag's value, else the config's `issues:` value, else `origin`'s repository. A malformed config value, with no flag, skips the labels with a warning.
- `/yngorchestrator` reads the `issues:` key at the start of every run and stops before the lock on a value that is not `<owner>/<repo>`. Every issue command targets the issues repo and every code command the code repo, each `gh` call naming its repository with `-R`. A URL argument must name the issues repo.
- Issues are named by full reference, `<owner>/<repo>#<n>`, wherever the code repo's side names them, with or without the `issues:` key: the dispatch prompt's `ISSUE` field, commits, and pull requests. A slice's pull request says `Implements <owner>/<repo>#<n>`; a fix pull request and the Epic's pull request into `main` say `Closes <owner>/<repo>#<n>`.
- README, INSTALL and guide section 25 describe the issues repo: when to use one, the key, the install flag, and full references across the two repositories. The spec gains R28-R32.

---

## [1.6.0] — 2026-10-12

Agents tell specs from context, and flag spec decisions that should become project rules.

### Added
- `templates/agents.md` gains a **Specs and Context** section. `context.md` is the project's standing brief; `docs/specs/<feature>/` (`requirements.md`, `decisions.md`) is one feature's contract, and only an Epic needs one. Agents never edit `context.md`: a decision that should hold project-wide ends its `decisions.md` entry with `→ context` and is listed under **Promote to context** in the pull request, for the owner to promote at the Epic's spec-level review.

---

## [1.5.0] — 2026-10-09

The playbook's files in your project root live in one folder, `.yngaiplaybook/`.

### Added
- `<root>/.yngaiplaybook/` holds every playbook file kept in the project root, beside `.bare/` and never committed: `yngorchestratorconfig.yml` (merge rules) and `yngorchestratorruns/` (run logs and locks). Each item is named `<tool><purpose>`, so tools sharing the folder cannot collide.
- `templates/yngaiplaybookreadme.md`: `yngorch` writes it as `<root>/.yngaiplaybook/README.md` on every install, with the playbook version filled in. It explains each file, who owns it, whether the installer overwrites it, and the merge keys.
- `yngorch` (`.ps1` and `.sh`) moves an older `.yngorchestrator/` (1.2.0-1.4.0) or `.orchestrator/` (1.1.0) into `.yngaiplaybook/`: `config.yml` becomes `yngorchestratorconfig.yml`, `runs/` becomes `yngorchestratorruns/`, other files keep their names, one line per item. When `.yngaiplaybook/` already exists, or both old folders do, it moves nothing and warns.

### Changed
- `/yngorchestrator` reads and writes only the `.yngaiplaybook/` paths. A run on a root that still has `.yngorchestrator/` or `.orchestrator/` and no `.yngaiplaybook/` stops before taking the lock and names `yngorch` to run; the skill never migrates.
- `templates/orchestrator-config.yml` is renamed `templates/yngorchestratorconfig.yml`.
- README, INSTALL and guide sections 6 and 25 name the new paths and link to the folder's README. The spec gains R23-R27.

---

## [1.4.0] — 2026-10-09

`/yngorchestrator` runs from anywhere in the project, on any issue.

### Added
- `skills/yngorchestrator/locate.md`: `/yngorchestrator <issue>` takes a number, `#<n>` or the issue's URL, from the project root, any worktree or any folder below one. It finds the root, checks the issue is in `origin`'s repository, tells its kind (Epic, slice or standalone), and offers to reopen a closed issue. With no argument inside a worktree, it takes the Epic recorded on the branch.
- `skills/yngorchestrator/worktree.md`: finds the issue's branch (a `Branch:` line in the issue, else `*/<n>-*`, locally then on `origin`) and brings it and its worktree to a known state: fast-forwards a branch behind `origin`, creates a missing worktree or branch, and links a new worktree through `yngshared`. A new Epic branch is created only once the person confirms its name; an Epic run stops when its spec is missing. A `fix/` branch records no `epicid`.
- `skills/yngorchestrator/scoped.md`: a run on a slice handles that slice only (Gate 1, its dependencies, one worker, the `slice-to-epic` merge, closing it) and names the slices its merge unblocked. A run on a standalone issue uses `fix/<n>-<name>` from `origin/main`, one worker with `PR BASE: main` and no spec, and the `fix-to-main` merge rule. Both check Gate 1 before creating any branch, and resume from the pull request on an issue at `workflow:in-review`.
- A run holds `.yngorchestrator/runs/<n>.lock` while it writes issue state, and stops when it finds one held. A slice run logs to, and locks, its Epic's log.
- `scripts/yngshared.ps1`, `scripts/yngshared.sh` (1.2.0): `-link` / `--link` also links `.shared/.claude/` into the project root's own `.claude/`, so a session started at the root finds the skill and worker. `yngorch` links the root along with every worktree.

### Changed
- Every command of a run names its target by absolute path (`git -C`, `git --git-dir`, `gh -R`), so the session stays where it started.
- `dispatch.md` hands a standalone issue's worker `PR BASE: main`; `slice-worker` accepts `SPEC: none`.
- README, INSTALL and guide section 25 say the command runs from anywhere in the project and takes an Epic, a slice or a standalone issue; INSTALL starts an Epic through the orchestrator instead of by hand. The spec gains R14-R22.

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
