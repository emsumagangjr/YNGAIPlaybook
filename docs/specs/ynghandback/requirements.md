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
skills/yngorchestrator/handback.md              the step: gather, rank, render, open (R1, R5, R8, R14)
skills/yngorchestrator/web/template.html        the shipped page: markup and style, no external asset (R3, R15)
skills/yngorchestrator/web/index.html           the shipped project index: one row per run log (R8)
skills/yngorchestrator/SKILL.md                 step 5 hands on to handback.md (R1, R14)
skills/yngorchestrator/track.md                 a label/report disagreement is a waiting item (R7)
skills/yngorchestrator/scoped.md                a standalone or slice run hands on to handback.md (R9, R14.3)
templates/yngorchestratorconfig.yml             handback-page:, and "hand-back page" in Words used below (R12, R16)
skills/yngorchestrator/locate.md                step 3 resolves <handback-page> with the rest of the config (R12.3)
scripts/yngv.ps1, scripts/yngv.sh               .html and .htm open in the default browser (R13.6-R13.9)
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
    element. The file carries no second copy of that tag, in a comment
    or anywhere else, so a substitution cannot match the wrong one.
3.  The payload is inlined, never a sibling file: a `file://` page
    cannot `fetch` a file beside it. Inlined, it is markup until the
    parser meets `</script`, so **the run writes every `<` in the
    payload as `\u003c`**, which JSON reads back as the same text and
    no parser can read as a tag. The strings come from issue titles,
    report summaries, review records and run-log lines — this spec's
    own R3.2 among them — so one of them holding `</script>` is
    ordinary, not an attack. Unescaped, it ends the element early and
    leaves the page with no payload to render.
4.  **The template never computes anything the run computes.** It
    renders the payload's arrays in the order given. Ranking, the
    waiting list, the merge path, the label/report conflict and every
    other judgement belong to the run (R5, R7). The merge path is the
    payload's own `mergePath` (R4.7), read as written: it was prose in
    a waiting item's `why` only while no field carried it.
5.  A template whose rendering disagrees with step 5's prose list is a
    defect in the template.
6.  The template derives no address. A number it prints is a link when
    the payload gives an address for it — the `url` of `issue` where the
    number is the page's own issue (R4.9), the `url` of the slice in
    `slices[]` that carries that number, or the waiting item's own
    `url` where R5.4 makes that the issue (`promote`, `human`,
    `conflict`) — and plain text when the payload gives none (R15.5).
    An item's `url` is never lent to a number R5.4 says it does not
    name: a pull request standing in for an issue is worse than no
    link. Addresses the run writes are addresses the page can open,
    `epic.spec` included: the page sits in `.yngaiplaybook/`, so a
    path relative to the repository root resolves to nothing there.
7.  Every value from the payload is put on the page as text, never as
    markup, and an address that could run on click is printed instead
    of linked. With the payload escaped as R3.3 says, nothing a
    provider or a worker wrote can execute on this page.
8.  The shipped file is openable on its own. With the placeholder still
    empty, or holding something that is not a payload, the page says so
    in one line and renders nothing else.

## R4 The payload

1.  Schema version 1:

    ``` json
    { "schema": 1, "generated": "<UTC>", "live": true,
      "mergePath": "slice-to-epic",
      "issue":  { "number": 98, "title": "...", "url": "...",
                  "branch": "epic/98-..." },
      "epic":   { "number": 98, "title": "...", "branch": "epic/98-...",
                  "url": "...",
                  "spec": "../<worktree>/docs/specs/<feature>/" },
      "waiting":[ { "kind": "merge|promote|human|held|decision|conflict",
                    "issue": 104, "why": "...", "url": "...",
                    "blocks": [105, 106] } ],
      "slices": [ { "number": 104, "title": "...", "url": "...",
                    "label": "workflow:in-review",
                    "report": { "outcome": "done", "at": "<UTC>",
                                "summary": "..." },
                    "pr": { "number": 131, "url": "...", "state": "OPEN",
                            "checks": "passed", "mergeable": true },
                    "dependsOn": [103], "decisions": ["..."] } ],
      "runlog": ["..."], "worktrees": [ { "path": "...", "deferred": false } ] }
    ```

2.  Every key appears, in this order. An absent value is `null`, an
    absent list `[]`.
3.  `generated` is the UTC instant the run wrote the payload, in the
    same form as the lock's `started` (`%Y-%m-%dT%H:%M:%SZ`).
4.  `label` is the issue's one `workflow:*` state (yngproviders R8).
    `report.outcome` is the completion report's `STATUS`
    (`report.md`). `pr.checks` is the provider's rollup (`none`,
    `pending`, `passed`, `failed`). These are three different things
    and the payload keeps them apart (R16.3). The payload's key is
    `outcome`, not `status`: the bare word already means four things
    here, and a payload key naming one of them is that collision
    (R16.3). The report's own field in `report.md` keeps its name.
5.  `decisions` is the slice's open review record: the lines of the
    report's `REVIEW RECORD`, which are also the pull request
    description's.
6.  `schema` rises when a field changes meaning or leaves. A template
    reading a `schema` it does not know renders the waiting list and a
    line saying the page was written by a newer orchestrator.
7.  `mergePath` is the run's merge path, as `merge.md` and `track.md`
    name it: `slice-to-epic` for an Epic run and its slices,
    `fix-to-main` for a standalone (R9.3). `pr.number` is the pull
    request's number in the code repo, beside its address. Both arrived
    after the template shipped, which until then had to work each one
    out — the merge path from a waiting item's `why`, the number from
    the last run of digits in the address — which R3.4 forbids.
    **`schema` stays `1`**: R4.6 raises it when a field changes
    meaning or leaves, and these two only arrive. A template written
    for schema 1 before them renders exactly as it did.
8.  `epic.spec` is an address the page can open from
    `<root>/.yngaiplaybook/`, where the page sits (R3.6): the spec
    folder in the Epic's worktree, written relative to that folder, not
    the repository-relative `docs/specs/<feature>/` the issue and the
    plan name, which resolves to nothing from there.
9.  `issue` is the issue the page was written for — its `number`,
    `title`, `url` and `branch` — filled for an Epic and a standalone
    alike. It is where the page takes its heading and its identity
    from, and the address the payload gives for its own number (R3.6,
    R15.5). `epic` stays Epic-only, carrying what only an Epic has:
    its branch, its spec folder and its slice set. So a standalone's
    page carries `epic: null` (R9.1) and still names its own issue,
    which is what R9.4 and R15.5 ask of it. **`schema` stays `1`**:
    `issue` arrives, and `report`'s own key becomes `outcome` (R4.4),
    before any page has been written in the field, so nothing in the
    field changes meaning for a reader (R4.6).

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

    Every other row is read from that Epic's own
    `ynghandback-<n>.html`: the **payload inlined in it** (R3.2),
    parsed as JSON, which gives the row's `generated`, the number of
    items in its `waiting[]`, and the title its payload carries. The
    run wrote that payload itself, into the one element R3.2 names,
    and R3.3 left no `<` anywhere inside it, so the lines between that
    element's tags are the payload and nothing else. **The page's
    markup is never parsed, and no HTML is ever read back as markup**
    (R3.1 holds). Its own row the run takes from the payload it has
    just built, not from the file it has just written. The address for
    a row's number the run writes from the provider file's *Issue URL*
    form, which is a form and not a call (R15.5). A row's title is
    its page's own `issue.title` (R4.9), which an Epic's page and a
    standalone's carry alike, so every row names its issue; a payload
    carrying no title leaves its row showing its number alone.
3.  Each row therefore carries its own age, shown as an absolute UTC
    instant. The problem with a stale row is not that it is old, it is
    that it does not say so. So no field of a row outlives the instant
    beside it: nothing is carried over from the index's own last
    payload, and a row the run could not read keeps none of what an
    earlier run knew (R8.4).
4.  A row whose `ynghandback-<n>.html` is absent renders with no counts
    and a note that no page has been written for it. A page whose
    payload is absent, unparseable, or of a `schema` the run does not
    know renders as that same no-counts row, with a note that its page
    could not be read: never as a guess, and never as a crash.
5.  `web/index.html` is a second shipped file beside `template.html`,
    static and versioned with the skill (R3.1), with its own empty
    `<script type="application/json" id="handback-index"></script>`
    placeholder and its own inlined payload (R3.2, R3.3). It keeps
    every rule the Epic's page keeps: no network and no request of any
    kind (R3, R11.4), no bare word "status" (R16.3), both palettes and
    a first screen that reads at phone width (R15). It is a file and
    not an index mode inside `template.html`, because the two page
    shapes share no section. Schema version 1:

    ``` json
    { "schema": 1, "generated": "<UTC>", "project": "<issues repo>",
      "runs": [ { "number": 135, "title": "...", "url": "...",
                  "page": "ynghandback-135.html", "waiting": 3,
                  "generated": "<UTC>", "note": null } ] }
    ```

    Every key appears, in this order. An absent value is `null`, an
    absent list `[]`. `schema` is the index's own number, separate from
    R4.1's and rising on its own file for the reasons R4.6 gives; an
    index page reading a `schema` it does not know says so and renders
    no rows, because every row is of that schema and no part of the
    payload is left for it to show. The payload's `generated` is the
    instant the run wrote the index; a **row's** `generated` is the
    instant that row's own page was written (R8.1), and is never
    recomputed here. `waiting` is the number of items in that page's
    `waiting[]`, and `null` where R8.4 applies; `note` is R8.4's one
    sentence, and `null` on a row that was read. `page` is the page's
    file name, which the index opens from its own folder (R3.6), and
    `url` the issue's address, so every number naming an issue is a
    link to it (R15.5). Rows are in number order, lowest first.
6.  The index is written in the same step as the Epic's page (R14.1)
    and under the same rules: whole, with no history kept (R2.3), only
    when the gather succeeded (R10.3), and only when `<handback-page>`
    is `open` or `write` (R12.1). Either both files are written or
    neither is: a page refreshed beside an index still carrying the old
    instant for it would say two different things about one run. The
    run opens the Epic's page (R14.1); the index it writes and names,
    and the person opens it with `yngv` (R13.1).

## R9 Standalone issues

1.  One template serves both kinds. A standalone run (`scoped.md`)
    writes `ynghandback-<n>.html` for its own issue, with `epic: null`
    and `slices: []`. Its `issue` is that issue (R4.9): the page's
    heading, its identity and the address for its own number come from
    there, so `epic: null` leaves nothing on the page unnamed.
2.  The sections an Epic's page builds from `slices[]` — its slices,
    its pull requests, its dependency edges and its open review
    decisions (R6.1) — **hide** when those arrays are empty; they never
    render as empty boxes.
3.  The merge path shown is `fix-to-main`, as `track.md` reads it for a
    standalone run, not `slice-to-epic`. It is the payload's
    `mergePath` (R4.7), which the run writes and the page prints.
4.  A standalone's page is its waiting list, its pull request and its
    run detail, and nothing more. Its pull request is **the waiting row
    that links it** — `merge`, `held` or `decision`, whose `url` is the
    pull request (R5.4) — and not a table of its own: the pull-requests
    table is one of the four sections an Epic's page builds from
    `slices[]` (R6.1, R9.2), and a standalone has no slices. That is
    all there is to say about it, and a second template for one row of
    difference is not added.

## R10 Live data, and a provider that cannot be reached

1.  The payload is gathered from live provider operations (*list
    children*, *list prs*, *pr status*, *read issue*), with the run log
    as the narrative spine for `runlog` and for each slice's last
    report. The log records events, not current truth: a label changed
    by hand, a check gone red, a pull request someone else merged are
    in none of it.
2.  Generation makes no provider call step 5 does not already make. A
    **slice** run writing its Epic's page (R2.2) may make the reads
    that page needs: *read issue* on the Epic, *list children*, and the
    per-slice reads of R10.1. This requirement exists so page
    generation adds no provider traffic of its own, and for a slice run
    those reads **are** the page rather than traffic on top of it;
    reading it to forbid them left R2.2 as dead text.
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
3.  Read at the start of every run, with the rest of the config, in
    step 3 of `skills/yngorchestrator/locate.md`. The run holds the
    value it read to its end; an edit counts from the next run.
4.  `yngorch` adds the setting to an existing config on reinstall as an
    **active key at its default** (`handback-page: open`), the way
    `auto-promote: no` and `remote-control: yes` are added, not
    commented out the way `agent` and `issues` are. It never changes a
    value the person set. Both installers merge settings from the
    template by its `# --- Setting: <name> ---` headers, so this needs
    no change to either script; it is verified against a config
    without the key, not assumed.
5.  It sits beside `launcher` and `remote-control`: the settings that
    say what a run may do on the person's own machine.

## R13 Opening a page outside a run

1.  A page is opened outside a run by `yngv`, which the installer
    already put on the person's PATH (yngorchestrator R13), and which
    opens an HTML file in the default browser (R13.6):

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
6.  `yngv` opens `.html` and `.htm` in the default browser, as one more
    case in the extension switch each script already has: `yngv.ps1`
    through `Start-Process` on Windows, and `open` (macOS) or
    `xdg-open` (Linux) when it runs under PowerShell 7 there;
    `yngv.sh` through the `open_default` helper it already uses for
    markdown. Where that fails or no opener exists, it says so and
    shows the file's source, the way markdown falls back to its console
    renderer.
7.  `YNGV_HTML_BROWSER` persists the default per person, as an
    environment variable rather than project config: `yngv` is a
    per-user tool on PATH, installed outside any project
    (yngorchestrator R13.5). Both scripts match the value the same way,
    with surrounding whitespace stripped and case folded first, so
    `no`, `NO`, `no ` and ` no ` all read alike. Unset, empty,
    whitespace only, or any value other than `0`, `no`, `false` or
    `off` means the browser; those values mean the console. An unknown
    value never stops the call, as with `handback-page` (R12.2).
8.  `-Raw` / `--raw` and `-Console` / `--console` win per call, over
    both the default and the variable, as they already do for markdown.
    HTML has no console renderer of its own, so each shows the file's
    own source. A missing or unreadable path fails exactly as it
    already does for markdown; no error style is added.
9.  Each script's own help names the two extensions and
    `YNGV_HTML_BROWSER`; the help is the script's header block, which
    `yngv.sh -h` and `Get-Help yngv.ps1` print.

## R14 When a page is written

1.  Once per run, in step 5 of `SKILL.md`, at the hand-back: the moment
    the run ends and attention returns to the person. Step 5 hands on
    to `handback.md`.
2.  Not on each tracked event. An Epic of eight slices would open eight
    browser windows.
3.  A standalone or slice run writes at its own hand-back, in step 8 of
    `scoped.md`: a standalone its own page, a slice its Epic's (R2.2).
4.  A run that stops with a reason before its hand-back — step 5 of
    `SKILL.md`, or step 8 of `scoped.md` (R14.3) — writes no page: the
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
