# Orchestrator: Decisions

Dated log of options refused, one line of why each.

- **2026-10-08** Refused: Claude Code's built-in subagent worktree
  isolation. It creates worktrees outside the `.bare/` layout with its
  own names; the orchestrator creates each slice worktree itself and
  points the worker at its path.
- **2026-10-08** Refused: the orchestrator as a subagent. Subagents
  cannot start subagents, so the orchestrator runs in the main session.
- **2026-10-08** Refused: workers reporting by writing to a shared
  status file. A worker's final message already returns to the
  orchestrator; a file adds a second source of truth and write races.
- **2026-10-08** Refused: workers updating issue labels. The guide makes
  the dispatcher the only writer of issue state.
- **2026-10-08** Refused: scoped labels (`workflow::`). GitHub has none;
  plain labels prefixed `workflow:` carry the same states.
- **2026-10-08** Refused: a model-invoked `orchestrate` skill. Running an
  Epic is a person's call; a description would sit in every session's
  context to enable something nobody wants triggered implicitly.
- **2026-10-08** Refused: one `SKILL.md` holding every step. Planning,
  dispatch and tracking each run on their own branch of the loop; split
  files keep the entry short and let slices change them independently.
