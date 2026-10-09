# Epic Workflow: Bare Repository + Git Worktrees for Agentic Development

> Compiled by Emeterio M. Sumagang Jr. · YNGSoftware (www.yngsoftware.com)  
> Version 1.3.0 · Created 2026-09-16 · Part of [YNGAIPlaybook](../README.md)

## Purpose

This guide documents a Git workspace and integration pattern for
**agentic software development**, particularly when an Epic contains
multiple slices that can be implemented concurrently by multiple AI
coding agents.

The conceptual principle is:

> **One Epic → one branch → multiple worktrees → multiple agents**

Because Git normally prevents the same branch from being checked out in
multiple worktrees simultaneously, the practical implementation is:

> **One Epic → one Epic branch → multiple slice branches → multiple
> worktrees → multiple agents**

Each slice branch is derived from the Epic branch. Each slice branch
receives an isolated worktree and agent. Completed slices are integrated
back into the Epic branch.

The protected `main` branch receives feature changes **only by merging
completed Epic branches**. Work that belongs to no Epic (a lone fix or
chore) is the one exception; see section 16.

The complete promotion path is:

> **Agent → Slice Branch → Epic Branch → Main**

A person decides what an agent works on and how what it produces is
merged: by hand, or by a rule the person configured. Either way, people
stay in control. The two human gates are described in section 6:

> **Gate 1: a person promotes the issue. Gate 2: a person decides the
> merge, by hand or by config.**

Terminology used throughout: an **Epic** is a feature (a tracker card
plus an integration branch). A **slice** is one independently
deliverable outcome inside it (an issue plus a branch). A **spec** is
the versioned description of the feature. *Slice* replaces the older
word *task*, because a slice is named for the outcome it delivers, not
the step it takes.

`MR` (merge request) and `PR` (pull request) mean the same thing in this
guide; use whichever term your Git host uses.

------------------------------------------------------------------------

## 1. Architecture Overview

A conventional Git clone combines the Git repository metadata and a
single working directory:

``` text
myproject/
├── .git/
├── src/
├── README.md
└── ...
```

With the **Bare Repository + Git Worktrees Pattern**, Git metadata is
centralized while active branches receive separate working directories:

``` text
myproject/
│
├── .bare/                       # shared Git repository
├── .shared/                     # local, untracked files shared by default
│   ├── .env
│   ├── secrets/
│   └── config/
│
├── main/                        # protected main worktree
│   ├── .env -> ../.shared/.env
│   ├── secrets/                 # real folder
│   │   └── api.key -> ../../.shared/secrets/api.key
│   └── config/                  # real folder
│       └── app.ini -> ../../.shared/config/app.ini
│
├── epic-auth/                   # Epic integration worktree
│
├── slice-auth-oauth/            # Slice worktree → Agent A
│
├── slice-auth-permissions/      # Slice worktree → Agent B
│
└── slice-auth-audit/            # Slice worktree → Agent C
```

A corresponding branch hierarchy might be:

``` text
main
│
└── epic/AUTH-100-authentication
      │
      ├── slice/AUTH-101-oauth
      ├── slice/AUTH-102-permissions
      └── slice/AUTH-103-audit
```

The `.bare/` repository owns the shared Git history, objects, refs,
configuration, and worktree metadata.

The root `.shared/` directory holds local files that worktrees follow by
default. A worktree can replace an individual link with its own copy.

------------------------------------------------------------------------

## 2. Core Principles

### Epic-level ownership

An Epic represents a significant body of related work and receives its
own integration branch.

``` text
Epic
  ↓
Epic Branch
```

### Parallel slice execution

The Epic is decomposed into slices that can be assigned independently:

``` text
Epic Branch
    │
    ├── Slice A
    ├── Slice B
    └── Slice C
```

Each slice receives its own branch, worktree, and agent:

``` text
Epic Branch
    │
    ├── Slice Branch → Worktree → Agent A
    ├── Slice Branch → Worktree → Agent B
    └── Slice Branch → Worktree → Agent C
```

### Main is protected

The `main` branch is not a development workspace.

> **`main` can only receive feature changes by merging a completed Epic
> branch.**

There is deliberately no normal development path from an agent or slice
branch directly into `main`.

``` text
Agent ─────────── X ──────────► main

Slice Branch ──── X ──────────► main
```

The supported path is:

``` text
Agent
  ↓
Slice Branch
  ↓
Epic Branch
  ↓
Integration Testing / Review / CI
  ↓
main
```

------------------------------------------------------------------------

## 3. Epics, Slices and Specs

Three objects, three jobs:

| Level         | Object                          | In Git                          | Lives for       |
|---------------|---------------------------------|---------------------------------|-----------------|
| Feature       | Epic (tracker card and parent)  | Epic branch off `main`          | Target 2 weeks  |
| Unit of work  | Issue, child of the Epic        | Slice branch off the Epic branch | Hours to days   |
| Specification | Files in `docs/specs/<feature>/` | Committed on the Epic branch    | Outlives both   |

The separation is the point. When a feature is rebuilt, the issues and
the Epic survive because they describe outcomes; only the spec and the
code change. The Epic gets the tracker's native parent-child progress
rollup, so nobody maintains a checklist by hand. The spec gets version
history, so it is diffed and reviewed alongside the code it describes.

Do not put the spec in a single umbrella issue. An umbrella issue is the
board card, the branch anchor and the spec all at once, and a rebuild
invalidates the spec written in its description.

### The spec folder

``` text
docs/specs/auth/
├── requirements.md      # what the feature must do (reviewed at Epic merge)
└── decisions.md         # dated log of options refused, one line of why each
```

Rejections belong in `decisions.md`, not in an issue. A rejection has to
outlive the code, and a slice issue is closed and its code may be
rebuilt away. If a rejection implies new work, that work becomes its own
issue.

### Two rules for writing an issue

1.  **Title the outcome, not the step.** "Users can sign in with a
    Microsoft account" survives a rebuild. "Add `OAuthService` to the
    auth module" is invalidated by one.
2.  **Do not write the spec into the issue.** The issue carries the
    acceptance criteria for its own slice and a link to the spec
    section. Everything else lives in `docs/specs/`, where it is
    versioned and reviewed with the code.

### Naming

| Item          | Branch                                | Worktree directory | Base            |
|---------------|---------------------------------------|--------------------|-----------------|
| Epic          | `epic/AUTH-100-authentication`        | `epic-auth`        | `main`          |
| Slice         | `slice/AUTH-101-oauth`                | `slice-auth-oauth` | the Epic branch |
| Standalone fix | `fix/AUTH-140-login-redirect`        | `fix-login-redirect` | `main`        |

Use the tracker's issue key in the branch name. Where a tracker numbers
Epics in a different namespace from issues (GitLab uses `&12` for an
Epic and `#12` for an issue), the `epic/` prefix keeps the two readable
at a glance.

A project that already has a branch convention may keep it, provided an
Epic branch, a slice branch and a standalone fix are distinguishable
and every slice branch is created from its Epic branch. Never give one
branch a name that is a path prefix of another: Git cannot hold both
`epic/12` and `epic/12/crm`.

------------------------------------------------------------------------

## 4. Why This Works Well for Agentic Programming

AI coding agents commonly need to inspect source code, edit files,
install dependencies, create migrations, run tests, start development
servers, inspect diffs, and commit changes.

Running multiple agents against one working directory creates
unnecessary interference. An agent can change a file while another agent
is reading or testing it.

Worktrees provide filesystem-level separation:

``` text
                         .bare/
                    Shared Git database
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
 slice-auth-oauth/  slice-auth-permissions/ slice-auth-audit/
        │                  │                  │
        ▼                  ▼                  ▼
     Agent A            Agent B            Agent C
```

This provides:

-   concurrent slice development;
-   isolated files and Git indexes;
-   less branch switching and stashing;
-   shared Git history without multiple full clones;
-   clear slice/agent ownership;
-   easy creation and cleanup of temporary workspaces;
-   parallel builds and tests when runtime resources are also isolated.

------------------------------------------------------------------------

## 5. The Epic as the Integration Boundary

Consider an Epic:

``` text
AUTH-100
Authentication Improvements
```

with slices:

``` text
AUTH-101    Microsoft OAuth
AUTH-102    Role permissions
AUTH-103    Authentication audit logging
```

The branch model becomes:

``` text
main
  │
  └── epic/AUTH-100-authentication
          │
          ├── slice/AUTH-101-oauth
          ├── slice/AUTH-102-permissions
          └── slice/AUTH-103-audit
```

The agent model becomes:

``` text
                  epic/AUTH-100-authentication
                             │
             ┌───────────────┼───────────────┐
             │               │               │
             ▼               ▼               ▼
        AUTH-101          AUTH-102         AUTH-103
             │               │               │
             ▼               ▼               ▼
       Slice Branch    Slice Branch    Slice Branch
             │               │               │
             ▼               ▼               ▼
         Worktree          Worktree         Worktree
             │               │               │
             ▼               ▼               ▼
          Agent A           Agent B          Agent C
```

Individual slice success does not imply that the complete Epic is ready
for `main`. The Epic branch provides a controlled place for integration
testing and conflict resolution.

------------------------------------------------------------------------

## 6. The Two Gates

An agent can triage issues and an agent can write code, so the two
places a person must stand are **promotion** and **merge**. Everything
else may run unattended.

``` text
no workflow label          Inbox
        │
        ▼
workflow::needs-triage     triage fills in every label
        │
        ▼
GATE 1  a person promotes  move the card, or approve the triage
        │
        ├──────────────────────────┐
        ▼                          ▼
ready-for-agent            ready-for-human
an agent picks it up       a person picks it up
        │                          │
        └────────────┬─────────────┘
                     ▼
              in-progress          whole chain runs here, no MR yet
                     │
                     ▼
              in-review            MR is open, waiting for a person
                     │
                     ▼
GATE 2  a person decides the merge by hand, or by config (see below)
                     │
                     ▼
                  Closed
```

`workflow::needs-info` sits beside this flow: a question that must be
answered by a person before work can start. The issue is assigned to
whoever can answer and does not reach an agent until it is answered.

The names above assume a tracker with scoped labels. On a tracker
without them, use a single status field with the same values.

### Never promoted to `ready-for-agent`

Regardless of how confident triage is, these go to `ready-for-human`:

-   schema changes to anything already in production;
-   authentication and authorisation;
-   steps only a human can perform (creating credentials, walking a
    third-party dashboard);
-   anything triage was unsure about.

**Unsure means human, always.**

### Gate 1 is a convention until something checks it

Tracker permissions are usually per action, not per label value: any
identity that can set labels can set `ready-for-agent`. "Triage never
promotes" is therefore a rule in this guide, not something the
permission model enforces.

What enforces it is a provenance check at the point of dispatch. Before
creating a worktree, the dispatcher reads the issue's activity history,
confirms `ready-for-agent` was applied by a human account, and refuses
to dispatch if a bot applied it. A bot can still set the label, but
nothing acts on it, and a bot-applied promotion becomes a visible
anomaly in the activity log instead of silently producing code.

### Who moves the labels

Agents do not update issues. The **dispatcher** does (or the person
running the agents, if there is no dispatcher), and it is the only
writer of issue state during the work. Section 25 runs the dispatcher
as an agent: the *YNG Orchestrator*.

| Transition                      | Set by             | When                                            |
|---------------------------------|--------------------|-------------------------------------------------|
| to `needs-triage`               | triage agent       | it has filled in the other labels               |
| to `ready-for-agent` / `-human` | a person           | Gate 1                                          |
| to `in-progress`                | dispatcher         | it hands the work out, after the provenance check |
| to `in-review`                  | dispatcher         | the MR opens                                    |
| closed                          | dispatcher         | the slice MR merges into the Epic branch        |

### What `in-review` means

The MR is open and waiting for a person. Nothing else. The agent's own
review runs *before* the MR exists (see the agent slice workflow), so it
happens inside `in-progress` and never appears on the board. That is
deliberate: an "agent is reviewing" column would be empty most of the
time and would show nothing anyone can act on. With `in-review` meaning
"your turn", its length is the review backlog, which is the one number
on the board worth watching.

### Gate 2 by policy

A person may decide Gate 2 in advance for a whole kind of merge
instead of for each merge request: slice into Epic, Epic into `main`,
standalone fix into `main`. The decision lives in
`.yngorchestrator/config.yml` in the project root, beside `.bare/` and
outside every worktree, as `required` (a person merges) or `auto` (the
orchestrator merges once the work reports done, every check passes and
the review record holds no open decision). No branch or merge request
can change it, and every path defaults to `required`. See section 25.

### Slice completion

Closing keywords (`Closes #431`) fire only on merges into the default
branch, so a slice merged into an Epic branch does **not** auto-close.
Left alone, every slice issue would stay open until the Epic lands and
then dozens would close at once.

So when a slice MR merges into the Epic branch, close the slice issue
explicitly with a note saying which branch it landed on. The Epic's
progress rollup then moves continuously instead of jumping at the end.

The oddity to accept: a slice reads "closed" while its code is only on
the Epic branch. The alternative is a progress figure that is wrong
until it is suddenly right.

------------------------------------------------------------------------

## 7. Initial Repository Setup

Assume the remote repository is:

``` text
git@github.com:username/myproject.git
```

Create the project directory and its shared local-files folder:

``` bash
mkdir myproject
cd myproject
mkdir -p .shared/secrets .shared/config
```

Create `.shared/` once, at the project root beside `.bare/`. It is a
local folder outside all worktrees, so Git does not include it in any
branch. Put the private files that worktrees should follow by default
there.

Populate it from an existing checkout or your project's approved local
configuration source. For example, if the old checkout is beside
`myproject/`:

``` bash
cp ../myproject-old/.env .shared/.env
cp -R ../myproject-old/secrets/. .shared/secrets/
cp -R ../myproject-old/config/. .shared/config/
```

Run only the copy commands for paths your project actually has. For a
new project, create `.shared/.env` from its provided example file and
enter the local values; populate `secrets/` and `config/` in the same
way if needed. Do not put real credentials in a tracked example file.
Populate each item before linking it into worktrees. Later edits to a
shared item appear in every worktree that still follows its link.

Clone the remote as a bare repository:

``` bash
git clone --bare git@github.com:username/myproject.git .bare
```

Configure normal remote-tracking branch fetching:

``` bash
git --git-dir=.bare config remote.origin.fetch \
    "+refs/heads/*:refs/remotes/origin/*"

git --git-dir=.bare fetch origin
```

The initial structure, before creating any worktrees, is:

``` text
myproject/
├── .bare/
└── .shared/
    ├── .env                     # add your local values
    ├── secrets/
    └── config/
```

Keep `.shared/` outside every worktree and out of version control. Give
it access permissions appropriate for the secrets it contains; do not
commit or push those files.

------------------------------------------------------------------------

## 8. Create the Main Worktree

If the primary branch is `main`:

``` bash
git --git-dir=.bare worktree add main main
```

Result:

``` text
myproject/
├── .bare/
├── .shared/
└── main/
```

The `main/` worktree should remain clean and protected from normal
feature development.

Repository branch protection should also reject direct pushes to `main`
where possible.

------------------------------------------------------------------------

## 9. Create an Epic Branch and Worktree

For:

``` text
Epic: AUTH-100
Authentication Improvements
```

create an Epic branch from `main`:

``` bash
git --git-dir=.bare worktree add \
    -b epic/AUTH-100-authentication \
    epic-auth \
    main
```

Result:

``` text
myproject/
├── .bare/
├── main/
└── epic-auth/
```

The Epic worktree is the integration workspace for all slices belonging
to the Epic.

------------------------------------------------------------------------

## 10. Create Slice Worktrees for Multiple Agents

Create Agent A's slice:

``` bash
git --git-dir=.bare worktree add \
    -b slice/AUTH-101-oauth \
    slice-auth-oauth \
    epic/AUTH-100-authentication
```

Create Agent B's slice:

``` bash
git --git-dir=.bare worktree add \
    -b slice/AUTH-102-permissions \
    slice-auth-permissions \
    epic/AUTH-100-authentication
```

Create Agent C's slice:

``` bash
git --git-dir=.bare worktree add \
    -b slice/AUTH-103-audit \
    slice-auth-audit \
    epic/AUTH-100-authentication
```

Result:

``` text
myproject/
├── .bare/
├── main/
├── epic-auth/
├── slice-auth-oauth/
├── slice-auth-permissions/
└── slice-auth-audit/
```

Each agent now has an independent working directory.

------------------------------------------------------------------------

## 11. Git Constraint: Why Slice Branches Are Necessary

The conceptual model is:

> **One Epic → one branch → multiple worktrees → multiple agents**

However, Git normally prevents one branch from being checked out in
several worktrees simultaneously.

Therefore, do not attempt:

``` text
agent-a/ → epic/AUTH-100
agent-b/ → epic/AUTH-100
agent-c/ → epic/AUTH-100
```

Instead, derive slice branches from the Epic:

``` text
epic/AUTH-100
    │
    ├── slice/AUTH-101 → agent-a/
    ├── slice/AUTH-102 → agent-b/
    └── slice/AUTH-103 → agent-c/
```

This also gives each agent an explicit unit of ownership and a clean
commit history.

------------------------------------------------------------------------

## 12. Agent Slice Workflow

An agent works only inside its assigned slice worktree.

For example:

``` bash
cd slice-auth-oauth

git status

# Agent edits, builds and tests.

git diff
git add .
git commit -m "AUTH-101 Add Microsoft OAuth"
git push -u origin slice/AUTH-101-oauth
```

An agent starts only work that has passed Gate 1 (`ready-for-agent`).
Agents never merge; they push the slice branch and open the MR.

### The chain an agent runs

Every slice that produces code runs the same chain inside
`in-progress`, before any MR exists:

``` text
optional lead-in ──► implement ──► code-review ──► push, open MR
                          ▲              │
                          └──────────────┘
                          fixes what it can fix
```

-   **Lead-in (optional):** what must happen before writing code, such as
    diagnosing a bug or settling an interface. Set it only when the slice
    needs something other than its default: a bug defaults to *diagnose*
    first, a refactor to *design the seam* first, and a feature, test,
    docs change or chore goes straight to *implement*. A label that can
    be derived most of the time and is applied every time is bookkeeping
    that gets abandoned within a week; applied as an override it stays
    meaningful.
-   **Implement:** writes the test first, then the code.
-   **Code review:** always runs last, on every change, against the
    project's written standards.

### What review does with what it finds

The filter is whether a person's input changes the outcome.

| Finding                                     | Where it goes                                     |
|---------------------------------------------|---------------------------------------------------|
| Critical, unprefixed, most nits             | Fixed by the agent before the MR opens            |
| Needs a decision rather than a fix          | The MR's **review record**, phrased as the open question |
| Optional / worth keeping                    | A new issue, referenced from the review record    |
| FYI                                         | The review record, one line                       |

Nobody should be asked to review a problem the reviewer already knew how
to solve. A review record listing everything the agent considered is as
useless as one that says "LGTM".

------------------------------------------------------------------------

## 13. Integrating Slices into the Epic

Every slice reaches the Epic branch through a **merge request into the
Epic branch** (Gate 2), merged by a person or, where the project's
config says `auto`, by the orchestrator (section 25). The MR itself is
not optional: it is where the review record is read and where CI runs.

After AUTH-101's MR is approved and merged:

``` bash
# Refresh the Epic worktree; the merge itself happened on the host.
cd epic-auth
git pull
```

Then close the slice issue with a note saying it landed on
`epic/AUTH-100-authentication` (see *Slice completion* in the Gates
section), and repeat for the remaining slices.

A person working alone, with no agent involved, may merge locally
instead:

``` bash
cd epic-auth
git merge slice/AUTH-101-oauth
```

Agents never do this.

The Epic branch becomes the combined implementation:

``` text
main
  │
  └── epic/AUTH-100
          │
          ├── AUTH-101 ✓
          ├── AUTH-102 ✓
          └── AUTH-103 ✓
```

------------------------------------------------------------------------

## 14. Main Branch Protection and Integration Rule

The `main` branch is the stable integration boundary.

The core rule is:

> **`main` can only be edited through the merge of a completed Epic
> branch** (or, for work that belongs to no Epic, a reviewed standalone
> fix; see *Standalone Fixes*).

Normal feature development must not occur directly in `main`.

The complete flow is:

``` text
Slice A ──► Slice Branch ──┐
                           │
Slice B ──► Slice Branch ──┼──► Epic Branch ──► main
                           │
Slice C ──► Slice Branch ──┘
```

The three levels have distinct responsibilities:

``` text
MAIN
│
│  Stable / protected
│  Epic merges only
│
└── EPIC BRANCH
      │
      │  Integration boundary
      │
      ├── SLICE BRANCH → WORKTREE → AGENT A
      ├── SLICE BRANCH → WORKTREE → AGENT B
      └── SLICE BRANCH → WORKTREE → AGENT C
```

### Rules

1.  Agents never implement features directly on `main`.
2.  Developers do not use `main` as a feature-development workspace.
3.  Every body of feature work belongs to an Epic. Work that belongs to
    no Epic follows *Standalone Fixes*.
4.  Every Epic receives an Epic branch derived from `main`.
5.  Slices receive slice branches derived from the Epic branch.
6.  Each concurrently active slice receives its own worktree.
7.  Each worktree is owned by one slice/agent at a time.
8.  Completed slice branches merge into the Epic branch, not `main`,
    through a merge request that a person merges, or that the
    orchestrator merges on a path a person set to `auto`.
9.  Integration testing is performed against the combined Epic branch.
10. Only a completed, reviewed, and validated Epic branch may merge into
    `main`.
11. Repository protection should reject direct pushes to `main`.
12. Agents never promote an issue to `ready-for-agent`. An agent merges
    only as the orchestrator, on a path a person set to `auto`.
13. The spec lives on the Epic branch and is updated in the same change
    as the code it describes.

This creates a controlled promotion path:

> **Agent → Slice Branch → Epic Branch → Main**

------------------------------------------------------------------------

## 15. Completing an Epic

After all required slices have been integrated:

``` text
slice/AUTH-101 ─┐
slice/AUTH-102 ─┼──► epic/AUTH-100 ──► main
slice/AUTH-103 ─┘
```

Before the Epic is merged into `main`, run the appropriate Epic-level:

-   integration tests;
-   regression tests;
-   code review;
-   security checks;
-   database migration validation;
-   CI pipeline;
-   acceptance checks.

The Epic branch then goes to `main` as **one merge request**, reviewed
**at the spec level** against `requirements.md` rather than line by line
(each slice was already reviewed in its own MR), with a drift check
against `decisions.md` to confirm nothing refused there was built
anyway. The Epic closes on merge.

The technical checks above are what make a spec-level review safe: the
reviewer is trusting that the combined branch works, so the combined
branch must be tested as a whole.

This gives two levels of validation:

``` text
Slice-level testing
        ↓
Slice integration
        ↓
Epic branch
        ↓
Epic-level integration testing
        ↓
Review / CI
        ↓
main
```

------------------------------------------------------------------------

## 16. Standalone Fixes (Work With No Epic)

Not everything belongs to a feature. A lone fix or chore with no Epic
parent branches from `main`, is worked in its own worktree, and merges
into `main` on its own:

``` bash
git --git-dir=.bare worktree add \
    -b fix/AUTH-140-login-redirect \
    fix-login-redirect \
    main
```

It runs the same chain (lead-in, implement, code-review), opens an MR
into `main`, and is merged under Gate 2: by a person, or by config
(`fix-to-main`, section 25). Nothing about it
bypasses review; it only skips the Epic level.

Deciding where a bug goes:

-   The bug is in the feature's own code: an issue, child of that Epic,
    fixed as a slice on the Epic branch.
-   The bug is in something the feature merely touches: a standalone
    issue with no Epic parent, fixed from `main`.

The "no path from a slice branch to `main`" rule in this guide is about
feature work. A standalone fix is not a slice.

------------------------------------------------------------------------

## 17. Epic Lifetime and Staying Current

### Keep an Epic short

Keep the Epic branch under roughly **two weeks** from the day it is cut
from `main` to the day it merges. Drift from `main` scales with how long
the branch lives, not with how much is on it. If an Epic cannot merge
inside two weeks, it is two Epics: split it at an outcome boundary.

### Stay current

-   Merge `main` into the Epic branch whenever `main` moves, and always
    before opening the Epic MR. Merge rather than rebase: the Epic
    branch is shared, and rewriting its history breaks every slice
    derived from it.
-   Bring each slice up to date from the Epic branch before opening its
    MR, so the MR shows only the slice's own change.

### Record the Epic on each branch

Tooling that runs inside a worktree (intake, dispatch, sync scripts)
needs to know which Epic the worktree belongs to, so that new issues are
parented to it at creation instead of arriving unparented in the inbox.
Most feedback that arrives while a feature is being built is about that
feature, so parenting it at creation is far cheaper than triaging it
later.

Store the Epic key against the **branch**, in the shared config:

``` bash
# Once per new slice or Epic branch, from myproject/.
git --git-dir=.bare config branch.slice/AUTH-101-oauth.epicid AUTH-100
git --git-dir=.bare config branch.epic/AUTH-100-authentication.epicid AUTH-100

# Read it from inside any worktree.
git config --get "branch.$(git branch --show-current).epicid"
```

Do **not** use `git config --local <key> <value>` for this. In a bare
repository with worktrees, `--local` writes to the shared
`.bare/config`, so every worktree reads the same value and concurrent
Epics overwrite each other. The per-worktree alternative
(`extensions.worktreeConfig` with `git config --worktree`) does not work
in this layout either: a linked worktree then inherits
`core.bare = true` from `.bare/config` and Git refuses to run work-tree
commands in it. A branch-scoped key avoids both problems, and
`git branch -d` removes it along with the branch.

------------------------------------------------------------------------

## 18. Multiple Epics Can Run Concurrently

The same model supports several independent Epics:

``` text
                       PROTECTED
                          MAIN
                           ▲
                           │
                     Epic merges
                           │
              ┌────────────┴────────────┐
              │                         │
          EPIC A                     EPIC B
              ▲                         ▲
        ┌─────┼─────┐             ┌─────┼─────┐
        │     │     │             │     │     │
       T1    T2    T3            T1    T2    T3
        ▲     ▲     ▲             ▲     ▲     ▲
        │     │     │             │     │     │
       A1    A2    A3            A4    A5    A6
```

Each Epic acts as an independent integration boundary while `main`
remains protected from partial implementations.

------------------------------------------------------------------------

## 19. Environment Isolation

Git worktrees isolate source files and Git indexes, but they do not
automatically isolate runtime resources.

Each active agent may need independent:

-   `.env` values when its branch opts out of the shared defaults;
-   Python virtual environment;
-   database or database schema;
-   development server port;
-   Docker Compose project;
-   Redis namespace or instance;
-   Celery queue;
-   temporary directories;
-   test artifacts.

For example:

``` text
epic-auth/                 → port 8000
slice-auth-oauth/          → port 8001
slice-auth-permissions/    → port 8002
slice-auth-audit/          → port 8003
```

For Django projects, database migrations require particular care when
several agents create migrations concurrently.

### Where "just rebuild it" stops being cheap

Before a feature's schema first reaches production, regenerate freely:
the code is disposable, and a per-branch review database absorbs the
churn. After it, every schema change is **expand, migrate, contract**,
with the production check recorded. This is also why schema changes to
anything already in production never go to an agent unattended (see
*Never promoted to `ready-for-agent`*). Know in advance which iteration
is the last cheap one.

For Docker Compose, assign a unique project name per worktree so
containers, networks, and volumes do not collide.

### Shared private files with a per-worktree opt out

The project root's `.shared/` folder is the default source for local
`.env`, `secrets/`, and `config/`. Link each item into a new worktree
after `git worktree add`.

**On Windows, use `yngshared.ps1`.** Copy [yngshared.ps1](../scripts/yngshared.ps1)
into the project root beside `.bare/` and `.shared/`, then run it from
there. It handles every file in `.shared/` and its subfolders (not just
the three above): each file gets its own relative symlink, and the
matching folders in the worktree are created as real folders. Empty
folders are ignored. It never overwrites real files without `-Force`,
backs up each file it replaces, and never replaces a folder (a real
folder where a file should go is left alone with a warning):

``` powershell
.\yngshared.ps1 -link main epic-auth -WhatIf   # preview
.\yngshared.ps1 -link main epic-auth           # symlink shared files
.\yngshared.ps1 -link -All                     # every worktree
.\yngshared.ps1 -copy slice-auth-oauth -Name .env   # opt out: own .env
.\yngshared.ps1 -copy slice-auth-oauth -Name config\app.ini   # nested file
.\yngshared.ps1 -unlink slice-auth-oauth       # links -> independent copies
```

`-Name` takes files only, as paths relative to `.shared/`; a folder name
is an error, so name each file in it. Symlinks on Windows need Developer
Mode or an elevated shell. Run
`Get-Help .\yngshared.ps1 -Full` for requirements, all switches, and the
exact behavior for each existing-file case.

**On macOS/Linux, use `yngshared.sh`.** Copy [yngshared.sh](../scripts/yngshared.sh)
into the project root, `chmod +x yngshared.sh`, and use the same actions
with double-dash options (`./yngshared.sh -h` for full help). It behaves
the same as the Windows script, including per-file links and
`--name config/app.ini`:

``` bash
./yngshared.sh --link main epic-auth --what-if   # preview
./yngshared.sh --link main epic-auth             # symlink shared items
./yngshared.sh --link --all                      # every worktree
./yngshared.sh --copy slice-auth-oauth --name .env   # opt out: own .env
./yngshared.sh --unlink slice-auth-oauth         # links -> independent copies
```

To see what the script does, or without it, the equivalent manual
loop from `myproject/` is:

``` bash
# Run for each new worktree; replace main with its directory name.
# Each file in .shared/ (including nested ones) gets its own relative
# link; folders are created as real folders, never linked as a whole.
wt=main
(cd .shared && find . -type f | sed 's|^\./||') | while IFS= read -r rel; do
    if [ -e "$wt/$rel" ] || [ -L "$wt/$rel" ]; then continue; fi
    mkdir -p "$wt/$(dirname "$rel")"
    depth=$(printf '%s' "$wt/$rel" | awk -F/ '{print NF-1}')
    up=$(printf '../%.0s' $(seq "$depth"))
    ln -s "${up}.shared/$rel" "$wt/$rel"
done
```

Repeat for `epic-auth` and each slice worktree, or put this loop in the
worktree creation script. Existing files are left alone. If a tracked
file already occupies one of these paths, keep it tracked and choose a
different local path for the shared data.

Do not link a whole folder such as `main/secrets -> ../.shared/secrets`.
Anything the scripts (or you) then write beneath it lands inside
`.shared/`. If a worktree still has such a folder link from an older
version, `yngshared` warns and skips every file beneath it, even with
`-Force`. Remove the folder link (`rm main/secrets` with no trailing
slash, or `cmd /c rmdir main\secrets` on Windows; never `rm -r` or
`Remove-Item -Recurse`), then run the script again.

By default, every linked worktree reads the same underlying files. A
change through one link is visible in all linked worktrees. To opt a
branch out for one item, use `yngshared.ps1 -copy <worktree> -Name <item>`
(Windows) or `./yngshared.sh --copy <worktree> --name <item>`
(macOS/Linux), or replace that worktree's link with a local copy manually:

``` bash
# From myproject/: give the OAuth slice its own .env.
test -L slice-auth-oauth/.env
cp -L slice-auth-oauth/.env slice-auth-oauth/.env.local-copy
unlink slice-auth-oauth/.env
mv slice-auth-oauth/.env.local-copy slice-auth-oauth/.env
```

The OAuth slice now has independent `.env` values; the file links in its
`secrets/` and `config/` folders still follow `.shared/`. The same
approach works for a nested file, one file at a time. To opt out when
creating a worktree, simply omit the selected link and create a local
file at that path.
Only unlink a path after confirming it is a symbolic link; deleting or
editing the shared target affects every branch that follows it.

Ensure the relevant paths are ignored in every branch's `.gitignore`
or a local Git excludes file. Directory patterns with a trailing slash
do not ignore symbolic links, so use patterns that match both the link
and an independent directory:

``` gitignore
/.env
/secrets
/config
```

Add only entries that are genuinely private and untracked in the
project. For example, do not ignore a tracked application `config/`
directory; share a specific local file within it instead. Verify with
`git status --short` that neither the links nor local copies appear as
untracked files before committing. Each worktree keeps its own
dependencies, build outputs, and runtime resources.

------------------------------------------------------------------------

## 20. Agent Safety Rules

A coding agent operating under this architecture should:

1.  Work only inside its assigned slice worktree.
2.  Stay on its assigned slice branch unless explicitly instructed
    otherwise.
3.  Treat the Epic branch as an integration branch.
4.  Never modify another agent's worktree.
5.  Never manually modify `.bare/`.
6.  Never implement feature work directly on `main`.
7.  Never merge a slice branch directly into `main`.
8.  Check `git status` before starting work.
9.  Inspect `git diff` before committing.
10. Run relevant tests before marking a slice complete.
11. Keep commits scoped to the assigned slice.
12. Push the slice branch and open a merge request into the Epic
    branch for review/integration.
13. Coordinate changes affecting shared architecture, dependencies,
    schemas, or common configuration.
14. Treat databases, ports, containers, queues, and caches as separate
    isolation concerns.
15. Follow the project's existing specifications, agent instructions,
    review requirements, and commit conventions.
16. Start only work a person has promoted to `ready-for-agent`, and stop
    and hand back anything that turns out to need a human (see *Never
    promoted to `ready-for-agent`*). Unsure means human.
17. Never merge a merge request, and never change an issue's workflow
    state. The dispatcher (or the person running you) does that.
18. Run code review on your own change and fix what is fixable before
    opening the merge request; put only open decisions in the review
    record.
19. Update the spec on the Epic branch in the same change as the code it
    describes, and never write spec content into an issue.
20. Change `.bare/` only through Git commands (`worktree add`,
    `branch`, `config`), never by editing its files.

------------------------------------------------------------------------

## 21. Integration Conflicts Still Exist

Worktrees eliminate filesystem collisions, but they do not eliminate
normal integration conflicts.

For example, Agent A and Agent B may independently modify:

``` text
settings.py
```

Their workspaces remain isolated while they develop.

However, merging both slice branches into the Epic may produce a Git
conflict.

Worktrees solve:

``` text
workspace collision
```

They do not automatically solve:

``` text
merge conflicts
slice dependency conflicts
architectural conflicts
database migration conflicts
integration failures
semantic conflicts
```

Good Epic decomposition, slice boundaries, interfaces, and communication
remain important.

------------------------------------------------------------------------

## 22. Cleanup

After a slice is merged into the Epic:

``` bash
git --git-dir=.bare worktree remove slice-auth-oauth
```

Delete its local slice branch when appropriate:

``` bash
git --git-dir=.bare branch -d slice/AUTH-101-oauth
```

After the completed Epic is merged into `main`:

``` bash
git --git-dir=.bare worktree remove epic-auth
```

Then remove the local Epic branch:

``` bash
git --git-dir=.bare branch -d epic/AUTH-100-authentication
```

If a worktree directory was manually deleted, prune stale metadata:

``` bash
git --git-dir=.bare worktree prune
```

------------------------------------------------------------------------

## 23. Listing Active Worktrees

Use:

``` bash
git --git-dir=.bare worktree list
```

Example:

``` text
/path/myproject/.bare                    (bare)
/path/myproject/main                     abc1234 [main]
/path/myproject/epic-auth                def5678 [epic/AUTH-100-authentication]
/path/myproject/slice-auth-oauth         123abcd [slice/AUTH-101-oauth]
/path/myproject/slice-auth-permissions   456efgh [slice/AUTH-102-permissions]
```

This is useful for both developers and agent orchestrators because it
provides a view of active local workspaces and branch ownership.

------------------------------------------------------------------------

## 24. Quick Reference

### Create repository

``` bash
git clone --bare <repository-url> .bare

git --git-dir=.bare config remote.origin.fetch \
    "+refs/heads/*:refs/remotes/origin/*"

git --git-dir=.bare fetch origin
```

### Create main worktree

``` bash
git --git-dir=.bare worktree add main main
```

### Create Epic

``` bash
git --git-dir=.bare worktree add \
    -b epic/AUTH-100-authentication \
    epic-auth \
    main
```

### Create agent slice

``` bash
git --git-dir=.bare worktree add \
    -b slice/AUTH-101-oauth \
    slice-auth-oauth \
    epic/AUTH-100-authentication

# Record the Epic on the branch (never `git config --local`).
git --git-dir=.bare config branch.slice/AUTH-101-oauth.epicid AUTH-100
```

### Create standalone fix (no Epic)

``` bash
git --git-dir=.bare worktree add \
    -b fix/AUTH-140-login-redirect \
    fix-login-redirect \
    main
```

### List active worktrees

``` bash
git --git-dir=.bare worktree list
```

### Commit agent work

``` bash
cd slice-auth-oauth

git status
git diff
git add .
git commit -m "AUTH-101 Add Microsoft OAuth"
git push -u origin slice/AUTH-101-oauth
```

### Integrate slice into Epic

Default: open a merge request from the slice branch into the Epic
branch, have a person merge it, then close the slice issue with a note
naming the Epic branch. Refresh the Epic worktree afterwards:

``` bash
cd ../epic-auth
git pull
```

A person working alone, with no agent involved, may merge locally:

``` bash
cd ../epic-auth
git merge slice/AUTH-101-oauth
```

### Remove completed slice

``` bash
git --git-dir=.bare worktree remove slice-auth-oauth
git --git-dir=.bare branch -d slice/AUTH-101-oauth
```

### Remove completed Epic after merge to main

``` bash
git --git-dir=.bare worktree remove epic-auth
git --git-dir=.bare branch -d epic/AUTH-100-authentication
```

### Prune stale metadata

``` bash
git --git-dir=.bare worktree prune
```

------------------------------------------------------------------------

## 25. Running the Dispatcher as the YNG Orchestrator

The dispatcher in section 6 can itself be an agent. The playbook ships
it as the **YNG Orchestrator** skill (`/yngorchestrator`), with the
**slice worker** agent it hands slices to:

``` text
skills/yngorchestrator/SKILL.md     the orchestrator: role, run log, steps
skills/yngorchestrator/plan.md      cut the Epic into slices; create issues
skills/yngorchestrator/dispatch.md  Gate 1 check, worktree, launch a worker
skills/yngorchestrator/track.md     act on reports; close merged slices
skills/yngorchestrator/merge.md     apply the project's merge rule to a PR
skills/yngorchestrator/report.md    the completion report every worker ends with
agents/slice-worker.md              the worker: one slice, worktree to PR
templates/orchestrator-config.yml   the project's config, starting at all-required
```

The orchestrator runs in the main agent session, from the Epic
worktree. Workers run as subagents, one per slice, each in the slice
worktree the orchestrator created for it (section 10). A worker's last
message is its **completion report**, so it reaches the orchestrator
with no extra channel:

``` text
             Orchestrator (main session, the dispatcher)
       plan ─► check Gate 1 ─► dispatch ─► track ─► hand back
                                  │           ▲
                 ┌────────────────┼───────────┼───────┐
                 ▼                ▼           │       ▼
              Worker A         Worker B    reports  Worker C
           slice worktree   slice worktree        slice worktree
```

It keeps to both gates:

-   **Gate 1.** It creates slice issues at `workflow:needs-triage` and
    dispatches only issues a person labelled `workflow:ready-for-agent`,
    checking the issue timeline for who applied the label.
-   **Gate 2.** Workers open pull requests; the orchestrator labels them
    `workflow:in-review` and applies the merge rule for the path (see
    *Merge rules* below). On `required` it tells the person; after a
    merge, by either, it closes the slice issue and removes the
    worktree.

It is **standalone**: nothing of it is committed to the project. Its
files sit in the project root, beside `.bare/` and outside every
worktree:

``` text
myproject/
├── .bare/
├── .shared/
│   └── .claude/                 # linked into worktrees by yngshared
│       ├── skills/yngorchestrator/
│       └── agents/slice-worker.md
├── .yngorchestrator/
│   ├── config.yml               # merge rules
│   └── runs/
│       └── 100.md               # run log for Epic #100
├── main/
└── epic-auth/
```

The run log lets an interrupted run resume where it stopped, and
outlives the Epic worktree.

### Merge rules

`.yngorchestrator/config.yml` in the project root records the person's
Gate 2 decision per merge path:

``` yaml
merge:
  slice-to-epic: required   # required | auto
  epic-to-main: required
  fix-to-main: required
```

-   `required`: a person merges. This is the default for a missing file,
    a missing key, or any value other than `auto`.
-   `auto`: the orchestrator merges, with a merge commit, when the
    worker reported `done` (for an Epic, every slice is closed), the
    pull request is mergeable, every check passed, and the review record
    holds no open decision. When any of these fails, it comments which
    one on the pull request and leaves it to the person.

The file belongs to no branch, so no branch or merge request can grant
itself `auto`; the orchestrator reads it fresh at every merge, so an
edit applies at once. A common start is `slice-to-epic: auto` with the other two
`required`. This is what lets the orchestrator carry the Epic on its
own: each slice it merges closes, which unblocks the slices that depend
on it, so it keeps dispatching instead of stopping at every slice to
wait for a person. Every change to `main` still passes a person.

`fix-to-main` is read whenever the orchestrator holds a standalone-fix
pull request; it does not yet dispatch standalone fixes itself.

### Install

[INSTALL.md](../INSTALL.md) has the whole path, by hand or by asking
your agent: prerequisites, setting up the layout, and the first Epic.
The install itself is one command, from anywhere inside the project (its root or any
worktree), using your clone of YNGAIPlaybook:

``` powershell
C:\path\to\YNGAIPlaybook\scripts\yngorch.ps1     # Windows
```

``` bash
/path/to/YNGAIPlaybook/scripts/yngorch.sh        # macOS/Linux
```

It finds the project root, copies the skill and worker into
`.shared/.claude/`, writes `.yngorchestrator/config.yml` with every path
`required` (only if you have none), hides the links with
`.bare/info/exclude` (Git's local ignore file, never pushed), links
every worktree through `yngshared`, creates the workflow labels
with `gh` when it is installed, and puts `yngv`, the file viewer, in
your `~/.local/bin` (on Windows it also adds that folder to your user
PATH; on macOS/Linux it prints the line to add when it is missing).
Then set your merge rules in `.yngorchestrator/config.yml`.

Run the same command again to upgrade, or after creating a worktree to
link it; it never overwrites your config. The orchestrator links the
slice worktrees it creates itself. `-Project <path>` / `--project
<path>` installs into a project other than the current folder, and
`-SkipLabels` / `--skip-labels` leaves the labels alone, and
`-SkipViewer` / `--skip-viewer` leaves `yngv` out.

These are Claude Code's folders. Another agent that supports skills and
subagents takes the same files in its own folders. The commands inside
are written for GitHub (`gh`); on another tracker, use its equivalents.

### Run

From the Epic worktree, start the agent and run `/yngorchestrator <epic
issue>`. With no slice issues yet, it plans first and waits for you to
approve the plan; afterwards, promote the slices you want an agent to
take, and run it again. It ends each run with one list of everything
waiting on you: pull requests to merge, slices handed back, slices
waiting for promotion.

------------------------------------------------------------------------

## Summary

The **Bare Repository + Git Worktrees Pattern** provides a structured
foundation for parallel agentic software development organized around
Epics.

The conceptual principle is:

> **One Epic → one branch → multiple worktrees → multiple agents**

The practical Git implementation is:

> **One Epic → one Epic branch → multiple slice branches → multiple
> worktrees → multiple agents**

And the controlled integration path is:

> **Agent → Slice Branch → Epic Branch → Main**

`main` is protected and does not serve as a feature-development
workspace. Feature changes reach `main` only through a completed,
reviewed, tested, and validated Epic branch (work with no Epic follows
the standalone-fix path).

Two people-only gates govern the flow: a person promotes an issue before
an agent may start it, and a person decides every merge, by hand or by
config. The Epic is a feature of roughly two weeks or less, its slices
are named for outcomes, and its spec is versioned on the Epic branch
beside the code.

``` text
                         MAIN
                    Stable / Protected
                           ▲
                           │
                     Epic merge only
                           │
                    EPIC BRANCH
                 Integration Boundary
                           ▲
              ┌────────────┼────────────┐
              │            │            │
         Slice Branch Slice Branch Slice Branch
              ▲            ▲            ▲
              │            │            │
           Worktree      Worktree      Worktree
              ▲            ▲            ▲
              │            │            │
           Agent A       Agent B       Agent C
```

This architecture enables multiple agents to work concurrently while
maintaining filesystem isolation, explicit slice ownership, controlled
Epic-level integration, and a clean promotion path into the protected
`main` branch.
