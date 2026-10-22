# YNG Providers: Decisions

Dated log of options refused, one line of why each.

- **2026-10-23** Refused: any provider, with commands worked out at
  runtime. Gate 1's provenance check cannot rest on improvised commands.
  → context
- **2026-10-23** Refused: Azure DevOps in the first set. Its boards and
  provenance map least cleanly; it is planned, behind the same seam.
- **2026-10-23** Refused: plain `git` with raw REST for every provider.
  `gh` and `glab` are what the person already has logged in; REST only
  where no CLI exists (Bitbucket).
- **2026-10-23** Refused: Bitbucket Data Center. Its REST API is a
  separate backend and Atlassian is winding it down; planned.
- **2026-10-23** Refused: Jira as Bitbucket's tracker for now. A fourth
  backend; Bitbucket issues carry every playbook concept; planned.
- **2026-10-23** Refused: Bitbucket code with issues forced onto GitHub
  or GitLab. It makes the third provider half a provider.
- **2026-10-23** Refused: Bitbucket credentials from git's credential
  manager or a file. Environment variables are the simplest to check
  and document in both shells, and stay out of the project.
- **2026-10-23** Refused: GitLab scoped labels (`workflow::`). Premium
  only; one set of names across providers keeps the docs neutral.
- **2026-10-23** Refused: GitLab child Tasks or Premium epics for
  slices. Tasks are another work-item type `glab` handles poorly; epics
  need Premium. A body line works on every tier.
- **2026-10-23** Refused: a `yngprovider` wrapper script. Two scripts
  per provider to keep in step; one Markdown file per provider matches
  the skill's one-file-per-step layout.
- **2026-10-23** Refused: a provider command table in every step file.
  Each step would grow with each provider.
- **2026-10-23** Refused: an issues repo on a different provider. Two
  providers in one run, and closing keywords stop working; planned.
- **2026-10-23** Refused: making `provider:` required. Every existing
  install would stop until reinstalled; absent means `github`.
- **2026-10-23** Refused: new `Rn` sections in the yngorchestrator
  spec. The feature spans installer and orchestrator, and later
  providers need one place to follow.
- **2026-10-23** Refused: trusting the command references without a
  live run. Provenance refusal is a safety rule; each provider proves
  it in a sandbox. → context
- **2026-10-23** Refused: a supported-provider list written into
  `locate.md`. The provider files present are the list, so adding a
  provider stays one file (R7).
- **2026-10-23** Refused: `gh pr checks` for *pr status*. Its exit
  status mixes "no checks" with "failed"; `statusCheckRollup` gives
  `none`, `pending`, `passed` and `failed` apart.
- **2026-10-23** Refused: `gh`'s own default host. Every GitHub call
  sets `GH_HOST=<host>`, so a GitHub Enterprise run never reaches
  github.com.
- **2026-10-23** Refused: parsing Bitbucket's JSON without `jq`. `sed` on
  JSON breaks on the first nested field; `jq` is one small binary.
- **2026-10-23** Refused: setting a Bitbucket component with `PUT` on the
  issue. `POST .../changes` is the call documented to make a change
  record, and provenance reads only change records.
- **2026-10-23** Refused: creating a Bitbucket issue with its component
  set. Creation makes no change record, so provenance would list no
  application, and plan approval needs exactly one.
- **2026-10-23** Refused: pushing a new Bitbucket repository's README with
  git. It needs a git credential beside the API token; `POST .../src`
  commits with the token alone.
- **2026-10-23** Refused: finding Bitbucket children with a BBQL filter on
  the body. `~` is a substring match (`#1` finds `#12`); `jq` matches the
  whole `Parent:` line.
