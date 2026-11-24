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
