# Find or create the branch and worktree

You find the issue's branch, bring it and its worktree to a known
state, and link the skill into a worktree you create. You arrive from
[locate.md](locate.md) holding `<root>`, `<owner>/<repo>`, the issue
`<n>`, its title, its kind and, for a slice, its parent. An Epic run
comes straight from locate.md; a slice run (R19) and a standalone run
(R20) come only after their Gate 1 check, so no branch is created for
an issue a person has not promoted.

Every command names its target by absolute path, as in locate.md: `git
--git-dir="<root>/.bare"` or `git -C <worktree>`, and `gh` with
`-R <owner>/<repo>`. The session's own folder does not matter.

The run already holds its lock (*The lock* in [SKILL.md](SKILL.md)).
When a step stops the run, tell the person the reason in one sentence,
delete the lock, and end the run. A stop before step 4 has changed
nothing; a stop after it names what was created.

| Kind       | Prefix   | Worktree              | Created from         | `epicid` |
|------------|----------|-----------------------|----------------------|----------|
| Epic       | `epic/`  | `epic-<name>`         | `origin/main`        | `<n>`    |
| slice      | `slice/` | `slice-<epic>-<name>` | the Epic branch      | the Epic's number |
| standalone | `fix/`   | `fix-<name>`          | `origin/main`        | `<n>`    |

## 1. Look up the branch

Fetch first, so `origin`'s branches are current:

``` bash
git --git-dir="<root>/.bare" fetch origin --prune
```

Then find the branch, in this order:

1. **The issue body's `Branch:` line** wins. Read the body and take the
   name from the first line that starts with `Branch:`, without
   backticks or spaces. With a name, skip 2 and 3:

   ``` bash
   gh api "repos/<owner>/<repo>/issues/<n>" --jq .body \
     | sed -n 's/^Branch:[[:space:]]*`\{0,1\}\([^`[:space:]]*\).*/\1/p' | head -n 1
   ```

2. **Local branches** matching `*/<n>-*`:

   ``` bash
   git --git-dir="<root>/.bare" for-each-ref --format='%(refname:short)' "refs/heads/*/<n>-*"
   ```

3. **`origin`'s branches**, only when no local branch matched, without
   the `origin/` prefix:

   ``` bash
   git --git-dir="<root>/.bare" for-each-ref --format='%(refname:lstrip=3)' "refs/remotes/origin/*/<n>-*"
   ```

More than one match stops the run: list the matches, and ask the
person to add a `Branch:` line to the issue naming the one to use.

The branch's prefix must fit the kind (the table above). Any other
prefix stops the run, naming the branch and the kind. No match at all
is not a stop: the branch's state is *nowhere* (step 3).

Done when you hold one `<branch>` with a fitting prefix, or know there
is none.

## 2. Find the Epic branch (a slice only)

A slice's Epic is its parent issue. Run step 1 for the parent, as an
Epic: its `Branch:` line, then `*/<parent>-*` locally, then on
`origin`, with the prefix `epic/`. The same stops apply. A parent with
no Epic branch stops the run too: an Epic run on `<parent>` creates it.

`<epic>`, used in the slice's worktree name, is the Epic worktree's
name without `epic-` (step 3 finds that worktree); with no Epic
worktree, it is the Epic branch's name after `epic/<parent>-`.

The slice starts from the local Epic branch when it exists, and from
`origin/<epic branch>` otherwise.

Done when you hold `<epic branch>`, `<epic>` and the slice's start
point.

## 3. Read the branch's state

``` bash
git --git-dir="<root>/.bare" worktree list --porcelain
```

A `branch refs/heads/<branch>` line names the branch's worktree: its
path is the `worktree` line above it.

| State                    | Test                                                        |
|--------------------------|-------------------------------------------------------------|
| local, with a worktree   | `refs/heads/<branch>` exists and the list names a worktree  |
| local, no worktree       | `refs/heads/<branch>` exists and the list names none        |
| only on `origin`         | only `refs/remotes/origin/<branch>` exists                  |
| nowhere                  | neither exists, or step 1 found no branch                   |

``` bash
git --git-dir="<root>/.bare" show-ref --verify --quiet "refs/heads/<branch>"
git --git-dir="<root>/.bare" show-ref --verify --quiet "refs/remotes/origin/<branch>"
```

Done when the branch has one of the four states.

## 4. Set it up

`<name>` is a short kebab-case form of the issue's title. For a branch
that already exists, it is the branch's name after `<prefix><n>-`, so
the worktree matches the branch. `<worktree>` is
`<root>/<directory>`, with the directory from the table above.

Before any state below creates a worktree, check the project was
installed: `<root>/.shared/` is a folder, and the `yngshared` script
for this machine is in `<root>` (`yngshared.ps1` on Windows,
`yngshared.sh` on macOS/Linux). When either is missing, stop: the
project was never installed, and `yngorch` (`scripts/yngorch.ps1` or
`scripts/yngorch.sh` from the playbook) must be run once. A
`<worktree>` folder that already exists also stops the run, naming it:
it is not this branch's worktree.

### Local, with a worktree

Compare the branch with `origin` (step 1 fetched it):

``` bash
git --git-dir="<root>/.bare" rev-list --left-right --count "<branch>...origin/<branch>"
```

| `ahead behind` | Action                                                        |
|----------------|---------------------------------------------------------------|
| `0 0`          | Nothing to do                                                 |
| `0 N`          | Behind: `git -C <worktree> merge --ff-only origin/<branch>`   |
| `N 0`          | Ahead: unpushed work; leave it, and tell the person           |
| `N M`          | Diverged: leave it, report both counts, and go on with the branch as it is |

With no `origin/<branch>`, the branch was never pushed: nothing to
compare. A fast-forward that fails (uncommitted changes in the way) is
reported, and the branch is left as it is.

### Local, no worktree

``` bash
git --git-dir="<root>/.bare" worktree add "<worktree>" <branch>
```

### Only on `origin`

Create the local branch tracking `origin`, with its worktree:

``` bash
git --git-dir="<root>/.bare" worktree add --track -b <branch> "<worktree>" origin/<branch>
```

### Nowhere

The new branch is `<prefix><n>-<name>`, or the `Branch:` line's name
when the issue has one.

- **slice**: from the Epic branch (step 2);
- **standalone**: from `origin/main`;
- **Epic**: propose the name to the person, from `origin/main`, and
  create it only once they confirm it, or with the name they give
  instead. Without a confirmation, stop.

``` bash
git --git-dir="<root>/.bare" worktree add --no-track -b <branch> "<worktree>" <start point>
```

`--no-track` keeps the new branch from tracking its start point; the
first push sets its upstream.

### Every created branch, every new worktree

A branch created above records its `epicid` (the table above): a
slice its Epic's number, an Epic and a standalone issue their own
number.

``` bash
git --git-dir="<root>/.bare" config "branch.<branch>.epicid" <epic number>
```

A worktree created above gets the skill and worker through
`yngshared`:

``` powershell
& "<root>\yngshared.ps1" -link "<worktree>"     # Windows
```

``` bash
"<root>/yngshared.sh" --link "<worktree>"       # macOS/Linux
```

Done when `git --git-dir="<root>/.bare" worktree list` shows
`<worktree>` on `<branch>`, any branch you created prints its
`epicid`, and any worktree you created holds the linked
`.claude/skills/yngorchestrator/SKILL.md`.

## 5. Check the spec (an Epic only)

The spec folder is `docs/specs/<feature>/`. Take `<feature>` from the
Epic body's `Spec:` line (`docs/specs/<feature>/requirements.md`);
without one, from the spec on the Epic branch whose header names
`Epic: #<n>`:

``` bash
git --git-dir="<root>/.bare" grep -l -E "^Epic: #<n>([^0-9]|$)" <branch> -- "docs/specs/*/requirements.md"
```

Each match prints as `<branch>:docs/specs/<feature>/requirements.md`.
More than one match, like none, leaves `<feature>` unknown.

Then check the file is on the Epic branch:

``` bash
git --git-dir="<root>/.bare" cat-file -e "<branch>:docs/specs/<feature>/requirements.md"
```

No `<feature>`, or no file, stops the run: planning (R3) has nothing
to cut. Name the Epic worktree and the path the spec belongs at. You
do not write the spec.

Done when `<epic worktree>/docs/specs/<feature>/requirements.md`
exists on the Epic branch.

## 6. Hand on

- **Epic**: go on with step 1 of [SKILL.md](SKILL.md), holding
  `<root>`, `<owner>/<repo>`, the Epic `<n>`, `<epic branch>`,
  `<epic worktree>` and the spec folder
  `<epic worktree>/docs/specs/<feature>/`;
- **slice**, **standalone**: hold `<branch>` and `<worktree>` for the
  slice run (R19) or the standalone run (R20).

Done when the run continues holding the branch and its worktree.
