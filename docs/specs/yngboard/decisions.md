# YNG Board: Decisions

Dated log of options refused, one line of why each.

- **2026-11-25** Refused: keeping the hand-back page's scope — only what
  waits on a person. It cannot answer "where has everything got to",
  which is the question actually asked in a workspace. → context
- **2026-11-25** Refused: a second page beside the hand-back page. Two
  pages about one run, each half an answer, and both to keep in step.
- **2026-11-25** Refused: writing the board once per run. Writing and
  opening are separate acts; only opening was ever the problem, and a
  once-written page is stale the moment the next slice reports.
- **2026-11-25** Refused: restating the write rule in plan.md,
  dispatch.md, track.md, merge.md and scoped.md. Five places to forget
  it; the run log already lists every moment the run learns something.
- **2026-11-25** Refused: logging the board write as a run-log event. A
  rule that fires on every line must not write a line, and a derived
  file is not a change to issue state.
- **2026-11-25** Refused: a ranked attention list kept beside the table.
  Two renderings of overlapping data; the ranking survives as the sort
  order, which is where it was always doing its work.
- **2026-11-25** Refused: a new vocabulary for the attention column. The
  six shipped kinds each already attach to one slice, and renaming them
  would orphan the payload, the template and nine closed slices.
- **2026-11-25** Refused: a progress bar, a percentage or a phase on an
  in-flight slice. The worker sends no interim report, so every one of
  them would be invented. → context
- **2026-11-25** Refused: making the worker report progress as part of
  this feature. It changes the report format and the worker's contract;
  it gets its own issue.
- **2026-11-25** Refused: an elapsed figure without the absolute
  instant. An age alone cannot say when the data was true.
- **2026-11-25** Refused: reading ynghandback R3.4 to forbid arithmetic.
  It was written to keep ranking out of JavaScript; deriving an elapsed
  figure from a baked instant decides nothing.
- **2026-11-25** Refused: renaming the config key outright. The
  template leaves an unknown key in place "with a note that the
  orchestrator ignores it", so someone who set `write` or `no` would
  silently get the default back.
- **2026-11-25** Refused: migrating `handback-page` with the installer.
  Installer work that only helps people who reinstall; an alias read at
  config time helps everyone and rewrites nothing.
- **2026-11-25** Refused: keeping `open` as the default. With
  open-at-first-write it raises a window near the start of every run,
  which is the noise the feature exists to remove.
- **2026-11-25** Refused: keeping the project index. It answers a
  question this project does not ask, every run paid to write it, and
  the branch rule in `yngboard` covers the case it was built for.
- **2026-11-25** Refused: leaving `ynghandback.html` and
  `ynghandback-<n>.html` on disk. A file nothing updates is worse than
  one that is current or absent — the reasoning that deleted the index.
- **2026-11-25** Refused: `yngv <path>` as the only way in. The feature
  is named for something to type; a long path is no better than typing
  "status".
- **2026-11-25** Refused: a `yngboard` that regenerates a board. That
  is what ynghandback R13 refused and still refuses: the provider reads
  would exist twice and double every future provider change.
- **2026-11-25** Refused: a positional verb on `yngorch`. It is
  flags-only; `yngboard` is its own script, as `yngv` is.
- **2026-11-25** Refused: `yngboard` opening a stale board from another
  Epic when none exists for this branch. It says so and names
  `/yngorchestrator <n>`.
- **2026-11-25** Refused: `yngstatus` as the name. "Status" means four
  things here, and the column heading ban exists for that reason.
- **2026-11-25** Refused: renaming `docs/specs/ynghandback/`. It would
  falsify the `[1.15.0]` entry and the nine closed slices citing it.
- **2026-11-25** Refused: renaming the branch, worktree or Epic #135.
  They are merged and closed; `worktree.md` takes the feature from the
  body's `Spec:` line, not from a branch name.
- **2026-11-25** Refused: a hook, a watcher or a scheduled refresh. The
  board would need the provider reads outside a run, which R9.3
  refuses; run-only is honest, because a run is the only thing that
  moves a slice. → context
- **2026-11-25** Refused: keeping `schema` at 1. `waiting[]` leaves and
  1.15.0 has shipped a payload in the field, so by ynghandback R4.6 a
  reader can hold a page carrying it.
- **2026-11-25** Refused: `dispatchedAt` as a date, like `report.at`.
  An elapsed figure needs better than a date, so the `dispatched`
  run-log line gains a time.
- **2026-11-25** Refused: 2.0.0. The alias keeps every existing config
  working; the renamed step file and deleted index are internal.
- **2026-11-25** Refused: hiding the table when nothing needs
  attention. "Where has everything got to" is the question it answers.
