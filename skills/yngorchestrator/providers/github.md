# GitHub provider

The operations of [README.md](README.md) for GitHub (github.com and
GitHub Enterprise Server), through `gh`. Load this file only when the
run's `provider:` is `github`, or absent.

Every command below sets `GH_HOST=<host>`, so `gh` talks to the run's
host and never to its own default, and names its repository: `-R` on
`gh issue` and `gh pr`, the path on `gh api`.

## Facts

| Fact              | GitHub                                                              |
|-------------------|---------------------------------------------------------------------|
| CLI               | `gh`, logged in: `gh auth status --hostname <host>`                 |
| Cloud host        | `github.com`                                                        |
| Path form         | `<owner>/<repo>`: `^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$`               |
| Issue URL         | `https://<host>/<owner>/<repo>/issues/<n>` (a pull request: `/pull/<n>`) |
| Issue reference   | `<owner>/<repo>#<n>`                                                |
| Closing reference | `Closes <issues repo>#<n>`; GitHub closes the issue when the pull request merges into the default branch |

States are plain labels with the state names (R8.2). An Epic carries
the `epic` label. Parent and child are GitHub's native sub-issues
(R9.1).

## read issue

``` bash
GH_HOST=<host> gh api "repos/<issues repo>/issues/<n>" \
  --jq '{number, state, state_reason, title, body: (.body // ""), labels: [.labels[].name], pr: (.pull_request != null)}'
```

A `404` is *not found*. `pr: true` is *a pull request*: the issues
API also serves pull requests.

## set state

Read the issue's other `workflow:` labels, then add the new one and
remove those in one call. With `none`, `<state>` adds nothing:

``` bash
old=$(GH_HOST=<host> gh api "repos/<issues repo>/issues/<n>" \
  --jq '[.labels[].name | select(startswith("workflow:") and . != "<state>")] | join(",")')
args=()
[ "<state>" != none ] && args+=(--add-label "<state>")
[ -n "$old" ] && args+=(--remove-label "$old")
[ ${#args[@]} -eq 0 ] || GH_HOST=<host> gh issue edit <n> -R <issues repo> "${args[@]}"
```

## mark epic

``` bash
GH_HOST=<host> gh issue edit <n> -R <issues repo> --add-label epic
```

To test: the issue is an Epic when *read issue*'s labels hold `epic`.

## list children

``` bash
GH_HOST=<host> gh api "repos/<issues repo>/issues/<epic>/sub_issues" --paginate \
  --jq '.[] | [.number, .state, .title, ([.labels[].name] | join(","))] | @tsv'
```

## read parent

``` bash
parent=$(GH_HOST=<host> gh api "repos/<issues repo>/issues/<n>/parent" --jq .number 2>/dev/null) || parent=
```

Judge by the exit status, not the output: on a `404` (no parent), `gh`
still prints the error body to standard output.

## link child

The REST call takes the slice's numeric `id`, not its number:

``` bash
id=$(GH_HOST=<host> gh api "repos/<issues repo>/issues/<n>" --jq .id)
GH_HOST=<host> gh api -X POST "repos/<issues repo>/issues/<epic>/sub_issues" -F sub_issue_id="$id"
```

## provenance

Every application of the label, from the issue's timeline, oldest
first:

``` bash
GH_HOST=<host> gh api "repos/<issues repo>/issues/<n>/timeline" --paginate \
  --jq '.[] | select(.event=="labeled" and .label.name=="workflow:ready-for-agent")
        | [.actor.login, .actor.type, (.performed_via_github_app.slug // "-"), .created_at] | @tsv'
```

An application is a **human**'s when all three hold:

- `actor.type` is `User`;
- the login is no bot account (none ending in `[bot]`);
- `performed_via_github_app` is empty (`-`).

Otherwise it is not, and the failing condition is the reason.

This check sees accounts, not intent. A label applied through the
person's own token, the orchestrator's included, reads as theirs and
passes: that is why the orchestrator never applies
`workflow:ready-for-agent` itself (R10.2).

## comment

On an issue, and on a pull request:

``` bash
GH_HOST=<host> gh issue comment <n> -R <issues repo> --body "<text>"
GH_HOST=<host> gh pr comment <PR> -R <code repo> --body "<text>"
```

## close / reopen

``` bash
GH_HOST=<host> gh issue close <n> -R <issues repo> --comment "<text>"
GH_HOST=<host> gh issue reopen <n> -R <issues repo>
```

Without a comment, leave out `--comment`.

## create issue

``` bash
url=$(GH_HOST=<host> gh issue create -R <issues repo> --title "<title>" --label "<state>" --body-file <file>)
n=${url##*/}
```

## edit body

``` bash
GH_HOST=<host> gh issue edit <n> -R <issues repo> --body-file <file>
```

`<file>` holds the new body; `-` reads it from standard input.

## create pr

``` bash
GH_HOST=<host> gh pr create -R <code repo> --base <base> --head <branch> --title "<title>" --body-file <file>
```

It prints the pull request's URL.

## pr status

``` bash
GH_HOST=<host> gh pr view <PR> -R <code repo> \
  --json number,url,state,headRefName,baseRefName,mergeable,statusCheckRollup \
  --jq '{number, url, state, head: .headRefName, base: .baseRefName,
    mergeable: ({MERGEABLE: "yes", CONFLICTING: "no"}[.mergeable] // "unknown"),
    checks: ([.statusCheckRollup[]? | (.conclusion // .state // "")] as $c
      | if ($c | length) == 0 then "none"
        elif all($c[]; . == "SUCCESS" or . == "NEUTRAL" or . == "SKIPPED") then "passed"
        elif any($c[]; . == "" or . == "PENDING" or . == "EXPECTED") then "pending"
        else "failed" end)}'
```

A check run still going has no conclusion yet, and a commit status
still going reads `PENDING`: both are `pending`.

## list prs

``` bash
GH_HOST=<host> gh pr list -R <code repo> --state all --limit 1000 \
  --json number,state,headRefName,baseRefName,url \
  --jq '.[] | select(.headRefName | test("<pattern>")) | [.number, .state, .headRefName, .baseRefName, .url] | @tsv'
```

## merge pr

``` bash
GH_HOST=<host> gh pr merge <PR> -R <code repo> --merge --delete-branch
```

## create repo

``` bash
GH_HOST=<host> gh repo create <owner>/<repo> --private --add-readme
```

`--add-readme` makes the first commit, so `main` exists before the
bare clone (R5).

## setup states

Create or update each label on the issues repo; `--force` updates one
that exists:

``` bash
GH_HOST=<host> gh label create "<name>" -R <issues repo> -c "<color>" -d "<description>" --force
```

| Name                       | Color    | Description |
|----------------------------|----------|-------------|
| `epic`                     | `3e4b9e` | Feature: tracker card plus integration branch |
| `workflow:needs-triage`    | `fbca04` | Triage fills in every label |
| `workflow:needs-info`      | `d876e3` | A person must answer before work starts |
| `workflow:ready-for-agent` | `0e8a16` | Gate 1 passed: an agent may pick it up (set by a person, or by plan approval if auto-promote: yes) |
| `workflow:ready-for-human` | `1d76db` | Gate 1 passed: a person picks it up |
| `workflow:in-progress`     | `c5def5` | Being worked; no PR yet (set by the dispatcher) |
| `workflow:in-review`       | `5319e7` | PR open, waiting for a person (set by the dispatcher) |
