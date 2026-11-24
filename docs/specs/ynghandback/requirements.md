# YNG Hand-back: Requirements

Epic: #135 · Branch: `epic/135-ynghandback`

## Purpose

Step 5 of `SKILL.md` already answers the only question a person has at
the end of a run: what is waiting on me, and in what order. It answers
it as prose in the terminal, once, and the answer scrolls away.

This feature gives that same answer a second rendering: a **hand-back
page**, one self-contained HTML file per Epic, written at hand-back and
opened in the default browser. It computes nothing of its own. The run
ranks the waiting items exactly as step 5 ranks them, writes them into
the page as data, and the page renders them — so the terminal list and
the page cannot disagree.

The page lists what is waiting; it never acts. Every item links to the
provider page where the person takes the action, and the run picks that
action up on its next read. The dispatcher stays the one writer of
issue state (yngorchestrator R46, *The lock*), and Gates 1 and 2 stay a
person's act on the provider, where the label and the merge are the
record.

``` text
   /yngorchestrator <n> ──► step 5 Hand back
                                 │  one computation, ranked once
                   ┌─────────────┴─────────────┐
                   ▼                           ▼
            prose list in the          waiting[] in the payload
            terminal (unchanged)                │
                                                ▼
                               web/template.html + inlined payload
                                                │
                                                ▼
                        <root>/.yngaiplaybook/ynghandback-<n>.html
                                                │  yngv, or the browser
                                                ▼
                                            the person
```

The orchestrator's own requirements live in
[yngorchestrator](../yngorchestrator/requirements.md), the provider
seam in [yngproviders](../yngproviders/requirements.md). Where this
spec changes one of them, it names it.

## Deliverables

``` text
skills/yngorchestrator/handback.md              the step: gather, rank, render, open (R1, R5, R14)
skills/yngorchestrator/web/template.html        the shipped page: markup and style, no external asset (R3, R15)
skills/yngorchestrator/SKILL.md                 step 5 hands on to handback.md (R1, R14)
skills/yngorchestrator/track.md                 a label/report disagreement is a waiting item (R7)
skills/yngorchestrator/scoped.md                a standalone run renders its own page (R9)
templates/yngorchestratorconfig.yml             handback-page:, and "hand-back page" in Words used below (R12, R16)
scripts/yngorch.ps1, scripts/yngorch.sh         add handback-page to an existing config on reinstall (R12.4)
INSTALL.md, README.md, guides/epic-workflow.md  section 25 subsection, the files in the tree, the setting (R17)
VERSION, CHANGELOG.md, SKILL.md metadata        1.15.0 (R18)
```

------------------------------------------------------------------------

## R1 The hand-back page

1.  A hand-back page is one HTML file, self-contained: it opens from
    `file://` with no server, no network and no installed runtime, and
    shows what is waiting on the person for one Epic or one standalone
    issue.
2.  It is a rendering of step 5 of `SKILL.md`, not a second source of
    truth. Everything it shows, the run computed for step 5.
3.  It is never the only rendering. Step 5's prose list stays exactly
    as `SKILL.md` defines it, and stays first: it is what reaches the
    person over Remote Control, which `remote-control: yes` enables by
    default and where a `file://` path is useless. The run adds one
    line naming the page's path.
4.  The page is read-only (R11). It is not an application, not a
    dashboard and not a second writer of issue state.

## R2 Where the files live

1.  Pages are written to `<root>/.yngaiplaybook/`, beside the config
    and the run logs: outside every worktree, outside Git, committed to
    no branch.

    | File                   | What it is                                   |
    |------------------------|----------------------------------------------|
    | `ynghandback.html`     | the project index: every Epic and standalone |
    | `ynghandback-<n>.html` | one Epic's or one standalone issue's page    |

    `<n>` is the run log's name (`SKILL.md`, *Run log*): the Epic's
    number for an Epic or any of its slices, the issue's own number for
    a standalone.
2.  A slice run writes its Epic's page, `ynghandback-<epic>.html`, as
    it writes its Epic's log. It never writes a page of its own.
3.  A page is overwritten whole. No history is kept: the run log is the
    history.
4.  These two names are the only paths this feature adds under
    `.yngaiplaybook/`, and it reads and writes nothing else there
    (amends yngorchestrator *The project root*, which names the config
    and `yngorchestratorruns/` as the only paths).

## R3 The template and the payload

1.  The page's markup and style are a shipped file,
    `skills/yngorchestrator/web/template.html`: static, versioned with
    the skill, reviewed by commit. The run never authors markup.
2.  The template holds one placeholder, an empty
    `<script type="application/json" id="handback-data"></script>`. The
    run's whole output is the payload (R4), substituted into that
    element.
3.  The payload is inlined, never a sibling file: a `file://` page
    cannot `fetch` a file beside it.
4.  **The template never computes anything the run computes.** It
    renders the payload's arrays in the order given. Ranking, the
    waiting list, the merge path, the label/report conflict and every
    other judgement belong to the run (R5, R7).
5.  A template whose rendering disagrees with step 5's prose list is a
    defect in the template.

## R4 The payload

1.  Schema version 1:

    ``` json
    { "schema": 1, "generated": "<UTC>", "live": true,
      "epic":   { "number": 98, "title": "...", "branch": "epic/98-...",
                  "url": "...", "spec": "docs/specs/.../" },
      "waiting":[ { "kind": "merge|promote|human|held|decision|conflict",
                    "issue": 104, "why": "...", "url": "...",
                    "blocks": [105, 106] } ],
      "slices": [ { "number": 104, "title": "...", "url": "...",
                    "label": "workflow:in-review",
                    "report": { "status": "done", "at": "<UTC>",
                                "summary": "..." },
                    "pr": { "url": "...", "state": "OPEN",
                            "checks": "passed", "mergeable": true },
                    "dependsOn": [103], "decisions": ["..."] } ],
      "runlog": ["..."], "worktrees": [ { "path": "...", "deferred": false } ] }
    ```

2.  Every key appears, in this order. An absent value is `null`, an
    absent list `[]`.
3.  `generated` is the UTC instant the run wrote the payload, in the
    same form as the lock's `started` (`%Y-%m-%dT%H:%M:%SZ`).
4.  `label` is the issue's one `workflow:*` state (yngproviders R8).
    `report.status` is the completion report's `STATUS`
    (`report.md`). `pr.checks` is the provider's rollup (`none`,
    `pending`, `passed`, `failed`). These are three different things
    and the payload keeps them apart (R16.3).
5.  `decisions` is the slice's open review record: the lines of the
    report's `REVIEW RECORD`, which are also the pull request
    description's.
6.  `schema` rises when a field changes meaning or leaves. A template
    reading a `schema` it does not know renders the waiting list and a
    line saying the page was written by a newer orchestrator.

## R5 The waiting list

1.  `waiting[]` is computed by the run, ranked, and is the page's first
    and largest section. Its order is step 5's order: the items holding
    up the most slices first, and a slice waiting on a person ahead of
    the items it holds up.
2.  Its kinds are step 5's list, one per row:

    | `kind`     | What waits on the person                                      |
    |------------|---------------------------------------------------------------|
    | `merge`    | a pull request is open for review (Gate 2)                    |
    | `held`     | an `auto` merge was held; `why` names the condition            |
    | `human`    | a slice is `workflow:ready-for-human`; `why` names the reason  |
    | `promote`  | a slice waits for `workflow:ready-for-agent` (Gate 1)          |
    | `decision` | a review record holds an open decision                        |
    | `conflict` | an issue's label and its last report disagree (R7)            |

3.  `blocks` names the slices whose `Depends on:` waits on this item,
    by number. It is `[]` when the item holds nothing up.
4.  `url` is the provider page where the person takes the action: the
    issue for `promote`, `human` and `conflict`, the pull request for
    `merge`, `held` and `decision`.
5.  An empty `waiting[]` renders as one line saying nothing is waiting,
    not as an empty section.

## R6 What an Epic's page shows

1.  Four things, and only these four, beside the waiting list: the
    Epic's **slices** with their labels, the **pull requests**, the
    **dependency edges** from each issue's `Depends on:` line, and the
    **open review decisions**. They are step 5's own inputs, so the
    page shows the same reasoning rather than a different one.
2.  The run log's events and the worktrees, deferred removals included
    (`track.md`, *Sweep deferred removals*), render in one collapsed
    *run detail* section, closed when the page opens.
3.  The spec folder is a link, never content.
4.  Nothing else is added without a requirement here. "Related items"
    is not a term this feature uses: the four things above are named
    individually, so a fifth cannot arrive unnamed (R16.2).

## R7 When a label and a report disagree

1.  A run that stops between a worker's report and the *set state* it
    calls for leaves a slice whose `workflow:*` label and whose last
    report in the run log describe different things.
2.  The **label wins**: it is the provider's record and the gate's
    audit trail, and the only thing that can be authoritative.
3.  The report is shown beside it as a dated note, never silently
    dropped and never silently preferred.
4.  The disagreement is itself a `conflict` row in `waiting[]` (R5.2),
    because it means a run stopped mid-write and only a person can say
    which state is right. `track.md` names the pairs that count as a
    disagreement.

## R8 The project index

1.  `ynghandback.html` lists every Epic and standalone issue that has a
    run log, one row each: its number, its title, how many items wait
    on the person, and **its own `generated` timestamp**.
2.  A run refreshes its own Epic's row with live data (R10) and leaves
    every other row as that Epic's last run left it. A run makes no
    provider call about an Epic it is not running.
3.  Each row therefore carries its own age, shown as an absolute UTC
    instant. The problem with a stale row is not that it is old, it is
    that it does not say so.
4.  A row whose `ynghandback-<n>.html` is absent renders with no counts
    and a note that no page has been written for it.

## R9 Standalone issues

1.  One template serves both kinds. A standalone run (`scoped.md`)
    writes `ynghandback-<n>.html` for its own issue, with `epic: null`
    and `slices: []`.
2.  The slice, dependency and review-decision sections **hide** when
    their arrays are empty; they never render as empty boxes.
3.  The merge path shown is `fix-to-main`, as `track.md` reads it for a
    standalone run, not `slice-to-epic`.
4.  A standalone's page is its waiting list, its pull request and its
    run detail. That is all there is to say about it, and a second
    template for one row of difference is not added.

## R10 Live data, and a provider that cannot be reached

1.  The payload is gathered from live provider operations (*list
    children*, *list prs*, *pr status*, *read issue*), with the run log
    as the narrative spine for `runlog` and for each slice's last
    report. The log records events, not current truth: a label changed
    by hand, a check gone red, a pull request someone else merged are
    in none of it.
2.  Generation makes no provider call step 5 does not already make.
3.  When any of those operations fails — a rate limit, an expired
    login, an outage — the run **writes nothing**: the existing
    `ynghandback-<n>.html` and the index are left exactly as they are,
    and the run tells the person which operation failed and that the
    page on disk is unchanged and still carries its own timestamp.
4.  A page is never written from partial live data, and never from the
    run log alone while `live` is `true`. An honestly dated page from
    yesterday beats a freshly dated page that is wrong in ways the
    person cannot see.
5.  `live` is `false` only on a page written under
    `handback-page: write` where the person asked for no provider
    contact.

## R11 The page never acts

1.  The page has no control that writes: no promote button, no merge
    button, no label control, no form, no request of any kind.
2.  Every waiting row carries a link to the provider page where the
    action is taken (R5.4). The person acts there; the run reads it on
    its next start, as it already does.
3.  This is a guardrail, not a stage. A control that wrote issue state
    would be a writer outside `yngorchestratorruns/<log>.lock`, beside
    a dispatcher that holds it, and would move Gate 1 and Gate 2 off
    the provider, where their record lives.
4.  The template contains no `fetch`, `XMLHttpRequest`, `WebSocket`,
    `form` or external request of any kind. A reviewer can check this
    by reading one shipped file.

## R12 The config setting `handback-page`

1.  A new setting in `<root>/.yngaiplaybook/yngorchestratorconfig.yml`,
    documented in the template's own form (what it decides, its values,
    its default, when it is read, who changes it):

    | Value   | What the run does at hand-back                       |
    |---------|------------------------------------------------------|
    | `open`  | writes the page and opens it in the browser (default) |
    | `write` | writes the page, opens nothing                       |
    | `no`    | writes no page                                       |

2.  Default `open`. An absent key, an empty value, or any value other
    than `write` or `no` means `open`, and never stops a run.
3.  Read at the start of every run, with the rest of the config.
4.  `yngorch` adds the setting to an existing config on reinstall as an
    **active key at its default** (`handback-page: open`), the way
    `auto-promote: no` and `remote-control: yes` are added, not
    commented out the way `agent` and `issues` are. It never changes a
    value the person set.
5.  It sits beside `launcher` and `remote-control`: the settings that
    say what a run may do on the person's own machine.

## R13 Opening a page outside a run

1.  A page is opened outside a run by `yngv`, which is already on the
    person's PATH and already opens HTML in the default browser:

    ``` text
    yngv <root>/.yngaiplaybook/ynghandback.html
    ```

2.  No new command, flag or subcommand is added to `yngorch`. `yngorch`
    is flags-only, with no positional verb in its grammar, and this
    feature does not introduce the first one.
3.  Nothing outside a run regenerates a page or calls the provider. The
    provider operations exist once, as `providers/<provider>.md` for
    the agent (yngproviders R7); a second implementation in PowerShell
    and shell would double every future provider change.
4.  A page too old to trust is refreshed by starting a run, which is
    the only context that already holds the data.
5.  `INSTALL.md` and the guide name the `yngv` line, so the person
    never has to work the path out.

## R14 When a page is written

1.  Once per run, in step 5 of `SKILL.md`, at the hand-back: the moment
    the run ends and attention returns to the person. Step 5 hands on
    to `handback.md`.
2.  Not on each tracked event. An Epic of eight slices would open eight
    browser windows.
3.  A standalone or slice run writes at its own hand-back
    (`scoped.md`), to its Epic's page (R2.2).
4.  A run that stops with a reason before step 5 writes no page: the
    page says what is waiting at a hand-back, and there was none.
5.  The write happens before the lock is deleted, and is logged as one
    run-log line in the format `SKILL.md` defines, event
    `handback page written` or `handback page skipped <reason>`.

## R15 How the page must render

1.  From `file://`, with no network: no CDN script, no web font, no
    external stylesheet, no remote image. Every asset is inline.
2.  Theme-aware, light and dark, from `prefers-color-scheme`, with
    both palettes defined; the page paints its own background.
3.  Readable at phone width (~400px) as well as on a desktop: the
    waiting list is the first thing on the page at every width, and the
    body never scrolls sideways. A wide table scrolls inside its own
    container.
4.  No bare word "status" as a label or column heading anywhere
    (R16.3). A column is *state*, *report* or *checks*.
5.  Every number that names an issue or a pull request is a link to it.

## R16 Vocabulary

1.  **Hand-back page** is the term, in the skill, the guide and the
    config. It is named for the step it renders, which keeps its scope
    self-policing: what is not waiting on a person is not on the page.
    It is added to the "Words used below" block of
    `templates/yngorchestratorconfig.yml`, beside Epic, slice, plan,
    Gate 1 and Gate 2.
2.  **"Related items" is not used.** R6.1 names the four things
    individually. An umbrella term invites a fifth thing to arrive
    without a requirement.
3.  **The bare word "status" is not used** in the page, the payload or
    the step file. It already means four things here: an issue's
    `workflow:*` label, a completion report's `STATUS`, a run-log
    event, and a pull request's checks. Each is named by what it is
    (R4.4, R15.4).
4.  No root `GLOSSARY.md` is added. Definitions live where this repo
    already keeps them: numbered requirements in
    `docs/specs/<feature>/` and the config template's "Words used
    below". A third home is a third place for a term to go stale.

## R17 Documentation

1.  `guides/epic-workflow.md`: a subsection of **section 25**, *Running
    the Dispatcher as the YNG Orchestrator*. Not a new section 26: the
    page is dispatcher behaviour, and the config template cites section
    25 by number as the dispatcher's normative home, a reference a
    split would leave incomplete.
2.  `README.md`: `ynghandback.html` and `ynghandback-<n>.html` in the
    `.yngaiplaybook/` tree, and the `yngv` line (R13.1).
3.  `INSTALL.md`: `handback-page` among the config's settings, with its
    three values, and how to open a page outside a run.
4.  `templates/yngaiplaybookreadme.md`: a line for `handback-page`,
    beside the lines for the other settings.
5.  Every place that says what a run leaves the person says the page is
    an addition to step 5's list, never a replacement (R1.3).

## R18 Version

1.  A feature, so a minor bump: `VERSION` and `SKILL.md`'s
    `metadata.version` to **1.15.0**.
2.  A `## [1.15.0]` entry in `CHANGELOG.md`, naming the page, the
    `handback-page` setting and the `yngv` line.
3.  `decisions.md` beside this file carries the options refused.
