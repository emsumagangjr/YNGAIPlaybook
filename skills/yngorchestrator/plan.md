# Plan the slices

You split the Epic into slices, show the plan to the person, and create
the slice issues once they approve it. Promotion is the person's
(Gate 1), and `<auto-promote>` (step 3 of [locate.md](locate.md))
says when they give it:

| `<auto-promote>` | The person promotes                  | Planning ends at                                   |
|------------------|--------------------------------------|----------------------------------------------------|
| `no`             | each slice, by its label, after planning | `workflow:needs-triage`                        |
| `yes`            | the agent slices, by approving the plan (R34) | agent slices at `workflow:ready-for-agent`, human slices at `workflow:ready-for-human`, and dispatch in the same run |

Plan approval never promotes a slice routed to a person (R35).

## 1. Read

Read the Epic issue, `<epic worktree>/docs/specs/<feature>/requirements.md`
and `decisions.md` beside it, and the code the spec touches. On a
re-plan, also read the Epic's existing slice issues and the run log.

Done when every requirement section (`Rn`) is either covered by an
existing slice or listed for a new one.

## 2. Cut

Propose slices. Each one is a vertical cut that a worker can finish and
a person can review on its own, and each one has:

- **Title**: the outcome, not the step. "Users can sign in with a
  Microsoft account", not "Add `OAuthService`". The title survives a
  rebuild of the code.
- **Acceptance criteria**: checkable statements for this slice only.
  The spec stays in `docs/specs/`; the issue links to it.
- **Spec section**: the one `Rn` it implements. A slice with no section
  is a gap in the spec: list it in the plan as a question for the
  person.
- **Depends on**: the slices whose code it needs merged into the Epic
  branch first. A slice with none can run in parallel with the others.
- **Files**: the files it creates or edits. Two slices running in
  parallel that edit one file will conflict at merge; recut so each
  slice owns its files, or make one depend on the other. Note every
  overlap that remains.
- **Lead-in**: only when it differs from the default (a bug defaults to
  *diagnose*, a refactor to *design the seam*, everything else to
  *none*).
- **Gate 1 route**: `ready-for-human` when the slice touches any of the
  guide's *Never promoted to `ready-for-agent`* list (a schema change to
  anything in production, authentication or authorisation, a step only
  a person can perform) or when you are unsure; give the reason in a
  few words. Unsure means human. Otherwise `ready-for-agent`.

Done when every slice has every field, every dependency points at a
slice in the plan or an existing issue, and every file overlap between
slices that can run in parallel is noted.

## 3. Present

Show the person the whole plan as one table, then the open questions.
With `<auto-promote>` `yes`, put this line above the table, so the
person knows what their approval does:

``` text
Approving this plan promotes the slices routed to an agent: `auto-promote: yes`.
```

With `no`, the table has no such line.

``` text
| #  | Slice (outcome)                     | Spec | Depends on | Files              | Lead-in  | Route          |
|----|-------------------------------------|------|------------|--------------------|----------|----------------|
| S1 | Users can sign in with Microsoft    | R2   | none       | auth/oauth.py      | none     | human: auth    |
| S2 | Signed-in users see their profile   | R3   | S1         | profile/view.py    | none     | agent          |
```

Below the table, list each slice's acceptance criteria, the file
overlaps, and any spec gaps. Wait for the person's answer; apply their
changes and show the table again until they approve it.

Done when the person has approved the plan in so many words.

## 4. Create

Create the issues in dependency order, so each `Depends on` can name a
real issue number. On a re-plan, create only the new slices; an
existing issue keeps its labels, and its body changes only where the
person approved the change. For each new slice, `<label>` comes from
`<auto-promote>` and the slice's route:

| `<auto-promote>` | Route | `<label>`                  |
|------------------|-------|----------------------------|
| `no`             | any   | `workflow:needs-triage`    |
| `yes`            | agent | `workflow:ready-for-agent` |
| `yes`            | human | `workflow:ready-for-human` |

``` bash
gh issue create -R <issues repo> --title "<outcome>" --label "<label>" --body-file <file>
```

A slice routed to a person is never created `workflow:ready-for-agent`,
whatever the config says: plan approval cannot override the guide's
*Never promoted to `ready-for-agent`* list (R35). On a re-plan, only
the new slices the person approved get a promoting label; an existing
slice keeps its labels (R34.4).

The body, with the optional lines only when they apply:

``` text
Part of #<epic>. Spec: `docs/specs/<feature>/requirements.md`, section **<Rn> <name>**.

## Acceptance criteria

- [ ] <criterion>

Depends on: #<n>, #<n>
Lead-in: diagnose | design the seam
Route: workflow:ready-for-human — <reason>
Shares files with: #<n> (<path>)
```

A slice issue lives in the issues repo beside its Epic, so the short
`#<n>` references in its body name the issues repo's issues.

Then attach it to the Epic. The REST call takes the issue's numeric
`id`, not its number:

``` bash
id=$(gh api "repos/<issues repo>/issues/<n>" --jq .id)
gh api -X POST "repos/<issues repo>/issues/<epic>/sub_issues" -F sub_issue_id="$id"
```

Append `<date> #<n> planned` to the run log for each.

With `<auto-promote>` `yes`, record each slice created
`workflow:ready-for-agent` as promoted by plan approval (R36.1), once
it is attached to the Epic. Comment on it:

``` bash
gh issue comment <n> -R <issues repo> --body "Promoted by plan approval (auto-promote: yes), <date>.
Plan approved by the person in the orchestrator session."
```

and append `<date> #<n> promoted by plan approval` to the run log.
That line is what step 1 of [dispatch.md](dispatch.md) checks, so
write it only for a slice the person approved in this plan, created
`workflow:ready-for-agent` by this run and attached to this Epic. A
slice routed to a person gets neither.

Done when every approved slice is an open sub-issue of the Epic
labelled `<label>`, each has its `planned` line and, with `yes`, each
agent slice has its comment and its `promoted by plan approval` line.

## 5. Hand to Gate 1

With `<auto-promote>` `yes`, the person's approval was Gate 1 for the
agent slices. Tell them, in one list, which slices were promoted by it
and which wait for a person (`workflow:ready-for-human`), each with
its reason and the slices whose `Depends on:` waits on it. Then go
straight on to step 3 of [SKILL.md](SKILL.md) in this run: no second
invocation is needed (R34.3).

Done, with `yes`, when the person has the list and the run has gone on
to dispatch.

With `no`, tell the person, in one list, which slices are ready to
promote:

- to `workflow:ready-for-agent`: the slices routed to an agent, those
  with no dependencies first;
- to `workflow:ready-for-human`: the slices routed to a person, each
  with its reason.

Promotion is theirs. Every label beyond `workflow:needs-triage` is set
by the person, so a slice reaches dispatch only through their hands.

Done, with `no`, when the person has the list.
