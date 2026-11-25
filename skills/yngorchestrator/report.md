# Worker reports

A slice worker sends two kinds of report, and one never stands in for
the other. The **completion report** is its last message and its whole
hand-off: the orchestrator acts on that report alone, without
re-reading the work. An **interim report** is news while the work runs:
where the worker has got to, which the dispatcher logs and the run
board shows on the slice's row (yngboard R14). News is not a hand-off,
and a worker that sent no interim report still ends with a completion
report.

## Completion report

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

### STATUS

| Value         | Means                                                                 |
|---------------|-----------------------------------------------------------------------|
| `done`        | Every acceptance criterion met, review run, branch pushed, PR open    |
| `blocked`     | Cannot continue without something outside the slice; `ISSUES` names it |
| `failed`      | Tried and could not make it work; `ISSUES` says what was tried         |
| `needs-human` | The slice reached something a person must decide or do; `ISSUES` gives the reason in one sentence |

`needs-human` covers everything on the guide's *Never promoted to
`ready-for-agent`* list, which `agents/slice-worker.md` carries for the
worker to act on.

### REVIEW RECORD

The same record that goes in the PR description: decisions only a person
can make, phrased as the open question. Findings the worker could fix
are fixed before the PR opens and do not appear here.

### Example

``` text
STATUS:        done
SUMMARY:       Users can sign in with a Microsoft account; callback and token refresh covered by tests.
BRANCH:        slice/101-oauth
PR:            https://github.com/acme/app/pull/131
COMMITS:       3f2a91c acme/app#101 Add Microsoft OAuth sign-in
               8b0d4e2 acme/app#101 Refresh expired Microsoft tokens
TESTS:         pytest auth/ — 42 passed
REVIEW RECORD: Should a Microsoft account with no matching email create a new user or be refused?
ISSUES:        none
```

## Interim report

Sent as each step of `agents/slice-worker.md` finishes — its steps 1
to 6, the report itself being step 7 — and when the worker stops early
(yngboard R14.1). It is **one line**, appended to the progress channel
the dispatch prompt names in `PROGRESS:`, and it carries four things
and no more:

``` text
<UTC instant> | <issues repo>#<n> | <step> | <one line>
```

| Field               | What it is                                                        |
|---------------------|-------------------------------------------------------------------|
| `<UTC instant>`     | `date -u +%Y-%m-%dT%H:%M:%SZ`: it names its zone, because the board derives an elapsed figure from it (yngboard R5.4) |
| `<issues repo>#<n>` | the issue's full reference, exactly as the prompt's `ISSUE` writes it |
| `<step>`            | the step just finished, its number and name as `agents/slice-worker.md` writes them: `3. Lead-in` |
| `<one line>`        | what that step did or found, in one line, with no line break      |

The four are separated by ` | `, in that order, one report per line.
Append; never overwrite, and never read the channel back:

``` bash
printf '%s | %s | %s | %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "acme/app#101" "3. Lead-in" "The refresh path already has a seam: the token store." \
  >> "<PROGRESS>"
```

**What it never carries**: an estimate, a percentage, a count of what is
left, a phase, a time to completion. The worker reports what it has
done, never a fraction of what remains (yngboard R14.2); the board shows
the last thing it actually said and how long ago it said it, and nothing
in between (yngboard R14.6).

**It never replaces the completion report.** An interim report sets no
state, writes no run-log line, closes nothing and ends nothing: the
dispatcher logs it and the board renders it, and the slice is still
handed off by the completion report above. One the dispatcher cannot
read is logged as received and nothing is built from it — a malformed
interim report cannot fail the slice (yngboard R14.4).

With `PROGRESS: none`, or a prompt carrying no `PROGRESS:` field at all,
there is nowhere to send: the worker sends none and works as before.
