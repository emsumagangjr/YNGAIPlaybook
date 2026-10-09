# Completion report

The last message a slice worker sends. It is the worker's whole hand-off:
the orchestrator acts on this report alone, without re-reading the work.

``` text
STATUS:        done | blocked | failed | needs-human
SUMMARY:       what was delivered, in one or two sentences
BRANCH:        slice branch name
PR:            pull request URL, or "none"
COMMITS:       short SHA and subject, one per line
TESTS:         what ran and the result
REVIEW RECORD: open decisions for the reviewer, one per line, or "none"
ISSUES:        issues opened, or the cause of a blocker, or "none"
```

Every field appears, in this order, even when its value is "none".

## STATUS

| Value         | Means                                                                 |
|---------------|-----------------------------------------------------------------------|
| `done`        | Every acceptance criterion met, review run, branch pushed, PR open    |
| `blocked`     | Cannot continue without something outside the slice; `ISSUES` names it |
| `failed`      | Tried and could not make it work; `ISSUES` says what was tried         |
| `needs-human` | The slice reached something a person must decide or do; `ISSUES` gives the reason in one sentence |

`needs-human` covers everything on the guide's *Never promoted to
`ready-for-agent`* list, which `agents/slice-worker.md` carries for the
worker to act on.

## REVIEW RECORD

The same record that goes in the PR description: decisions only a person
can make, phrased as the open question. Findings the worker could fix
are fixed before the PR opens and do not appear here.

## Example

``` text
STATUS:        done
SUMMARY:       Users can sign in with a Microsoft account; callback and token refresh covered by tests.
BRANCH:        slice/101-oauth
PR:            https://github.com/acme/app/pull/131
COMMITS:       3f2a91c #101 Add Microsoft OAuth sign-in
               8b0d4e2 #101 Refresh expired Microsoft tokens
TESTS:         pytest auth/ — 42 passed
REVIEW RECORD: Should a Microsoft account with no matching email create a new user or be refused?
ISSUES:        none
```
