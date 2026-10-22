# Provider files

Every call the orchestrator and the slice worker make to a git provider
lives in one file here, `<provider>.md`, one file per provider. The
step files ([SKILL.md](../SKILL.md), [locate.md](../locate.md) and the
others) and `agents/slice-worker.md` name the operations below, never a
command. A provider file turns each operation into its provider's
commands.

## Which file a run loads

Step 3 of [locate.md](../locate.md) reads `provider:` and `host:` from
`<root>/.yngaiplaybook/yngorchestratorconfig.yml` at the start of every
run. An absent `provider:` is `github`; an absent `host:` is the
provider's **cloud host** (its *Facts* below). The run then loads
`providers/<provider>.md`, and never another provider's file.

The supported providers are the files in this folder, other than this
README. A `provider:` with no file here stops the run before the lock,
naming the value and that list.

The dispatch prompt's `PROVIDER` field carries the provider, the host
and this file's absolute path, so the slice worker loads the same file
for *read issue*, *list prs* and *create pr*.

## What every provider file states

### Facts

| Fact              | What it is                                                                    |
|-------------------|-------------------------------------------------------------------------------|
| CLI               | the tool and how the person is logged in on `<host>`                          |
| Cloud host        | the `host:` an absent key means                                               |
| Path form         | a repository's path on the provider, with the `grep -E` pattern that checks it |
| Issue URL         | an issue's web address, so step 2 of locate.md can read a URL argument        |
| Issue reference   | how a pull request, a commit or a comment names an issue by full reference    |
| Closing reference | the line in a pull request's body that closes its issue on merge (R12)        |

The path forms (R11.2), each part of letters, digits, `-`, `_` and `.`:

| Provider  | Path form                            | Pattern |
|-----------|--------------------------------------|---------|
| GitHub    | `<owner>/<repo>`                     | `^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$` |
| GitLab    | `<group>[/<subgroup>...]/<project>`, nested groups included | `^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+$` |
| Bitbucket | `<workspace>/<repo>`                 | `^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$` |

Step 3 of [locate.md](../locate.md) checks `origin`'s path and the
config's `issues:` against the configured provider's pattern, so a
GitLab nested path passes on GitLab and stops a GitHub run. `issues:`
names a project on the same provider and host as the code repo
(R11.1).

### Operations

Every provider file implements each operation below, under a heading
with its name. The words are the interface: inputs in the operation's
column, outputs in the last.

| Operation      | Takes                                    | Gives |
|----------------|------------------------------------------|-------|
| read issue     | `<n>`                                    | number, title, body, `open` or `closed`, state reason, its labels (state names, `epic`); or *not found*; or *a pull request* when `<n>` is one |
| set state      | `<n>`, a state, or `none`                | the issue at that one `workflow:` state, every other `workflow:` state removed (R8); `none` removes them all |
| mark epic      | `<n>`; or `<n>` to test                  | the issue marked an Epic; or whether it is one |
| list children  | `<epic>`                                 | one line per slice of the Epic: number, `open` or `closed`, title, its labels (R9) |
| read parent    | `<n>`                                    | the Epic's number, or none (R9) |
| link child     | `<epic>`, `<n>`                          | the slice attached to its Epic (R9) |
| provenance     | `<n>`                                    | every application of `workflow:ready-for-agent`, oldest first: account, human or not and why, time (R10) |
| comment        | `<n>`, or a pull request `<PR>`; text    | the comment posted |
| close / reopen | `<n>`; for close, an optional comment    | the issue closed (with the comment) or reopened |
| create issue   | title, state, body file                  | the new issue's number, at that state |
| edit body      | `<n>`, the new body                      | the issue's body replaced |
| create pr      | head branch, base, title, body file      | the pull request's URL |
| pr status      | `<PR>`                                   | number, URL, `OPEN` / `MERGED` / `CLOSED`, head, base, mergeable `yes` / `no` / `unknown`, checks `passed` / `none` / `pending` / `failed` |
| list prs       | a `grep -E` pattern for the head branch  | one line per pull request whose head matches, in any state: number, state, head, base, URL |
| merge pr       | `<PR>`                                   | merged with a merge commit, head branch deleted (R13.2) |
| create repo    | the repository's path                    | a private repository with a first commit on `main` (R5) |
| setup states   | none                                     | the workflow states and `epic` exist on the issues repo (R8.4) |

The names used throughout:

- `<host>` is the provider's host, `<code repo>` `origin`'s repository
  and `<issues repo>` the one the issues live in, both in the path
  form. Issue operations target `<issues repo>`; pull request
  operations and *create repo* target `<code repo>`. Every call names
  its repository and its host; none is left to a tool's default.
- `<n>` and `<epic>` are issue numbers in the issues repo. `<PR>` is a
  pull request's number or URL, as a completion report gives it.
- *Pull request* means a merge request on GitLab.
- The states have the same names on every provider (R8.1):
  `workflow:needs-triage`, `workflow:ready-for-agent`,
  `workflow:ready-for-human`, `workflow:in-progress`,
  `workflow:in-review`, and `epic`. A provider that stores them
  differently maps them in its file; the step files never see that.

A call that fails for any reason but the outcomes in the table (*not
found*, *a pull request*, no parent) stops the step with the tool's
message. Credentials are never written to a file, a log, a comment or
a report, and never echoed (R6.2).

## Supported and planned

Supported: one file each, `github.md` first. Planned (R1.2): Azure
DevOps, Bitbucket Data Center, Jira as an issue tracker,
Gitea/Forgejo, and an issues repo on a different provider from the
code. More providers will be added, each behind this same seam.

## Adding a provider

1. Write `<provider>.md` here: its *Facts*, then every operation in the
   table above, each with its commands and the outputs the table names.
2. Choose the states mapping (R8): plain labels with the names above
   where the provider has labels; otherwise the field that holds one
   value per issue, and how an Epic is marked.
3. Define **provenance** (R10): which record says who set
   `workflow:ready-for-agent`, and the test that tells a person's
   account from a bot, an app or an access token. Say beside it that a
   change made with the person's own token passes, so the orchestrator
   never sets `workflow:ready-for-agent` itself.
4. Pass the smoke run below.

The step files do not change: a new provider is this one file, the
installer's detection and checks, and its row in the documentation's
*Supported providers* table.

## Smoke run

A provider is supported only after one end-to-end run in a throwaway
`yngsandbox` repository on it (R15):

- [ ] Install into an empty folder (R4, R5), and into an existing clone
      (R3).
- [ ] Plan an Epic; the person promotes one slice by hand.
- [ ] *Provenance* passes for the person, and is refused for a bot or
      an access token (R10).
- [ ] Dispatch, open the pull request, merge it into the Epic, merge
      the Epic into `main`, and the issue closes (R12, R13).
