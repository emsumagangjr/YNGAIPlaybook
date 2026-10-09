# YNG Orchestrator: Requirements

Epic: #1 · Branch: `epic/1-orchestrator`

## Purpose

The Epic Workflow guide names a **dispatcher**: the one writer of issue
state, which checks Gate 1, hands slices to agents and moves labels as
the work progresses. This feature delivers that role as an
agent-runnable **orchestrator** skill, plus the **slice worker** agent
it dispatches to.

The orchestrator runs in the main agent session. Workers run as
subagents, one per slice, each in its own slice worktree. A worker's
final message is its report and returns to the orchestrator
automatically.

``` text
            Orchestrator (main session, the dispatcher)
                 │ plans · checks Gate 1 · dispatches · tracks
     ┌───────────┼───────────┐
     ▼           ▼           ▼
  Worker A    Worker B    Worker C     one per slice, own worktree
     │           │           │
     └─ report ──┴─ report ──┘         final message = completion report
```

Neither the orchestrator nor any worker passes a people-only gate: a
person promotes every issue (Gate 1) and a person decides every merge
(Gate 2), per pull request or in advance per merge path (R7).

## Deliverables

``` text
skills/yngorchestrator/SKILL.md     the orchestrator: role, run log, the step sequence
skills/yngorchestrator/locate.md    step: locate the root and the issue (R14, R15, R25)
skills/yngorchestrator/worktree.md  step: find or create the branch and worktree (R16, R17)
skills/yngorchestrator/scoped.md    step: run one slice or standalone issue (R19, R20)
skills/yngorchestrator/plan.md      step: planning (R3)
skills/yngorchestrator/dispatch.md  step: dispatch (R4)
skills/yngorchestrator/track.md     step: tracking (R5)
skills/yngorchestrator/merge.md     step: merge by rule (R7)
skills/yngorchestrator/report.md    the completion report format (R1)
agents/slice-worker.md              the worker (R2)
templates/yngorchestratorconfig.yml the project config template (R7)
templates/yngaiplaybookreadme.md    the root folder's README template (R26)
```

Each step lives in its own file, reached from `SKILL.md` only when that
step runs, so the entry file stays short and each step can change
without touching the others.

The orchestrator is user-invoked (`/yngorchestrator`): running an Epic is a
person's decision, so it carries no always-loaded description.

Installed per project without being committed to it (R8).

------------------------------------------------------------------------

## R1 Completion report

Slice: #2

1.  Every worker ends with one report in a single shared format:

    ``` text
    STATUS:        done | blocked | failed | needs-human
    SUMMARY:       what was delivered, in one or two sentences
    BRANCH:        slice branch name
    PR:            pull request URL, or "none"
    COMMITS:       short SHAs and subjects
    TESTS:         what ran and the result
    REVIEW RECORD: open decisions only, or "none"
    ISSUES:        new issues opened, or blockers and their cause
    ```

2.  The format is defined once, in `skills/yngorchestrator/report.md`. The
    worker and the orchestrator both reference it; neither restates it.
3.  Every field appears, in order, even when its value is "none".
4.  `needs-human` states its reason, so the orchestrator can hand the
    slice back without re-reading the work.

## R2 Slice worker

Slice: #3

1.  Works only in the worktree path and on the branch it is given.
    Checks `git status` and the current branch first and refuses on a
    mismatch: it reports `blocked`, names the mismatch, and leaves the
    worktree untouched.
2.  Runs the guide's chain inside `in-progress`: optional lead-in (a
    bug defaults to *diagnose*, a refactor to *design the seam*), then
    implement test-first, then code review last. Review uses the
    project's code-review skill when it has one, and otherwise checks
    the diff against the project's written standards and the acceptance
    criteria. Fixes what review finds that it can fix; puts only open
    decisions in the review record.
3.  Updates the spec on the Epic branch in the same change as the code
    it describes.
4.  Pushes the slice branch and opens a pull request into the Epic
    branch. Never merges. Never changes labels.
5.  Stops with `needs-human` on anything in *Never promoted to
    `ready-for-agent`* that surfaces during the work. Unsure means
    human.
6.  Follows the guide's *Agent Safety Rules* (section 20).
7.  Ends with the R1 report.

## R3 Planning

Slice: #4

1.  Reads the Epic and its spec and proposes slices, each titled for
    its outcome, with acceptance criteria and a link to the spec
    section it implements.
2.  Marks for `workflow:ready-for-human` any slice touching production
    schema, authentication or authorisation, a human-only step, or
    anything it is unsure about.
3.  Records dependencies between slices, so that independent slices
    can run in parallel, and notes the files each slice edits: slices
    that run in parallel own separate files, or the overlap is named.
    Proposes a lead-in only when it differs from the default.
4.  Shows the plan to the person as one table. Only after approval does
    it create the slice issues, as sub-issues of the Epic, at
    `workflow:needs-triage`, and logs each to the run log. It never sets
    `workflow:ready-for-agent`; it tells the person which slices are
    ready to promote, and to which label.

## R4 Dispatch

Slice: #5

1.  Dispatches only issues labelled `workflow:ready-for-agent`, and
    only after reading the issue timeline and confirming a human
    account applied that label (the guide's provenance check). Refuses
    and reports otherwise. A human account is a timeline `labeled`
    event whose actor has type `User`, no `[bot]` login, and no
    `performed_via_github_app`. A label applied through the person's
    own token passes this check, so the orchestrator never applies
    `workflow:ready-for-agent` itself.
2.  Creates the slice worktree from the Epic branch, following the
    guide's naming, and records the Epic on the branch:

    ``` bash
    git --git-dir=.bare worktree add -b slice/<n>-<name> slice-<epic>-<name> <epic branch>
    git --git-dir=.bare config branch.slice/<n>-<name>.epicid <epic n>
    ```

3.  Links `.shared/` files into the worktree with `yngshared` when the
    project has a `.shared/` folder.
4.  Launches one slice worker per slice. Independent slices launch in
    parallel; a dependent slice waits for its inputs to merge into the
    Epic branch. Each prompt is self-contained: issue number and
    acceptance criteria, worktree path, branch, spec section.
5.  Sets `workflow:in-progress` when it hands the slice out.

## R5 Tracking

Slice: #6

1.  Acts on every report:

    | Report STATUS | Orchestrator action                                         |
    |---------------|-------------------------------------------------------------|
    | `done`        | Confirms the PR is open into the Epic branch; sets `workflow:in-review`; comments the open decisions |
    | `blocked` / `failed` | Re-dispatches once with the added context; on a second failure sets `workflow:ready-for-human` and comments the report |
    | `needs-human` | Sets `workflow:ready-for-human`; comments the reason        |

2.  After a person merges a slice PR into the Epic branch: pulls the
    Epic worktree, closes the slice issue with a note naming the Epic
    branch, then removes the slice worktree and its local branch.
3.  Keeps one run log per Epic at
    `<root>/.yngaiplaybook/yngorchestratorruns/<epic>.md` (R8), so an interrupted run can resume where it stopped and the log
    outlives the Epic worktree. `SKILL.md` defines the log's location and line format;
    `track.md` says what each report adds to it.
4.  Is the only writer of issue state during the work. Merges only on
    an `auto` path (R7).

## R6 Documentation

Slice: #7

1.  README lists the skills and agents and how to install them.
2.  `guides/epic-workflow.md` gains section 25 on running the dispatcher
    as an orchestrator, linked from *Who moves the labels*.
3.  CHANGELOG entry; `VERSION` and the guide header move to 1.1.0.

## R7 Merge rules

Slice: #14

1.  A project sets who merges each kind of pull request in
    `<root>/.yngaiplaybook/yngorchestratorconfig.yml` (R8):

    ``` yaml
    merge:
      slice-to-epic: required   # required | auto
      epic-to-main: required
      fix-to-main: required
    ```

    `required`: a person merges. `auto`: the orchestrator merges.
2.  `templates/yngorchestratorconfig.yml` ships with every path
    `required`. A missing file, missing key, or any value other than
    `auto` means `required`.
3.  The config belongs to no branch, so no branch or pull request can
    grant itself `auto`. The orchestrator reads it fresh at every merge.
4.  On `auto`, it merges only when the report is `done` (for
    `epic-to-main`, every slice is closed), the pull request is open
    and mergeable from the expected branch into the expected base,
    every check passed, and the review record is "none". Otherwise the
    pull request stays with the person, with the held condition
    commented on it.
5.  It merges with a merge commit and deletes the head branch, then
    runs the post-merge path of R5.2.
6.  Workers never merge. `fix-to-main` governs the pull request of a
    standalone run (R20).

## R8 Standalone install

Slice: #16

1.  Nothing of the orchestrator is committed to the project that uses
    it. Everything lives in the project root `<root>`, the folder
    holding `.bare/`, outside every worktree:

    ``` text
    <root>/.shared/.claude/skills/yngorchestrator/  the skill
    <root>/.shared/.claude/agents/slice-worker.md   the worker
    <root>/.yngaiplaybook/README.md                 the folder explained (R26)
    <root>/.yngaiplaybook/yngorchestratorconfig.yml merge rules (R7)
    <root>/.yngaiplaybook/yngorchestratorruns/<epic>.md  run log per Epic (R5)
    ```

2.  `yngshared` links the skill and worker into each worktree, one
    symlink per file; `<root>/.bare/info/exclude` hides them from Git
    in every worktree, with no `.gitignore` change.
3.  The orchestrator finds `<root>` from inside any worktree with
    `git rev-parse --git-common-dir`.
4.  Upgrading is re-copying into `<root>/.shared/`: every linked
    worktree sees the new files at once.
5.  One command installs or upgrades it: `scripts/yngorch.ps1` (Windows)
    or `scripts/yngorch.sh` (macOS/Linux), run from anywhere inside the
    project. It performs 1-4, links every worktree through `yngshared`,
    and creates or updates the workflow labels when `gh` is available.
    Re-running is safe; it never overwrites the config. (Slice #18.)
6.  `INSTALL.md` gives the whole path two ways: by hand, or by a person
    pointing their agent at this repository. The agent's procedure
    checks the machine and the layout, proposes any layout change and
    waits for approval, installs, and reports; it never commits to the
    project or moves an existing folder.

------------------------------------------------------------------------

## R9 Skill name

Slice: #22

1.  The skill is invoked as `/yngorchestrator`. It lives in
    `skills/yngorchestrator/`, and its frontmatter `name` is
    `yngorchestrator`.
2.  Every path that names the skill folder (the worker, the dispatch
    prompt's `REPORT` field) points at `skills/yngorchestrator/`.

## R10 Skill identity

Slice: #23

1.  `SKILL.md` frontmatter identifies the skill: `name`,
    `description`, `license` (CC-BY-4.0, as the playbook's guides and
    templates), and a `metadata` block with its display name
    (YNG Orchestrator), version, author, company and homepage.
2.  Under its title, the body opens with one line naming it: YNG
    Orchestrator, part of YNGAIPlaybook, by YNGSoftware.
3.  The frontmatter `version` moves with `VERSION`.

## R11 Run-state folder

Slice: #24

1.  The person's config and the run logs live in `<root>/.yngaiplaybook/`
    (`yngorchestratorconfig.yml`, `yngorchestratorruns/<epic>.md`; R23).
2.  The installer writes there. An older `<root>/.orchestrator/` or
    `<root>/.yngorchestrator/` moves there as R24 says.
3.  On upgrade, the installer removes what the old name left behind:
    `<root>/.shared/.claude/skills/orchestrate/`, the links to it in
    every worktree, and its `.bare/info/exclude` line.

## R12 Documentation naming

Slice: #25

1.  README, INSTALL, guide section 25, the config template and the
    specs name the product **YNG Orchestrator**, the command
    `/yngorchestrator`, the folders `skills/yngorchestrator/` and
    `<root>/.yngaiplaybook/` (R23). "The orchestrator" stays as the role's
    name in running text.
2.  The spec folder is `docs/specs/yngorchestrator/`.
3.  CHANGELOG entry; `VERSION` and the guide header move to 1.2.0.

------------------------------------------------------------------------

## R13 The yngv viewer

Slices: #32 (Windows), #33 (macOS/Linux), #34 (docs)

1.  The installer also installs `yngv`, the playbook's file viewer, for
    the person running it, in the user folder `~/.local/bin`, which its
    own help names as the install location:
    -   `yngorch.ps1`: `$HOME\.local\bin\yngv.ps1` and a `yngv.cmd` shim
        beside it, so a bare `yngv` resolves from cmd, PowerShell and
        bash;
    -   `yngorch.sh`: `~/.local/bin/yngv` (from `yngv.sh`), executable.
2.  Re-running overwrites only those files: it is the upgrade path.
3.  `yngorch.ps1` adds the folder to the user's PATH when it is
    missing, and says to open a new terminal. `yngorch.sh` edits no
    shell startup file: when the folder is not on PATH it prints the
    `export PATH=...` line to add.
4.  `-SkipViewer` / `--skip-viewer` skips this step.
5.  Nothing inside the project changes for `yngv`; it is per user, not
    per project.

------------------------------------------------------------------------

## R14 Invocation from anywhere

Slices: #41 (items 1-3)

1.  `/yngorchestrator <issue>` runs from a session started in the
    project root, in any worktree, or in any folder below a worktree.
2.  `<issue>` is a number (`39`), `#39`, or the issue's URL.
3.  The orchestrator finds `<root>` from any of those places: from
    `git rev-parse --git-common-dir` inside a worktree, and from the
    folder holding `.bare/` when the session started at the root,
    which is outside Git.
4.  `yngshared` (`.ps1` and `.sh`) `-link` / `--link` also links every
    file of `<root>/.shared/.claude/` into `<root>/.claude/`, one
    relative symlink per file, by the same rules as a worktree, so a
    session started at the root lists the skill and the worker:
    -   only `.claude/` goes to the root; `.env` and other items do not;
    -   re-running keeps existing links, and a real file is kept unless
        `-Force` / `--force` backs it up and links over it;
    -   `-Name` / `--name` and `-WhatIf` / `--what-if` apply as they do
        to worktrees; `-copy` and `-unlink` leave the root alone;
    -   `<root>/.claude/` is outside every worktree, so no exclude line
        is written for it.

    `yngorch` (`.ps1` and `.sh`) runs `yngshared -link -All`, so it
    links the root along with every worktree.
5.  Claude Code's docs do not say how it finds skills in a folder
    outside Git. 4 is accepted only once a person has started a
    session at the root and seen `/yngorchestrator` listed. If it is
    not listed, the root gets a `yngorch <issue>` launcher instead,
    which starts Claude Code in the target worktree with the command.

## R15 Issue check and kind

Slice: #41

1.  The issue must exist in `origin`'s repository. A URL to another
    repository, or a number with no issue, stops the run with the
    reason; so does a pull request's number or URL.
2.  The orchestrator classifies the issue:
    -   **Epic**: it carries the `epic` label, or has sub-issues;
    -   **slice**: it has a parent issue;
    -   **standalone**: neither.

    When the signals conflict (an `epic` label or sub-issues, together
    with a parent), it stops and asks the person which it is.
3.  A closed issue is not refused. The orchestrator shows its state
    (closed, its pull request and branch if any) and asks whether to
    reopen it and continue; it reopens only on the person's yes. A
    closed Epic with open slices is shown as inconsistent, with those
    slices listed.
4.  The run stays within the issue's boundary: an Epic run drives the
    Epic (R3-R7), a slice run that slice (R19), a standalone run that
    issue (R20).

## R16 Branch lookup

Slice: #43

1.  A `Branch:` line in the issue body names the branch, and wins.
2.  Otherwise the branch is the one matching `*/<n>-*`, looked up in
    local branches first, then on `origin` (fetched first), which is
    consulted only when no local branch matches.
3.  The prefix must fit the kind: `epic/` for an Epic, `slice/` for a
    slice, `fix/` for a standalone issue. A mismatch stops the run.
4.  More than one match stops the run with the matches listed.
5.  A slice's Epic is its parent issue; the Epic branch is found the
    same way.

## R17 Branch and worktree setup

Slice: #43

The procedure is `skills/yngorchestrator/worktree.md`, reached from
`locate.md` for an Epic run. Slice (R19) and standalone (R20) runs
reach it from `scoped.md`, only after their Gate 1 check.

1.  Per the branch's state:
    -   **local, with a worktree**: fetch, and fast-forward it when it
        is behind `origin`. A branch that has diverged is reported and
        left as it is, as is one ahead of `origin` or one a
        fast-forward cannot reach for uncommitted changes;
    -   **local, no worktree**: create the worktree;
    -   **only on `origin`**: fetch it, create a local tracking branch
        and its worktree;
    -   **nowhere**: for a slice, create it from the Epic branch; for a
        standalone issue, from `origin/main`. For an Epic, propose
        `epic/<n>-<name>` (or the `Branch:` line's name) from
        `origin/main` and create it only once the person confirms the
        name. A slice whose Epic has no branch stops the run.

    A new branch is created with `--no-track`, so it does not track
    its start point; its first push sets its upstream.
2.  Worktree directories follow the guide's naming: `epic-<name>`,
    `slice-<epic>-<name>`, `fix-<name>`. `<name>` is a short kebab-case
    form of the issue's title, or, for a branch that already exists,
    the branch's name after `<prefix><n>-`. `<epic>` is the Epic
    worktree's name without `epic-`. A folder already at that path
    stops the run.
3.  Every branch created records its Epic in
    `branch.<branch>.epicid`; an Epic branch records its own number.
    A standalone `fix/` branch has no Epic and records nothing.
4.  A new worktree gets the skill and worker linked in through
    `<root>/yngshared` (`-link <worktree>` / `--link <worktree>`).
    When `<root>/.shared/` or `yngshared` is missing, the project was
    never installed: the run stops, before creating anything, and names
    `yngorch` to run once.
5.  An Epic run stops when `docs/specs/<feature>/requirements.md` is
    missing on the Epic branch: planning (R3) has nothing to cut. The
    orchestrator does not write the spec. `<feature>` comes from the
    Epic body's `Spec:` line, or else from the one spec on the Epic
    branch whose header reads `Epic: #<n>`; neither stops the run too.

## R18 Working from any session

Slice: #41

1.  The session stays where it was started. Every command on the
    target runs by absolute path: `git -C <worktree>` or
    `git --git-dir=<root>/.bare`, the spec read from
    `<worktree>/docs/specs/...`, `WORKTREE:` given to workers as an
    absolute path. Every `gh` command names the repository with
    `-R <owner>/<repo>`, taken from `origin`.
2.  Nothing depends on the session's own folder, so a run started at
    the root, in `main/`, or in the target worktree behaves the same.

## R19 Slice run

Slice: #45

The procedure is `skills/yngorchestrator/scoped.md`, reached from
`locate.md` for a slice or a standalone issue. It runs that one issue
to its hand-back; the Epic run's planning and dispatch rounds do not
run.

1.  A run on a slice handles that slice only: Gate 1 provenance (R4),
    its `Depends on:` issues closed, one `slice-worker` dispatched,
    its report tracked (R5), and its pull request merged by the
    `slice-to-epic` rule (R7). Both checks run before `worktree.md`
    (R17), so no branch is created for a slice that fails them.
2.  A failed Gate 1 check or an open dependency stops the run with the
    reason, naming who applied the label or each open dependency. The
    orchestrator never applies `workflow:ready-for-agent`; a slice left
    at `workflow:in-progress` by an ended run fails Gate 1 until a
    person promotes it again.
3.  After the merge it closes the slice and removes its worktree and
    local branch (R5.2), for that slice only. It then names the
    slices the merge unblocked (the Epic's open slices whose
    `Depends on:` names it and whose dependencies are now all closed),
    and does not dispatch them: that is an Epic run.
4.  A run on an issue at `workflow:in-review` resumes from its pull
    request: an open one goes to the merge rule, a merged one to the
    post-merge step. A `required` path or a held merge ends the run at
    `workflow:in-review`; once a person has merged, a new run on the
    issue closes it.

## R20 Standalone run

Slice: #45

1.  A run on a standalone issue checks Gate 1 (R4), uses
    `fix/<n>-<name>` from `origin/main` and its worktree, and
    dispatches one `slice-worker` with `PR BASE: main` and
    `SPEC: none`: the issue's acceptance criteria are the whole
    contract, and the worker edits no spec.
2.  Its pull request merges by the `fix-to-main` rule in
    `<root>/.yngaiplaybook/yngorchestratorconfig.yml`: `auto` through `merge.md`,
    otherwise a person merges. A missing key means `required`, as for
    every path (R7).
3.  After the merge it closes the issue, if no closing keyword already
    did, naming `main`, and removes the `fix/` worktree and local
    branch. R19.4's resume applies the same way.

## R21 Run log and lock

Slice: #44

1.  An Epic run and a slice run append to the Epic's log,
    `yngorchestratorruns/<epic>.md`, so a later Epic run resumes from
    what a slice run did. A standalone run logs to
    `yngorchestratorruns/<n>.md`.
2.  A run holds `yngorchestratorruns/<n>.lock` for the log it writes, holding the
    time it started and the session's folder, and deletes it when it
    ends: at hand-back, and on every stop after taking it. A slice run
    takes its Epic's lock. The lock is taken once the issue's kind is
    known, before the run can write issue state (reopening a closed
    issue included), and created only when absent, so two runs
    starting together cannot both hold it.
3.  A run that finds the lock present stops and shows its contents:
    one writer of issue state at a time. A lock left by a crashed run
    is deleted by the person; the orchestrator never deletes a lock it
    did not create.

## R22 Documentation and version

Epic: #39 · Slice: #46

1.  Every script change lands in both `.ps1` and `.sh`.
2.  README, INSTALL and guide section 25 say the command runs from
    anywhere in the project and takes an Epic, a slice or a
    standalone issue.
3.  CHANGELOG entry; `VERSION`, the skill's `metadata.version` and the
    guide header move to 1.4.0.

------------------------------------------------------------------------

## R23 The playbook's root folder

Epic: #54

1.  Every YNGAIPlaybook file kept in the project root lives under
    `<root>/.yngaiplaybook/`, beside `.bare/` and outside every
    worktree. Nothing in it is committed. `.shared/` stays where it is.
2.  Each item in it is named `<tool><purpose>`, with no separator, so
    tools sharing the folder cannot collide:

    ``` text
    <root>/.yngaiplaybook/
    ├── README.md                       the folder explained (R26)
    ├── yngorchestratorconfig.yml       merge rules (R7)
    └── yngorchestratorruns/
        ├── <epic>.md                   run log (R5, R21)
        └── <n>.lock                    run lock (R21)
    ```

3.  A future feature that keeps files in the root puts them here,
    named by 2, and gets a section in the README (R26).

## R24 Migration

Epic: #54

1.  `yngorch` (`.ps1` and `.sh`) moves an older folder into the new
    layout, keeping every file's contents:

    | Found                                  | Moves to                                      |
    |----------------------------------------|-----------------------------------------------|
    | `.yngorchestrator/config.yml` (1.2.0-1.4.0) | `.yngaiplaybook/yngorchestratorconfig.yml` |
    | `.yngorchestrator/runs/`               | `.yngaiplaybook/yngorchestratorruns/`         |
    | `.orchestrator/config.yml` (1.1.0)     | `.yngaiplaybook/yngorchestratorconfig.yml`    |
    | `.orchestrator/runs/`                  | `.yngaiplaybook/yngorchestratorruns/`         |

    Any other file in the old folder moves to `.yngaiplaybook/` as it
    is. The emptied old folder is removed.
2.  When `.yngaiplaybook/` already exists, or both old folders exist,
    it moves nothing, leaves every folder as it is, and warns, naming
    them: the person moves what they need by hand.
3.  It says what it moved, one line per item.
4.  Re-running after a migration is safe: it finds only
    `.yngaiplaybook/` and keeps the config (R8.5).

## R25 Unmigrated root

Epic: #54 · Slice: #56

1.  `/yngorchestrator` reads and writes only the R23 paths: the config
    in `merge.md`, the run log and lock in `SKILL.md`, and every other
    step or prompt that names them.
2.  A run that finds `<root>/.yngorchestrator/` or
    `<root>/.orchestrator/` and no `<root>/.yngaiplaybook/` stops
    before taking the lock or touching anything, and names `yngorch`
    to re-run: it migrates (R24). The skill never migrates, and never
    reads the old paths. The check is the end of `locate.md` step 1,
    once `<root>` is found: it tests only that the folders exist. A
    root with none of the three folders is a fresh install and runs.

## R26 The folder's README

Epic: #54

1.  `yngorch` writes `<root>/.yngaiplaybook/README.md` from
    `templates/yngaiplaybookreadme.md` on every install, overwriting
    it, with `{{VERSION}}` replaced by the playbook's `VERSION`. It is
    the playbook's file, not the person's.
2.  Its first lines say it is generated by `yngorch` and that edits
    are replaced on the next install.
3.  It says, briefly:
    -   what the folder is: the playbook's files for this project,
        beside `.bare/`, never committed;
    -   the layout tree (R23.2), one line per item;
    -   the `<tool><purpose>` naming rule for future files;
    -   one section per feature with files here (today
        `yngorchestrator`): each file's purpose, its owner (the person
        or the playbook), whether `yngorch` overwrites it, and how to
        change it (the `merge` keys and their values);
    -   links to the playbook's INSTALL and guide section 25;
    -   the installed playbook version.

    It does not repeat how the orchestrator works: it links.
4.  The README and its install step land in the same slice as the
    layout and migration (R23, R24).

## R27 Documentation and version

Epic: #54

1.  Every script change lands in both `.ps1` and `.sh`.
2.  `templates/orchestrator-config.yml` is renamed
    `templates/yngorchestratorconfig.yml`; its header names the new
    path.
3.  README, INSTALL, guide section 25 and its root-layout tree name
    the R23 paths, and link to the folder's README (R26).
4.  CHANGELOG entry; `VERSION`, the skill's `metadata.version` and the
    guide header move to 1.5.0. Earlier CHANGELOG entries are history
    and keep their paths.
