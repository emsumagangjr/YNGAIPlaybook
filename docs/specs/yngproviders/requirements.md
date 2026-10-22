# YNG Providers: Requirements

Epic: #98 · Branch: `epic/98-yngproviders`

## Purpose

The orchestrator and its installer speak only GitHub today: `gh auth
status` is a prerequisite, and every issue, label, pull request and
merge is a `gh` call. This feature makes the git provider a setting.
The installer detects it in an existing project, asks for it only when
it cannot be worked out, and records it. The orchestrator then works
through the provider's own CLI the person already has.

Three providers are supported first: GitHub, GitLab and Bitbucket.
**More will follow.** The provider is one seam, one file per provider,
so adding the next means adding one file and passing one smoke run
(R7, R15).

``` text
            yngorch (install)                 /yngorchestrator (run)
   detect or ask ─► config: provider, host ─► load providers/<provider>.md
                                                     │ named operations
                          ┌──────────────────────────┼──────────────────────┐
                          ▼                          ▼                      ▼
                    github.md (gh)            gitlab.md (glab)     bitbucket.md (curl REST)
```

The orchestrator's own requirements live in
[yngorchestrator](../yngorchestrator/requirements.md). Where this spec
changes one of them, it names it (for example *amends yngorchestrator
R4*).

## Deliverables

``` text
skills/yngorchestrator/providers/README.md     the operations, Adding a provider, the smoke run (R7, R15, R16)
skills/yngorchestrator/providers/github.md     GitHub operations (gh)
skills/yngorchestrator/providers/gitlab.md     GitLab operations (glab)
skills/yngorchestrator/providers/bitbucket.md  Bitbucket Cloud operations (REST with curl)
scripts/yngorch.ps1, scripts/yngorch.sh        detection, -Provider, repo creation, per-provider checks and states
skills/yngorchestrator/*.md, agents/slice-worker.md  provider-neutral: operations by name, no inline gh
templates/yngorchestratorconfig.yml            provider: and host: keys
templates/yngaiplaybookreadme.md               lines for provider: and host:
INSTALL.md, README.md, guides/epic-workflow.md Supported providers, per-provider setup
```

------------------------------------------------------------------------

## R1 Supported providers

1.  Supported:

    | Provider  | Hosting                                  | CLI and auth                                     |
    |-----------|------------------------------------------|--------------------------------------------------|
    | GitHub    | github.com, GitHub Enterprise Server     | `gh`, logged in (`gh auth status --hostname`)    |
    | GitLab    | gitlab.com, GitLab self-managed          | `glab`, logged in (`glab auth status --hostname`) |
    | Bitbucket | bitbucket.org (Cloud only)               | REST with `curl` and `jq`, `BITBUCKET_EMAIL` and `BITBUCKET_API_TOKEN` (R6) |

2.  Planned, named as such wherever the supported list appears (R16):
    Azure DevOps, Bitbucket Data Center, Jira as an issue tracker,
    Gitea/Forgejo, and an issues repo on a different provider from the
    code (R11).

## R2 Provider and host in the config

1.  The config (yngorchestrator R23) gains two top-level keys:

    ``` yaml
    provider: github    # github | gitlab | bitbucket; absent: github (R14)
    host: github.com    # the provider's host; absent: the provider's cloud host
    ```

2.  The orchestrator reads both fresh at the start of every run, as it
    reads `issues:`. The supported providers are those that have a
    file in `skills/yngorchestrator/providers/` (R7), other than its
    README; a provider is supported by the run once its file is there.
    A `provider:` with no file there stops the run before the lock,
    naming the value and the providers that have a file in
    `providers/`. A `host:` with a scheme or a path stops the run the
    same way.
3.  The installer writes each key only when it has no value yet; it
    never overwrites one. The config template documents both, and the
    folder's README (yngorchestrator R26) gives each a line: purpose,
    owner (the person), and that `yngorch` writes it only when absent.

## R3 Detection in an existing project

1.  With no value in the config, the installer reads the host from
    `git remote get-url origin` (HTTPS or SSH form) and decides in
    order:
    1.  A known cloud host: `github.com` is github, `gitlab.com` is
        gitlab, `bitbucket.org` is bitbucket.
    2.  Any other host: `gh auth status --hostname <host>` and
        `glab auth status --hostname <host>`. Exactly one succeeding
        names the provider.
    3.  Otherwise, neither or both: the installer stops and asks for
        `-Provider` / `--provider`, naming the host and what each
        check returned. The agent doing the install asks the person.
2.  `-Provider github|gitlab|bitbucket` / `--provider` skips
    detection. With a value already in the config, a flag that differs
    is a `warning` naming both; the config wins and is not changed.
3.  The installer prints one line for the outcome: `wrote provider:
    gitlab (detected from origin)`, `wrote provider: gitlab (from
    --provider)`, or `kept provider: gitlab (yours)`.
4.  A Bitbucket host other than `bitbucket.org` is Bitbucket Data
    Center: the installer stops, saying it is planned, not supported.

## R4 Provider for a new project

Amends INSTALL.md, *For the agent doing the install*, step 2.

1.  When the person names a repository URL, the provider and host come
    from it by R3.1. No question is asked.
2.  When the person names only a repository name, or nothing, the agent
    asks, in this order and one at a time: the provider (GitHub, GitLab
    or Bitbucket); the host, only when it is self-hosted; then the
    owner, group or workspace.
3.  It then proposes the folders and commands as today and waits for
    the person's yes.

## R5 Repository creation

1.  After the person's yes, the new project's repository is created
    with a first commit, so `main` exists, before the bare clone:

    | Provider  | Create |
    |-----------|--------|
    | GitHub    | `gh repo create <owner>/<repo> --private --add-readme` |
    | GitLab    | `glab repo create <group>/<project> --private --readme` |
    | Bitbucket | `POST /2.0/repositories/<workspace>/<repo>` with `is_private: true` and `has_issues: true`, then a README committed to `main` through `POST .../src`, so no git credential is needed |

2.  The bare clone and worktree commands are the same for every
    provider, with the provider's clone URL.
3.  A repository that already exists is not created again: the agent
    reports it and clones it.

## R6 Machine checks per provider

Amends INSTALL.md, *Before you start* and step 1.

1.  The install checks only the configured provider's tool:
    `gh auth status --hostname <host>`, `glab auth status --hostname
    <host>`, or, for Bitbucket, `curl` present and `GET
    https://api.bitbucket.org/2.0/user` succeeding with
    `BITBUCKET_EMAIL` and `BITBUCKET_API_TOKEN`.
2.  Bitbucket credentials are read from those two environment variables
    only. Neither the installer, the orchestrator nor a worker writes
    them to the config, the project, a run log, a comment or a report,
    or echoes them.
3.  INSTALL.md lists the Bitbucket API token scopes the orchestrator
    needs (repository, pull request and issue, read and write) and how
    to set the variables in PowerShell and bash.

## R7 Provider files

1.  `skills/yngorchestrator/providers/<provider>.md` holds every
    provider call. Each file implements the same named operations,
    listed once in `providers/README.md`:

    | Operation          | What it does |
    |--------------------|--------------|
    | read issue         | title, body, state, labels or state, by full reference |
    | set state          | move the issue to one workflow state, removing the old (R8) |
    | mark epic          | mark or test an issue as an Epic (R8) |
    | list children      | the slices of an Epic (R9) |
    | read parent        | the Epic of a slice (R9) |
    | link child         | attach a slice to its Epic (R9) |
    | provenance         | who set `ready-for-agent`, and whether that is a human (R10) |
    | comment            | post a comment on an issue or a pull request |
    | close / reopen     | close or reopen an issue |
    | create issue       | create an issue at a state |
    | edit body          | replace an issue's body (the `Branch:` line, yngorchestrator R44.1) |
    | create pr          | open a pull request from a branch into a base |
    | pr status          | state, head, base, mergeable, and checks of a pull request |
    | list prs           | pull requests by head branch, any state |
    | merge pr           | merge with a merge commit and delete the head branch |
    | create repo        | R5 |
    | setup states       | create the workflow labels or their equivalent (R8) |

    `providers/README.md` gives each operation its inputs and outputs,
    which are the same on every provider, and the *Facts* every file
    states: its CLI, cloud host, path form (R11.2), issue URL, issue
    reference and closing reference (R12.1).

2.  The orchestrator loads `SKILL.md`, the step files it needs,
    `providers/README.md`, and the one provider file for the configured
    `provider:`, never another.
3.  The step files and `agents/slice-worker.md` name operations ("*set
    state* `workflow:in-progress`"), not commands. No `gh`, `glab` or
    `curl` call remains in them.
4.  The dispatch prompt carries the provider and host, so the worker
    loads the same provider file for *read issue*, *create pr* and
    *list prs*: a `PROVIDER:` field holding the provider, the host and
    the provider file's absolute path. A prompt without the field is
    read as `github` on `github.com`.

## R8 Workflow states and labels

1.  The state names are the same on every provider:
    `workflow:needs-triage`, `workflow:ready-for-agent`,
    `workflow:ready-for-human`, `workflow:in-progress`,
    `workflow:in-review`, and `epic`.
2.  GitHub and GitLab: plain labels with exactly these names, single
    colon, no GitLab scoped labels. *Set state* adds the new label and
    removes the previous `workflow:` label in one call.
3.  Bitbucket: the issue's `component` holds the state, named without
    the `workflow:` prefix (`needs-triage`, `ready-for-agent`, ...).
    An Epic is an issue in the `epic` milestone. *Set state*, *mark
    epic*, *close* and *reopen* post to the issue's `/changes`, so each
    leaves a change record (R10); *create issue* creates the issue
    without a component, then sets its state that way.
4.  *Setup states* creates the labels (GitHub, GitLab) or the
    components and the `epic` milestone (Bitbucket). Where the provider
    cannot create one through its API, the installer prints a `warning`
    naming each to create by hand and where.

## R9 Parent and child

1.  GitHub: native sub-issues, as today.
2.  GitLab and Bitbucket: a slice is an ordinary issue whose body holds
    one line `Parent: #<n>` naming its Epic in the issues repo. On
    GitLab, *link child* also adds a `relates_to` issue link, so the
    Epic's page lists its slices.
3.  *List children* on GitLab and Bitbucket finds the issues whose body
    holds that line for the Epic. *Read parent* reads it from the
    slice's body.

## R10 Gate 1 provenance

Amends yngorchestrator R4.1.

1.  Dispatch requires that the latest change that set
    `ready-for-agent` was made by a human account:
    - GitHub: as today, a timeline `labeled` event whose actor has
      type `User`, no `[bot]` login, and no `performed_via_github_app`.
    - GitLab: the latest `add` event for `workflow:ready-for-agent` in
      `GET /projects/:id/issues/:iid/resource_label_events`, whose
      user has `bot: false` in `GET /users/:id`. Project and group
      access tokens and service accounts are bot users and fail.
    - Bitbucket: the latest change in `GET .../issues/<id>/changes`
      that sets `component` to `ready-for-agent`, whose author has
      `type: user`. Workspace, project and repository access tokens
      act as `app_user` and fail. An issue created with the
      component already at `ready-for-agent` has no such change, and
      fails.
2.  A change made with the person's own token passes on every
    provider, so the orchestrator never sets `ready-for-agent` itself.
    Each provider file says so beside its check.
3.  The record of a plan promotion (yngorchestrator R36) is a comment
    on every provider.

## R11 Issues repo on the same provider

Amends yngorchestrator R28.3.

1.  `issues:` names a project on the same provider and host as the
    code repo. Cross-provider issues are planned (R1.2).
2.  The value's form is the provider's path: `<owner>/<repo>` on
    GitHub and Bitbucket (`<workspace>/<repo>`), `<group>[/<subgroup>...]/<project>`
    on GitLab. Any other form stops the run before the lock, naming
    it.

## R12 Linking and closing

Amends yngorchestrator R30.

1.  A fix pull request and the Epic's pull request into `main` name
    their issue with the provider's closing reference: `Closes
    <owner>/<repo>#<n>` (GitHub), `Closes <group>/<project>#<n>`
    (GitLab), `Closes #<n>` (Bitbucket, same repository only).
2.  When the provider does not close the issue on merge (Bitbucket
    with a separate issues repo, or any case its keywords do not
    cover), the orchestrator closes it with *close* after the merge
    and logs it.

## R13 Merge

Amends yngorchestrator R7.

1.  `auto` merges check *pr status* first, on every provider: open,
    the expected head and base, mergeable, and every check or pipeline
    passed. Any other result holds the merge with a comment, as today.
    On Bitbucket, the checks are the pull request's commit statuses,
    and mergeable is `no` when its diffstat names a conflict.
2.  *Merge pr* uses a merge commit and deletes the head branch on
    every provider.

## R14 Existing installs

1.  An absent `provider:` means `github`, and an absent `host:` means
    the provider's cloud host: every config written before this feature
    runs unchanged.
2.  On a reinstall with no `provider:`, the installer runs detection
    (R3) once and adds `provider:` and `host:` through the config
    upgrade (yngorchestrator R39), one `added` line each.

## R15 Smoke run per provider

1.  A provider is supported only after one end-to-end run in a
    throwaway `yngsandbox` repository on it:
    1.  Install into an empty folder (R4, R5) and into an existing
        clone (R3).
    2.  Plan an Epic; the person promotes one slice by hand.
    3.  Provenance passes for the person and is refused for a bot or
        access token (R10).
    4.  Dispatch, open the pull request, merge into the Epic, merge
        the Epic into `main`, and the issue closes (R12, R13).
2.  The checklist lives in `providers/README.md`. Creating the GitLab
    and Bitbucket accounts, sandboxes and tokens is a
    `workflow:ready-for-human` slice.

## R16 Documentation

1.  README.md and INSTALL.md carry a **Supported providers** table near
    the top: R1.1's providers, then a **Planned** list (R1.2), and a
    line that more providers will be added.
2.  `providers/README.md` has an **Adding a provider** section: the
    operations to implement (R7.1), the states mapping to choose (R8),
    the provenance rule to define (R10), and the smoke run (R15).
3.  `guides/epic-workflow.md`, INSTALL.md and the skill describe the
    workflow by operation, provider-neutral. Provider commands appear
    only in the provider files and in INSTALL.md's per-provider setup.

## R17 Version

1.  CHANGELOG entry; `VERSION`, the skill's `metadata.version` and the
    guide header move to 1.11.0.
