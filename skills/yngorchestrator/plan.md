# Plan the slices

You split the Epic into slices, show the plan to the person, and create
the slice issues once they approve it. Planning ends at
`workflow:needs-triage`: promotion is the person's (Gate 1).

## 1. Read

Read the Epic issue, `docs/specs/<feature>/requirements.md` and
`decisions.md` on the Epic branch, and the code the spec touches. On a
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

Show the person the whole plan as one table, then the open questions:

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
person approved the change. For each new slice:

``` bash
gh issue create --title "<outcome>" --label "workflow:needs-triage" --body-file <file>
```

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

Then attach it to the Epic. The REST call takes the issue's numeric
`id`, not its number:

``` bash
id=$(gh api "repos/{owner}/{repo}/issues/<n>" --jq .id)
gh api -X POST "repos/{owner}/{repo}/issues/<epic>/sub_issues" -F sub_issue_id="$id"
```

Append `<date> #<n> planned` to the run log for each.

Done when every approved slice is an open sub-issue of the Epic
labelled `workflow:needs-triage`, and each has its run log line.

## 5. Hand to Gate 1

Tell the person, in one list, which slices are ready to promote:

- to `workflow:ready-for-agent`: the slices routed to an agent, those
  with no dependencies first;
- to `workflow:ready-for-human`: the slices routed to a person, each
  with its reason.

Promotion is theirs. Every label beyond `workflow:needs-triage` is set
by the person, so a slice reaches dispatch only through their hands.

Done when the person has the list.
