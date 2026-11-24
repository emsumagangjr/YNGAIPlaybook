# YNG Hand-back: Decisions

Dated log of options refused, one line of why each.

- **2026-11-24** Refused: a local web server on `localhost`. A runtime
  dependency, a port and a process lifecycle beside the agent instance,
  for a page whose content is a point-in-time hand-off. → context
- **2026-11-24** Refused: a published Claude Artifact. It lives outside
  the project and outside the zero-dependency posture the rest of the
  playbook keeps; a page about a local run belongs beside the local run.
- **2026-11-24** Refused: buttons that promote or merge. A control that
  wrote issue state would be a second writer outside
  `yngorchestratorruns/<log>.lock`, and would move Gate 1 and Gate 2 off
  the provider, where the label and the merge are the record. → context
- **2026-11-24** Refused: an Epic page with no project index. The
  question a person actually has spans every log, and without an index
  you must already know the number to ask it.
- **2026-11-24** Refused: one self-contained file for the whole project.
  A run on one Epic would make live calls about Epics it is not running.
- **2026-11-24** Refused: relative ages ("2 days ago") on index rows. A
  page is read long after it is written; an absolute UTC instant cannot
  mislead about when the data was true.
- **2026-11-24** Refused: the run log alone as the data. It records
  events, not current truth: a label changed by hand, a check gone red,
  a pull request someone else merged are in none of it.
- **2026-11-24** Refused: a degraded or partial page when the provider
  cannot be reached. Overwriting an honestly dated page with a freshly
  dated wrong one is unrecoverable; the run writes nothing instead.
- **2026-11-24** Refused: the orchestrator authoring the page's markup.
  The design would not exist until it was generated, would drift between
  runs, and could not be reviewed by commit.
- **2026-11-24** Refused: the payload as a file beside the page. A
  `file://` page cannot `fetch` a sibling; the payload is inlined.
- **2026-11-24** Refused: the template deriving the waiting list and its
  ranking. Step 5's logic would exist twice, as prose and as JavaScript,
  free to disagree; the run ranks once and the template renders.
- **2026-11-24** Refused: "status page", "dashboard" and "web
  interface" as the term. "Status" already means four things here, and
  the other two promise an application. "Hand-back page" names the step
  it renders, so its scope polices itself.
- **2026-11-24** Refused: "related items" as a heading. The four things
  are named individually, so a fifth cannot arrive without a
  requirement.
- **2026-11-24** Refused: the run log's events and the worktrees as main
  content. They are run detail, collapsed; the page is for what is
  waiting on a person.
- **2026-11-24** Refused: trusting a completion report over the issue's
  label. The label is the provider's record and the gate's audit trail.
- **2026-11-24** Refused: resolving a label/report disagreement
  silently. It means a run stopped mid-write, which is the one fact that
  needs the person; it is a waiting item.
- **2026-11-24** Refused: a second, cut-down template for standalone
  issues. Two templates to keep in step for one row of difference; the
  one template hides the sections that do not apply.
- **2026-11-24** Refused: `yngorch handback`. `yngorch` is flags-only
  with no positional verb, and `yngv` opens HTML in the browser from
  PATH (R13.6).
- **2026-11-24** Refused: regenerating a page outside a run. The
  provider reads would exist a second time, in PowerShell and shell,
  doubling every future provider change (yngproviders R7).
- **2026-11-24** Refused: replacing step 5's prose list. It is what
  reaches the person over Remote Control, where a `file://` path is
  useless.
- **2026-11-24** Refused: writing or opening a page on each tracked
  event. An Epic of eight slices would open eight browser windows.
- **2026-11-24** Refused: `handback-page` added to an existing config
  commented out. It has a working default, so it is added active at that
  default, as `auto-promote` and `remote-control` are.
- **2026-11-24** Refused: making `handback-page` required. Every
  existing install would stop until reinstalled; absent means `open`.
- **2026-11-24** Refused: keeping dated pages as history. The run log is
  the history; a page is overwritten whole.
- **2026-11-24** Refused: pages committed to the repository. They belong
  to no branch, like everything else in `.yngaiplaybook/`.
- **2026-11-24** Refused: a root `GLOSSARY.md`. This repo defines terms
  in numbered requirements and the config template's "Words used below";
  a third home is a third place to go stale.
- **2026-11-24** Refused: a new section 26 in the guide. The page is
  dispatcher behaviour, and the config template cites section 25 by
  number as the dispatcher's normative home.
- **2026-11-24** Refused: a new `-Browser` / `--browser` flag on `yngv`
  for HTML. `-Raw` and `-Console` already say "not the browser" per
  call; a third flag would only restate the default.
- **2026-11-24** Refused: putting `yngv`'s HTML default in the project
  config. `yngv` is installed per user, outside any project
  (yngorchestrator R13.5), and reads no config; the default is the
  environment variable `YNGV_HTML_BROWSER` (R13.7).
- **2026-11-24** Refused: converting HTML before opening it, or opening
  it through `Show-Markdown`. A hand-back page is already the finished
  document; it goes to the browser untouched.
- **2026-11-24** Refused: an index mode inside `template.html`. The two
  page shapes share no section, so one file would be two pages behind a
  branch; the index is its own shipped file beside it.
- **2026-11-24** Refused: reading a row's data back out of a page's
  markup. A row comes from the JSON payload the run itself inlined in
  that page, parsed as JSON; no HTML is ever read back as markup.
- **2026-11-24** Refused: carrying a row's title or counts over from the
  index's own last payload. A field would then outlive the instant
  printed beside it, which is the one thing a row must not do.
- **2026-11-24** Refused: writing the Epic's page when the index cannot
  be written, or the other way about. A fresh page beside a row still
  carrying the old instant for it says two things about one run.
- **2026-11-24** Refused: `sed 's/</\u003c/g'` for the payload's escape.
  GNU `sed` reads `\u` as "uppercase the next character" and `gawk` 5.3
  reads `\u003c` as `<`, so each silently wrote a payload that parsed
  and was wrong; the backslash now comes from its character code.
- **2026-11-24** Refused: the run opening the browser itself. The step
  would carry a per-platform opener of its own, beside the one `yngv`
  already has on the person's PATH, and no per-person default to go
  with it; `yngv` gains the `.html` case and `YNGV_HTML_BROWSER`
  persists the choice (R13.6, R13.7).
- **2026-11-24** Refused: matching `YNGV_HTML_BROWSER` as written. A
  value with a trailing space, or `NO` in capitals, would have read as
  "the browser", the opposite of what was set; both scripts strip
  surrounding whitespace and fold case first, in the same way, so the
  two can never answer differently (R13.7).
- **2026-11-24** Refused: a second `yngv` version bump for the
  whitespace fix. 1.2.0 is unreleased and ships with this release, and
  the `.ps1` and the `.sh` move together; a bump for a fix to a change
  no one has yet would only put the two headers out of step.
- **2026-11-24** Refused: withholding step 5's prose list when the
  gather fails. It was printed before this step, from data the run
  already held, so the person keeps the list and is told which
  operation failed beside it; only the page is not written (R10.3).
- **2026-11-24** Refused: reading R10.2 as forbidding a slice run the
  reads its Epic's page needs. R2.2 makes that run the writer of that
  page, so the stricter reading left R2.2 as dead text; the
  requirement exists to stop page generation adding traffic of its
  own, and for a slice run those reads are the page.
- **2026-11-24** Refused: a page taking its heading and its identity
  from `epic`. A standalone's page carries `epic: null`, which left it
  unable to name its own issue or give an address for its own number;
  the payload gains a top-level `issue` that both kinds fill (R4.9).
- **2026-11-24** Refused: `report.status` as the payload's key. The
  bare word already means four things here, and a key naming one of
  them is that collision; the key is `report.outcome`, while the
  completion report's own field keeps its name (R4.4).
- **2026-11-24** Refused: `report.at` as a UTC instant. A run-log line
  carries a date and nothing finer, so an instant there would be
  precision the run does not have; the field is that line's own date,
  and R4.1's example was corrected rather than the data invented.
- **2026-11-24** Refused: the template working the merge path out of a
  waiting row's `why`, and a pull request's number out of the last
  digits of its address. Both are things the run knows and the page
  was re-deriving; they are now the payload's `mergePath` and
  `pr.number`, read as written (R3.4, R4.7).
- **2026-11-24** Refused: raising the payload's `schema` for the fields
  settled mid-Epic (`issue`, `mergePath`, `pr.number`, `outcome`). No
  page had been written in the field, and R4.6 raises it when a field
  changes meaning or leaves, not when one arrives.
- **2026-11-24** Refused: a pull-requests table on a standalone's page.
  That table is one of the four sections an Epic's page builds from
  `slices[]`, and a standalone has no slices; its pull request is the
  waiting row that links it, and that is all there is to say (R9.4).
