# YNG Board Command: Decisions

Dated log of options refused, one line of why each.

- **2026-11-26** Refused: teaching `yngboard` to refresh a board. It is
  a shell script, so the provider reads would exist a second time in
  PowerShell and shell — exactly what yngboard R9.3 refuses. → context
- **2026-11-26** Refused: a separate `/yngboard` skill. Another file,
  another install step, and it would duplicate locate.md steps 1 to 4
  to find the root, the config and the provider.
- **2026-11-26** Refused: a positional verb on `yngorch`. It is
  flags-only, and `board` belongs to the agent's command, not the
  installer's.
- **2026-11-26** Refused: `board` launching the run's own instance. A
  Herdr space to look at a page; and R46 is about runs, which this is
  not.
- **2026-11-26** Refused: `board` taking the lock. It writes no issue
  state, so there is nothing to serialise.
- **2026-11-26** Refused: logging a `board` line. A board write is not
  an event, and the line would fire the rule that wrote the board.
- **2026-11-26** Refused: `board` draining a progress channel to
  freshen a row. The dispatcher is the channel's only reader; a second
  one races its `logged` count and loses interim reports for good.
- **2026-11-26** Refused: `board` writing while a run holds the lock.
  Two writers on one file, under a dispatcher already rewriting it.
- **2026-11-26** Refused: `board` falling through to worktree.md for a
  merged Epic. It would create a branch and a worktree for a page.
- **2026-11-26** Refused: `board` running locate.md step 6. It offers
  to reopen a closed issue — a write, from a command that makes none.
- **2026-11-26** Refused: refusing a closed issue's board. #135 and
  #155 are closed and both worth reading; it is the common case.
- **2026-11-26** Refused: refusing an issue with no run log. The moment
  before a run starts is the command's best case, not an error.
- **2026-11-26** Refused: `board` honouring `run-board: no`. That
  setting is about what a run does unasked; typing the command is
  asking. → context
- **2026-11-26** Refused: the board file written inside the worktree.
  It is inside Git, so it would be committable and show in slice
  diffs, and `track.md` deletes the worktree when the slices merge.
- **2026-11-26** Refused: a slice worktree opening its Epic's board.
  Working one slice, the Epic's other rows are other problems, and the
  interim-report sequence is what a slice board is for.
- **2026-11-26** Refused: a second template for a slice board. The
  shipped one already renders a single issue with `slices: []`, which
  is how a standalone's board works.
- **2026-11-26** Refused: naming boards by run log. A slice's log is
  its Epic's, so it cannot tell the two boards apart.
- **2026-11-26** Refused: the dispatcher writing each slice's board as
  well as its own. Five writes an event with four live workers,
  rebuilding payloads nobody is looking at.
- **2026-11-26** Refused: a slice run writing only its own board. It
  appends to the Epic's log, so the Epic's board would stall silently
  whenever work goes through slice runs.
- **2026-11-26** Refused: one board write per appended line. R14's
  interim reports made multi-line batches the common case, and a drain
  of four cost four full payload rebuilds for one slice's list.
  → context
- **2026-11-26** Refused: skipping a write when the payload is
  byte-identical. It costs a read to find out, and after a drain the
  payload has genuinely changed.
- **2026-11-26** Refused: "workspace" as the word. It has meant the
  Herdr space, the git worktree and the project in one conversation;
  the unit a person stands in is a worktree.
- **2026-11-26** Refused: reading yngboard R1.6 to forbid this command.
  R1.6 refused hooks, watchers and schedules — refreshes that happen
  without the person. One they type is not one of those.
