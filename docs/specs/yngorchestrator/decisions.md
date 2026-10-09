# YNG Orchestrator: Decisions

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
- **2026-10-09** Refused: renaming the role word "orchestrator" in
  every sentence. The guide's role (dispatcher, orchestrator) is
  generic; the brand belongs on the product's names: the command,
  folders, skill identity, and first mention.
- **2026-10-09** Refused: renaming `slice-worker` and the `yngorch`
  installer. The installer already carries the prefix; the worker is
  out of this Epic's scope.
- **2026-10-09** Refused: installing `yngv` into the project root beside
  `yngshared`. It is a personal tool, used from any folder; per user on
  PATH makes a bare `yngv` work as `templates/agents.md` advises.
- **2026-10-09** Refused: `yngorch.sh` appending to `~/.bashrc` or
  `~/.zshrc`. Shells differ (bash, zsh, fish) and a startup file is the
  person's; it prints the line instead.
- **2026-10-09** Refused: a user-level install to run from the project
  root. A personal skill outranks a project one of the same name, so
  every project would run the user's copy and drift from its own
  install; the root gets a `.claude/` link instead (R14).
- **2026-10-09** Refused: handing off to a new session in the target
  worktree. The skill already works by absolute path from the root;
  a hand-off breaks the one-command run.
- **2026-10-09** Refused: re-running the full `yngorch` installer for a
  new worktree. It needs the playbook's source path, unknown inside
  another project; `<root>/yngshared` is always there once installed.
- **2026-10-09** Refused: requiring an open issue with the `epic` label.
  The orchestrator works within whichever issue it is given: an Epic,
  a slice or a standalone issue.
- **2026-10-09** Refused: refusing closed issues outright. The person
  may want one reopened and resumed; the orchestrator asks.
- **2026-10-09** Refused: classifying by label only, or by tracker
  structure only. A new Epic has no sub-issues yet, and a label alone
  cannot tell a slice.
- **2026-10-09** Refused: a slice run continuing into its siblings. It
  stays within the slice named; driving the Epic is an Epic run.
- **2026-10-09** Refused: a log per invoked issue. A slice logged apart
  from its Epic leaves the Epic's log stale and risks a second
  dispatch.
- **2026-10-09** Refused: a new `issue-to-main` merge path. The
  template's `fix-to-main` already covers standalone work on `fix/*`.
