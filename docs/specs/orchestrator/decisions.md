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
- **2026-10-09** Refused: reading the merge config from the working
  branch. A slice could set its own path to `auto` and merge itself;
  `origin/main` changes only through a merge a person already allowed.
- **2026-10-09** Refused: GitHub's native auto-merge. It merges on
  checks alone; `auto` here also needs a `done` report and an empty
  review record, which only the orchestrator sees.
- **2026-10-09** Refused: excluding the whole `.orchestrator/` folder
  from Git. The config beside the run log must be committed.
- **2026-10-09** Refused: committing the orchestrator, its config or its
  logs to the project. The owner wants it standalone; the project root
  beside `.bare/` already holds local files outside Git (`.shared/`).
  This supersedes reading the config from `origin/main`: a file no
  branch holds is safer than one only `main` holds.
- **2026-10-09** Refused: a user-level install (`~/.claude/`). It would
  put the worker's description in every project's sessions; per project
  keeps it where Epics run.
