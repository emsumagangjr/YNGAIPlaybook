# Bitbucket provider

The operations of [README.md](README.md) for Bitbucket Cloud
(bitbucket.org), through its REST API with `curl`. Load this file only
when the run's `provider:` is `bitbucket`. Bitbucket Data Center is
planned, not supported (R1.2, R3.4).

Bitbucket has no CLI to log in with, so every operation below is a
`curl` call against `https://api.bitbucket.org/2.0`, its answer read
with `jq`. The calls follow Atlassian's REST reference
(<https://developer.atlassian.com/cloud/bitbucket/rest/>); the ones
marked in *Smoke run checks* at the end still need the live run (#107)
to confirm them.

## Facts

| Fact              | Bitbucket                                                           |
|-------------------|---------------------------------------------------------------------|
| CLI               | `curl` and `jq`, with `BITBUCKET_EMAIL` (the Atlassian account's email) and `BITBUCKET_API_TOKEN` set: `bb GET user` answers |
| Cloud host        | `bitbucket.org` (the API is always `api.bitbucket.org/2.0`)         |
| Path form         | `<workspace>/<repo>`: `^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$`           |
| Issue URL         | `https://bitbucket.org/<workspace>/<repo>/issues/<n>` (a pull request: `/pull-requests/<n>`) |
| Issue reference   | `<workspace>/<repo>#<n>`                                            |
| Closing reference | `Closes #<n>`, and only when the issues repo is the code repo; the explicit *close* after the merge covers every other case (R12) |

States are the issue's **component**, named without the `workflow:`
prefix: `needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human`, `in-progress`, `in-review` (R8.3). An issue holds
one component, so it holds one state; on a Bitbucket issues repo the
component belongs to the workflow. An Epic is an issue in the `epic`
**milestone**. A slice names its Epic with one body line,
`Parent: #<epic>` (R9.2).

Issue numbers and pull request numbers are separate on Bitbucket: `<n>`
always names an issue, and a pull request's address is
`/pull-requests/<n>`, which step 2 of [locate.md](../locate.md) stops on.

## The helpers

Every command block below starts with these helpers. Shell state does
not carry from one call to the next, so paste them in front of each
block. They hold no secret: the credentials come from the environment.

``` bash
set -o pipefail
bb() {  # bb <method> <API path or full URL> [<JSON body>] [curl options...]
  local method=$1 url=$2 body=${3-} cred
  shift 2; [ $# -gt 0 ] && shift
  case $url in https://*) ;; *) url="https://api.bitbucket.org/2.0/$url" ;; esac
  cred="$BITBUCKET_EMAIL:$BITBUCKET_API_TOKEN"
  cred=${cred//\\/\\\\}; cred=${cred//\"/\\\"}
  set -- -sS -L --fail-with-body -K - -X "$method" "$@"
  [ -n "$body" ] && set -- "$@" -H 'Content-Type: application/json' --data-binary "$body"
  printf 'user = "%s"\n' "$cred" | curl "$@" "$url"
}
bb_all() {  # bb_all <API path>: the values of every page, one JSON object per line
  local url=$1 page
  while [ -n "$url" ]; do
    page=$(bb GET "$url") || return
    printf '%s\n' "$page" | jq -c '.values[]'
    url=$(printf '%s\n' "$page" | jq -r '.next // empty' | tr -d '\r')
  done
}
bb_jq='def open_closed: if (.state | IN("new", "open", "submitted", "on hold")) then "open" else "closed" end;
def reason: {resolved: "completed", closed: "completed", invalid: "not_planned", duplicate: "not_planned", wontfix: "not_planned"}[.state];
def labels: [(.component.name // empty
    | if IN("needs-triage", "needs-info", "ready-for-agent", "ready-for-human", "in-progress", "in-review") then "workflow:" + . else . end),
  (.milestone.name // empty | select(. == "epic"))];'
```

`bb` sends Basic authentication with the email and the API token. The
pair reaches `curl` as a config line on its standard input (`-K -`),
written by the shell's own `printf`: it is never on a command line, in
a file, in a log or in the output (R6.2). Never run these blocks under
`set -x`, which would print it. `--fail-with-body` makes every HTTP
error a non-zero exit with Bitbucket's message, and `pipefail` carries
that exit through a pipe into `jq`: a failed call stops the step with
that message, and is never read as an empty answer.

`bb_jq` maps an issue onto the README's words: Bitbucket's states `new`,
`open`, `submitted` and `on hold` are `open`, the rest `closed`; the
state reason is `completed` for `resolved` and `closed`, `not_planned`
for `invalid`, `duplicate` and `wontfix`; the labels are the component
as its `workflow:` state, and `epic` for the `epic` milestone.

Where a step file says *set state*, *mark epic*, *close* or *reopen*,
the call goes through the issue's `/changes`, so each leaves a change
record: that record is what *provenance* reads.

## read issue

``` bash
out=$(bb GET "repositories/<issues repo>/issues/<n>" "" -w '\n%{http_code}')
case ${out##*$'\n'} in
  200) printf '%s\n' "${out%$'\n'*}" | jq "$bb_jq"'{number: .id, state: open_closed, state_reason: reason,
         title, body: (.content.raw // ""), labels: labels, pr: false}' ;;
  404) echo 'not found'; printf '%s\n' "${out%$'\n'*}" >&2 ;;
  *)   printf '%s\n' "${out%$'\n'*}" >&2; false ;;
esac
```

A `404` is *not found*. Bitbucket's message follows on standard error:
it says when the cause is a repository with no issue tracker
(*Repository has no issue tracker*), so name it when you stop. The answer is never *a pull request*:
`<n>` is always an issue number here.

## set state

The new component replaces the old in one change, so the issue holds
one state. With `none`, the component is cleared:

``` bash
want=<state>; want=${want#workflow:}
cur=$(bb GET "repositories/<issues repo>/issues/<n>" | jq -r '.component.name // ""' | tr -d '\r')
if [ "$want" = none ]; then
  [ -z "$cur" ] || bb POST "repositories/<issues repo>/issues/<n>/changes" \
    '{"changes": {"component": {"new": null}}}' >/dev/null
elif [ "$cur" != "$want" ]; then
  bb POST "repositories/<issues repo>/issues/<n>/changes" \
    "$(jq -nc --arg c "$want" '{changes: {component: {new: $c}}}')" >/dev/null
fi
```

The component must exist on the issues repo (*setup states*); a name
that does not is refused with Bitbucket's message.

## mark epic

``` bash
bb POST "repositories/<issues repo>/issues/<n>/changes" \
  '{"changes": {"milestone": {"new": "epic"}}}' >/dev/null
```

To test: the issue is an Epic when *read issue*'s labels hold `epic`,
that is, its milestone is `epic`.

## list children

The issues of the issues repo whose body holds the line
`Parent: #<epic>`, in any state:

``` bash
bb_all "repositories/<issues repo>/issues?pagelen=50" |
  jq -r --arg e "<epic>" "$bb_jq"'
    select((.content.raw // "") | split("\n") | any(.[]; test("^Parent: #" + $e + "\\s*$")))
    | [.id, open_closed, .title, (labels | join(","))] | @tsv'
```

The line must match whole, so `Parent: #12` is not a child of `#1`.

## read parent

``` bash
parent=$(bb GET "repositories/<issues repo>/issues/<n>" |
  jq -r '[(.content.raw // "") | split("\n")[] | capture("^Parent: #(?<p>[0-9]+)\\s*$").p] | first // empty' |
  tr -d '\r')
```

An empty `parent` means none: the body has no `Parent:` line.

## link child

Rewrite the slice's body with one `Parent: #<epic>` line at the end,
dropping any other `Parent:` line, so the slice has one parent:

``` bash
json=$(bb GET "repositories/<issues repo>/issues/<n>" |
  jq -c --arg e "<epic>" '{content: {raw: (
    ((.content.raw // "") | split("\n") | map(select(test("^Parent: #[0-9]+\\s*$") | not))
      | join("\n") | sub("\\s+$"; "")) + "\n\nParent: #" + $e + "\n")}}')
bb PUT "repositories/<issues repo>/issues/<n>" "$json" >/dev/null
```

## provenance

Every change that set the component to `ready-for-agent`, from the
issue's `/changes`, oldest first:

``` bash
bb_all "repositories/<issues repo>/issues/<n>/changes?pagelen=50" |
  jq -sr 'map(select(.changes.component.new == "ready-for-agent")) | sort_by(.created_on)[]
    | [(.user.nickname // .user.display_name // "-"), (.user.type // "none"),
       (if .user.type == "user" then "human" else "not human: author type is " + (.user.type // "none") end),
       .created_on] | @tsv'
```

An application is a **human**'s when the change's author has
`type: user`. Any other type is not, and that type is the reason:
workspace, project and repository access tokens act as `app_user`, and
fail (R10.1). The latest line is the one that counts.

An issue created with its component already at `ready-for-agent` has no
change setting it, so *provenance* lists nothing and Gate 1 refuses it:
the person sets the component on the issue after creating it. *Create
issue* below makes the same change record for the orchestrator's own
issues.

This check sees accounts, not intent. A change made through the
person's own API token, the orchestrator's included, reads as theirs
and passes: that is why the orchestrator never sets `ready-for-agent`
itself (R10.2).

## comment

On an issue, and on a pull request (`${PR##*/}` takes the number from
a pull request's URL, and leaves a number as it is):

``` bash
PR=<PR>
bb POST "repositories/<issues repo>/issues/<n>/comments" \
  "$(jq -nc --arg t "<text>" '{content: {raw: $t}}')" >/dev/null
bb POST "repositories/<code repo>/pullrequests/${PR##*/}/comments" \
  "$(jq -nc --arg t "<text>" '{content: {raw: $t}}')" >/dev/null
```

## close / reopen

Close is the state `resolved`; with a comment, *comment* first. Reopen
is the state `open`:

``` bash
bb POST "repositories/<issues repo>/issues/<n>/changes" '{"changes": {"state": {"new": "resolved"}}}' >/dev/null
bb POST "repositories/<issues repo>/issues/<n>/changes" '{"changes": {"state": {"new": "open"}}}' >/dev/null
```

## create issue

Create the issue as a task with no component, then *set state* `<n>`
`<state>`, so the state is a change on record (*provenance*):

``` bash
n=$(bb POST "repositories/<issues repo>/issues" \
  "$(jq -nc --arg t "<title>" --rawfile b "<file>" '{title: $t, kind: "task", content: {raw: $b}}')" |
  jq -r .id | tr -d '\r')
```

## edit body

``` bash
bb PUT "repositories/<issues repo>/issues/<n>" \
  "$(jq -nc --rawfile b "<file>" '{content: {raw: $b}}')" >/dev/null
```

`<file>` holds the new body.

## create pr

``` bash
bb POST "repositories/<code repo>/pullrequests" \
  "$(jq -nc --arg t "<title>" --arg h "<branch>" --arg b "<base>" --rawfile d "<file>" \
    '{title: $t, description: $d, source: {branch: {name: $h}}, destination: {branch: {name: $b}}}')" |
  jq -r .links.html.href
```

It prints the pull request's URL.

## pr status

``` bash
PR=<PR>; id=${PR##*/}
checks=$(bb_all "repositories/<code repo>/pullrequests/$id/statuses?pagelen=50" |
  jq -sr '[.[].state] | if length == 0 then "none"
    elif all(.[]; . == "SUCCESSFUL") then "passed"
    elif any(.[]; . == "INPROGRESS") then "pending"
    else "failed" end') || checks=unknown
mergeable=$(bb_all "repositories/<code repo>/pullrequests/$id/diffstat?pagelen=100" |
  jq -sr 'if any(.[]; .status | IN("merge conflict", "local deleted", "remote deleted", "rename conflict", "rename deleted"))
    then "no" else "yes" end') || mergeable=unknown
bb GET "repositories/<code repo>/pullrequests/$id" |
  jq --arg m "$(printf '%s' "$mergeable" | tr -d '\r')" --arg c "$(printf '%s' "$checks" | tr -d '\r')" \
    '{number: .id, url: .links.html.href,
      state: ({OPEN: "OPEN", MERGED: "MERGED"}[.state] // "CLOSED"),
      head: .source.branch.name, base: .destination.branch.name, mergeable: $m, checks: $c}'
```

The checks are the **commit statuses** on the pull request's head
commit (Bitbucket Pipelines, and any CI that reports to Bitbucket):
all `SUCCESSFUL` is `passed`, one still `INPROGRESS` is `pending`, and
`FAILED` or `STOPPED` is `failed`. `checks: unknown` (the call failed)
is no pass. A `DECLINED` or `SUPERSEDED` pull request is `CLOSED`.

Bitbucket's API has no mergeable flag. The pull request's diffstat
names each file a merge would conflict on with a conflict status; none
is `yes`, and a failed call is `unknown`.

## list prs

``` bash
bb_all "repositories/<code repo>/pullrequests?state=OPEN&state=MERGED&state=DECLINED&state=SUPERSEDED&pagelen=50" |
  jq -r --arg p "<pattern>" 'select(.source.branch.name | test($p))
    | [.id, ({OPEN: "OPEN", MERGED: "MERGED"}[.state] // "CLOSED"), .source.branch.name,
       .destination.branch.name, .links.html.href] | @tsv'
```

## merge pr

[merge.md](../merge.md) reads *pr status* first (R13.1), so an `auto`
merge happens only with the commit statuses `passed` or `none`. Then:

``` bash
PR=<PR>
bb POST "repositories/<code repo>/pullrequests/${PR##*/}/merge" \
  '{"type": "pullrequest", "merge_strategy": "merge_commit", "close_source_branch": true}' >/dev/null
```

`merge_commit` makes a merge commit and `close_source_branch` deletes
the head branch (R13.2). A merge that takes long answers `202` and goes
on in the background: read *pr status* until it shows `MERGED`.

After a merge into `main`, the step files *read issue* and *close* the
issue while it is still open (R12.2). On Bitbucket that is the rule
whenever the issues repo is not the code repo, where `Closes #<n>`
would name the code repo's own issue, and whenever the closing keyword
did not act (*Smoke run checks*).

## create repo

Create the repository with its issue tracker, then make the first
commit on `main` through the API, so `main` exists before the bare
clone (R5) and no git credential is needed:

``` bash
bb POST "repositories/<workspace>/<repo>" '{"scm": "git", "is_private": true, "has_issues": true}' >/dev/null
printf '# %s\n' "<repo>" > "<scratch>/README.md"
bb POST "repositories/<workspace>/<repo>/src" "" \
  -F "README.md=@<scratch>/README.md" -F branch=main -F "message=Initial commit" >/dev/null
```

`<scratch>` is a folder outside the project.

## setup states

Bitbucket's API reads components and milestones but has no call to
create them (R8.4). List what is missing:

``` bash
have=$(bb_all "repositories/<issues repo>/components?pagelen=100" | jq -r .name | tr -d '\r')
for c in needs-triage needs-info ready-for-agent ready-for-human in-progress in-review; do
  printf '%s\n' "$have" | grep -qxF "$c" || echo "missing component: $c"
done
bb_all "repositories/<issues repo>/milestones?pagelen=100" | jq -r .name | tr -d '\r' |
  grep -qxF epic || echo "missing milestone: epic"
```

Each missing one is a `warning` for the person, naming it and where to
create it: the repository's **Repository settings > Issues >
Components** and **Milestones**, at
`https://bitbucket.org/<issues repo>/admin`, with the issue tracker
turned on. The components' meanings are the label descriptions in
[github.md](github.md)'s *setup states*.

## Smoke run checks

Atlassian's reference leaves these open; the Bitbucket smoke run (#107,
R15) checks each, and this file changes where one fails:

- [ ] **Components and milestones cannot be created through the API.**
      No create call is documented; confirm none exists, or move
      *setup states* to it.
- [ ] **Closing keywords in pull request descriptions.** Bitbucket
      resolves issues from `Closes #<n>` in commit messages; check
      whether a pull request description carrying it resolves the issue
      when the pull request merges into `main`. Either way the explicit
      *close* after the merge keeps R12.2 true.
- [ ] **`app_user` in `/changes`.** Set the component to
      `ready-for-agent` once with the person's API token and once with
      a repository access token; the first change's author must read
      `type: user`, the second `app_user`, so *provenance* passes the
      first and refuses the second.

Also to confirm on the same run:

- [ ] A change's `changes.component.new` holds the component's name,
      and `{"new": null}` clears it.
- [ ] A pull request's diffstat shows a conflicting file with a
      conflict status, so *pr status* gives `mergeable: no`.
