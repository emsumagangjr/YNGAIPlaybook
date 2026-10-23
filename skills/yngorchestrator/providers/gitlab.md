# GitLab provider

The operations of [README.md](README.md) for GitLab (gitlab.com and
GitLab self-managed), through `glab`. Load this file only when the
run's `provider:` is `gitlab`.

Every call goes through `glab api --hostname <host>` to the REST API
v4, so `glab` talks to the run's host and never to the one its config
or the current folder would pick. Only *create repo* uses a `glab`
subcommand, with `GITLAB_HOST=<host>`. `glab api` has no `--jq`, so its
output goes through `jq`. Every text payload (a body, a comment) is
built by `jq` and sent with `--input -`, so no text is ever read as a
flag value or as JSON.

Beside the README's names, the commands use:

- `<issues id>` and `<code id>`: `<issues repo>` and `<code repo>`
  URL-encoded, each `/` written `%2F` (`group%2Fsub%2Fproject`), as
  the REST API names a project;
- `<iid>`: the merge request's number; from a `<PR>` URL, its last
  part.

Run each block below with `set -eo pipefail`, as one script: a failed
`glab` call then stops it with `glab`'s message, whatever a later `jq`
prints.

A list call takes `--paginate`, and its output goes through
`jq -s 'flatten'`, which reads one array or one array per page alike.

On Windows, a native `jq.exe` ends its lines with CRLF, in Git Bash
too. Where a command keeps `jq`'s output in a variable or sends it
back, it ends in `tr -d '\r'`.

## Facts

| Fact              | GitLab                                                              |
|-------------------|---------------------------------------------------------------------|
| CLI               | `glab`, logged in: `glab auth status --hostname <host>`; and `jq` on `PATH` |
| Cloud host        | `gitlab.com`                                                        |
| Path form         | `<group>[/<subgroup>...]/<project>`: `^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+$` |
| Issue URL         | `https://<host>/<group>/<project>/-/issues/<n>` (a merge request: `/-/merge_requests/<n>`) |
| Issue reference   | `<group>/<project>#<n>`, the full path with every subgroup          |
| Closing reference | `Closes <issues repo>#<n>`; GitLab closes the issue when the merge request merges into the default branch, while the project's *Auto-close referenced issues on default branch* setting is on (its default). Otherwise R12.2 closes it |

States are plain labels with the state names, single colon, no scoped
labels (R8.2). An Epic carries the `epic` label. A slice names its
Epic with one body line `Parent: #<epic>`, and a `relates_to` issue
link shows it on the Epic's page (R9.2).

## read issue

``` bash
glab api --hostname <host> "projects/<issues id>/issues/<n>" |
  jq '{number: .iid, state: ({opened: "open", closed: "closed"}[.state]), state_reason: null,
       title, body: (.description // ""), labels}'
```

A `404` is *not found*: the block fails, and `glab`'s message names
the `404`. GitLab numbers merge requests apart from issues, so `<n>`
is never *a pull request* here: a merge request's number with no issue
behind it is *not found*. GitLab records no state reason:
`state_reason` is always `null`.

## set state

Read the issue's other `workflow:` labels, then add the new one and
remove those in one call. With `none`, `<state>` adds nothing:

``` bash
old=$(glab api --hostname <host> "projects/<issues id>/issues/<n>" |
  jq -r '[.labels[] | select(startswith("workflow:") and . != "<state>")] | join(",")' | tr -d '\r')
args=()
[ "<state>" != none ] && args+=(-f "add_labels=<state>")
[ -n "$old" ] && args+=(-f "remove_labels=$old")
[ ${#args[@]} -eq 0 ] || glab api --hostname <host> -X PUT "projects/<issues id>/issues/<n>" "${args[@]}" --silent
```

## mark epic

``` bash
glab api --hostname <host> -X PUT "projects/<issues id>/issues/<n>" -f add_labels=epic --silent
```

To test: the issue is an Epic when *read issue*'s labels hold `epic`.

## list children

The slices are the issues whose body has the line `Parent: #<epic>`
(R9.3), so read every issue of the issues repo and keep those:

``` bash
glab api --hostname <host> "projects/<issues id>/issues?state=all&per_page=100" --paginate |
  jq -rs --arg p "Parent: #<epic>" 'flatten | .[]
    | select((.description // "") | split("\n") | map(sub("\\s+$"; "")) | any(. == $p))
    | [.iid, ({opened: "open", closed: "closed"}[.state]), .title, (.labels | join(","))] | @tsv' |
  tr -d '\r'
```

The line must match whole, trailing spaces and `\r` aside, so
`Parent: #12` never matches `Parent: #123`. The `relates_to` links are
not read: a person may add one for any reason.

## read parent

``` bash
parent=$(glab api --hostname <host> "projects/<issues id>/issues/<n>" |
  jq -r '(.description // "") | split("\n") | map(sub("\\s+$"; ""))
    | map(select(test("^Parent: #[0-9]+$")) | ltrimstr("Parent: #")) | first // empty' | tr -d '\r')
```

An empty `parent` is no parent.

## link child

Write the `Parent:` line into the slice's body, then add the
`relates_to` link. A body that already names `<epic>` keeps its line;
one that names another Epic stops the step, naming both:

``` bash
body=$(glab api --hostname <host> "projects/<issues id>/issues/<n>" | jq -r '.description // ""' | tr -d '\r')
named=$(printf '%s\n' "$body" | sed -nE 's/^Parent: #([0-9]+)[[:space:]]*$/\1/p' | head -n 1)
if [ -z "$named" ]; then
  printf '%s\n\nParent: #%s\n' "$body" "<epic>" | jq -Rs '{description: .}' | tr -d '\r' |
    glab api --hostname <host> -X PUT "projects/<issues id>/issues/<n>" --input - --silent
elif [ "$named" != "<epic>" ]; then
  echo "issue <n> already names Parent: #$named, not #<epic>" >&2; exit 1
fi
```

The link names the Epic's project by its numeric `id`. Add it only
when the slice has no link to the Epic yet, since a second one is
refused:

``` bash
pid=$(glab api --hostname <host> "projects/<issues id>" | jq -r .id | tr -d '\r')
linked=$(glab api --hostname <host> "projects/<issues id>/issues/<n>/links" |
  jq -r --argjson e <epic> --argjson p "$pid" 'any(.[]; .iid == $e and .project_id == $p)' | tr -d '\r')
[ "$linked" = true ] || glab api --hostname <host> -X POST "projects/<issues id>/issues/<n>/links" \
  -F target_project_id="$pid" -F target_issue_iid=<epic> -f link_type=relates_to --silent
```

## provenance

Every application of the label, from the issue's label events, oldest
first; then each account's `bot` flag, username and state from the
users API:

``` bash
glab api --hostname <host> "projects/<issues id>/issues/<n>/resource_label_events" --paginate |
  jq -rs 'flatten | map(select(.action == "add" and .label.name == "workflow:ready-for-agent"))
    | sort_by(.id) | .[] | [(.user.id // "-"), (.user.username // "-"), .created_at] | @tsv' |
  tr -d '\r' |
while IFS=$'\t' read -r uid login at; do
  if [ "$uid" = - ]; then
    verdict="not human: no account on the event"
  else
    u=$(glab api --hostname <host> "users/$uid") || { echo "users/$uid: lookup failed" >&2; exit 1; }
    verdict=$(printf '%s' "$u" |
      jq -r 'if .bot == true then "not human: bot: true"
             elif .bot != false then "not human: no bot field"
             elif (.username // "" | test("^ghost[0-9]*$")) then "not human: the Ghost User"
             elif .state != "active" then "not human: state: \(.state // "none")"
             else "human" end' | tr -d '\r')
  fi
  printf '%s\t%s\t%s\n' "$login" "$verdict" "$at"
done
```

An application is a **human**'s when its event names an account and
`GET /users/:id` gives that account all three:

- `bot: false`;
- a username not matching `^ghost[0-9]*$`;
- `state: active`.

Otherwise it is not, and the verdict names the first that fails.
Project and group access tokens act as bot users, and service accounts
are bot users: all of them read `bot: true` and fail. A deleted
account's events pass to the Ghost User, which is no bot but no person
either. Its username is `ghost`, or `ghost1` and so on when `ghost` was
already taken, so the pattern refuses those, while `ghostly` or
`aghost` pass. A blocked, deactivated or banned account is not
`active` (R10.1). A users call that fails stops the step,
so no application is judged without its account. A `remove` event is
no application: the latest `add` is the one that counts.

This check sees accounts, not intent. A label applied through the
person's own token, the orchestrator's included, reads as theirs and
passes: that is why the orchestrator never applies
`workflow:ready-for-agent` itself (R10.2).

## comment

The text goes in a quoted here-document, so its backticks and `$`
stay text. On an issue:

``` bash
jq -Rs '{body: .}' <<'TEXT' | tr -d '\r' | glab api --hostname <host> -X POST "projects/<issues id>/issues/<n>/notes" --input - --silent
<text>
TEXT
```

On a merge request:

``` bash
jq -Rs '{body: .}' <<'TEXT' | tr -d '\r' | glab api --hostname <host> -X POST "projects/<code id>/merge_requests/<iid>/notes" --input - --silent
<text>
TEXT
```

The pipeline stays on the `<<'TEXT'` line: the text starts on the
next.

## close / reopen

With a comment, post it with *comment* first, then close:

``` bash
glab api --hostname <host> -X PUT "projects/<issues id>/issues/<n>" -f state_event=close --silent
glab api --hostname <host> -X PUT "projects/<issues id>/issues/<n>" -f state_event=reopen --silent
```

## create issue

``` bash
n=$(jq -Rs --arg t "<title>" --arg l "<state>" '{title: $t, labels: $l, description: .}' <file> | tr -d '\r' |
  glab api --hostname <host> -X POST "projects/<issues id>/issues" --input - | jq -r .iid | tr -d '\r')
```

## edit body

``` bash
jq -Rs '{description: .}' <file> | tr -d '\r' |
  glab api --hostname <host> -X PUT "projects/<issues id>/issues/<n>" --input - --silent
```

`<file>` holds the new body; `-` reads it from standard input.

## create pr

``` bash
jq -Rs --arg s "<branch>" --arg b "<base>" --arg t "<title>" \
    '{source_branch: $s, target_branch: $b, title: $t, description: .}' <file> | tr -d '\r' |
  glab api --hostname <host> -X POST "projects/<code id>/merge_requests" --input - | jq -r .web_url
```

It prints the merge request's URL.

## pr status

``` bash
glab api --hostname <host> "projects/<code id>/merge_requests/<iid>" |
  jq '{number: .iid, url: .web_url,
    state: ({opened: "OPEN", locked: "OPEN", merged: "MERGED", closed: "CLOSED"}[.state]),
    head: .source_branch, base: .target_branch,
    mergeable: (.detailed_merge_status as $m
      | if $m == "mergeable" then "yes"
        elif ($m | IN("checking", "unchecked", "preparing", "approvals_syncing",
                      "ci_still_running", "ci_must_pass")) then "unknown"
        else "no" end),
    checks: ((.head_pipeline.status // null) as $p
      | if $p == null then "none"
        elif $p == "success" then "passed"
        elif ($p | IN("failed", "canceled", "canceling", "skipped")) then "failed"
        else "pending" end)}'
```

`checks` is the head pipeline's status (R13.1). A pipeline waiting on
a manual job, or still created, scheduled or running, is `pending`. A
skipped pipeline did not pass, so it is `failed`. `mergeable` is
`detailed_merge_status`: `yes` only at `mergeable`; anything blocking
the merge for good (a conflict, a needed rebase, a draft, open threads,
missing approvals) is `no`. GitLab checks mergeability asynchronously,
so a fresh merge request may read `unknown` once.

## list prs

``` bash
glab api --hostname <host> "projects/<code id>/merge_requests?state=all&per_page=100" --paginate |
  jq -rs 'flatten | .[] | select(.source_branch | test("<pattern>"))
    | [.iid, ({opened: "OPEN", locked: "OPEN", merged: "MERGED", closed: "CLOSED"}[.state]),
       .source_branch, .target_branch, .web_url] | @tsv' |
  tr -d '\r'
```

## merge pr

GitLab makes the merge commit only when the project's merge method
does: `merge`, or `rebase_merge` (a merge commit on a semi-linear
history). A fast-forward project (`ff`), or one that squashes always,
stops the step, naming the setting (*Settings > Merge requests*) for
the person to change (R13.2):

``` bash
read -r method squash <<<"$(glab api --hostname <host> "projects/<code id>" |
  jq -r '[.merge_method, .squash_option] | @tsv' | tr -d '\r')"
case "$method" in merge|rebase_merge) ;; *) echo "merge method is $method, not a merge commit" >&2; exit 1 ;; esac
[ "$squash" != always ] || { echo "the project squashes every merge" >&2; exit 1; }
sha=$(glab api --hostname <host> "projects/<code id>/merge_requests/<iid>" | jq -r .sha | tr -d '\r')
glab api --hostname <host> -X PUT "projects/<code id>/merge_requests/<iid>/merge" \
  -f sha="$sha" -F squash=false -F should_remove_source_branch=true | jq -r .state
```

It prints `merged`. Without `auto_merge`, GitLab merges now or refuses
with the reason; *pr status* has already checked the pipeline. `sha`
satisfies a group that requires one on the merge API.

## create repo

``` bash
GITLAB_HOST=<host> glab repo create <group>/<project> --private --readme --defaultBranch main --skipGitInit
```

`--readme` makes the first commit, so `main` exists before the bare
clone (R5). `--skipGitInit` keeps `glab` from cloning into the current
folder: the bare clone comes next.

## setup states

Create each label that is missing from the issues repo; one that
exists is left as it is, as the installer does (R8.4), and so is one
of that name inherited from a group. A label's name in the path writes
`:` as `%3A`:

``` bash
glab api --hostname <host> "projects/<issues id>/labels/<name, : as %3A>" --silent 2>/dev/null ||
  glab api --hostname <host> -X POST "projects/<issues id>/labels" \
    -f "name=<name>" -f "color=#<color>" -f "description=<description>" --silent
```

The lookup is judged by `glab`'s exit status alone: a `404` creates
the label.

| Name                       | Color    | Description |
|----------------------------|----------|-------------|
| `epic`                     | `3e4b9e` | Feature: tracker card plus integration branch |
| `workflow:needs-triage`    | `fbca04` | Triage fills in every label |
| `workflow:needs-info`      | `d876e3` | A person must answer before work starts |
| `workflow:ready-for-agent` | `0e8a16` | Gate 1 passed: an agent may pick it up (set by a person, or by plan approval if auto-promote: yes) |
| `workflow:ready-for-human` | `1d76db` | Gate 1 passed: a person picks it up |
| `workflow:in-progress`     | `c5def5` | Being worked; no PR yet (set by the dispatcher) |
| `workflow:in-review`       | `5319e7` | PR open, waiting for a person (set by the dispatcher) |
