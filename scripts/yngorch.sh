#!/usr/bin/env bash
# yngorch.sh — installs or upgrades the YNGAIPlaybook orchestrator in a
# project, without committing anything to it.
#
# Author:  Emeterio M. Sumagang Jr.
# Company: YNGSoftware (www.yngsoftware.com)
#
# Works with any project laid out as a bare repository with one folder per
# worktree (the "Bare Repository + Git Worktrees" pattern). Everything goes
# into the project root, beside .bare/, outside every worktree and outside Git:
#
#   <project-root>/
#   |-- .bare/info/exclude          + hides the links in every worktree
#   |-- .shared/.claude/
#   |   |-- skills/yngorchestrator/ the orchestrator skill
#   |   `-- agents/slice-worker.md  the worker it dispatches
#   |-- .yngaiplaybook/             the playbook's files for this project
#   |   |-- README.md               the folder explained (rewritten every run)
#   |   |-- yngorchestratorconfig.yml  merge rules (written only if absent)
#   |   `-- yngorchestratorruns/    one run log per Epic, and run locks
#   |-- .claude/                    linked from .shared/.claude/, for a session at the root
#   |-- yngshared.sh                links .shared/ into the worktrees
#   `-- main/, epic-.../, ...       worktrees, linked file by file
#
# Steps, all safe to repeat:
#   1. Find the project root from --project (default: the current folder).
#   2. Copy the skill and worker into .shared/.claude/ (upgrades in place).
#   3. Fill .yngaiplaybook/: yngorchestratorconfig.yml from the template,
#      only if absent; yngorchestratorruns/; README.md from the template.
#   4. Add the two exclude lines to .bare/info/exclude, only if missing.
#   5. Copy yngshared.sh into the project root and link every worktree,
#      and .shared/.claude/ into the root's own .claude/.
#   6. Create or update the workflow labels with gh, when gh is available.
#   7. Copy yngv, the file viewer, to <bin-dir>/yngv (default ~/.local/bin).
#      Per user, not per project. When that folder is not on PATH it prints
#      the line to add to your shell's startup file; it edits none itself.
#
# Upgrading from 1.1.0-1.4.0: step 3 moves .yngorchestrator/ (1.2.0-1.4.0)
# or .orchestrator/ (1.1.0) into .yngaiplaybook/, one line per item:
# config.yml becomes yngorchestratorconfig.yml, runs/ becomes
# yngorchestratorruns/, any other file keeps its name, and the emptied old
# folder goes. When .yngaiplaybook/ already exists, or both old folders do,
# it moves nothing, leaves each folder as it is, and warns: move what you
# need by hand. From 1.1.0 (the skill was named "orchestrate"), steps 2, 4
# and 5 also remove the old skill folder, its exclude line and its links in
# every worktree.
#
# Run it again after creating a worktree, or to upgrade: it re-links every
# worktree and never overwrites your config.
#
# Usage: yngorch.sh [--project <path>] [--skip-labels] [--skip-viewer]
#                   [--bin-dir <path>]
# Requires: bash, git. Optional: gh, authenticated, for the labels.

set -euo pipefail

usage() { sed -n '2,53p' "$0" | sed 's/^# \{0,1\}//'; }

project=$PWD
skip_labels=0
skip_viewer=0
bin_dir="$HOME/.local/bin"
while [ $# -gt 0 ]; do
    case "$1" in
        --project) project=${2:?--project needs a path}; shift 2 ;;
        --skip-labels) skip_labels=1; shift ;;
        --skip-viewer) skip_viewer=1; shift ;;
        --bin-dir) bin_dir=${2:?--bin-dir needs a path}; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

here=$(cd "$(dirname "$0")" && pwd)
playbook=$(dirname "$here")
step() { printf '  %-8s %s\n' "$1" "$2"; }

# 1. The project root: the folder holding .bare/.
common=$(git -C "$project" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
[ -z "$common" ] && [ -d "$project/.bare" ] && common="$project/.bare"
if [ -z "$common" ] || [ "$(basename "$common")" != ".bare" ]; then
    echo "Not inside a bare-repository project (no .bare/ found from '$project'). See guides/epic-workflow.md, sections 7-8." >&2
    exit 1
fi
root=$(cd "$common/.." && pwd)
echo "YNG Orchestrator -> $root"

# 2. Skill and worker into .shared/.claude/.
mkdir -p "$root/.shared/.claude/skills/yngorchestrator" "$root/.shared/.claude/agents"
cp "$playbook"/skills/yngorchestrator/* "$root/.shared/.claude/skills/yngorchestrator/"
cp "$playbook/agents/slice-worker.md" "$root/.shared/.claude/agents/"
step copied ".shared/.claude/skills/yngorchestrator/, .shared/.claude/agents/slice-worker.md"
# The 1.1.0 skill folder, which only this installer writes.
if [ -d "$root/.shared/.claude/skills/orchestrate" ]; then
    rm -rf "$root/.shared/.claude/skills/orchestrate"; step removed ".shared/.claude/skills/orchestrate/ (renamed yngorchestrator)"
fi

# 3. The playbook's root folder, .yngaiplaybook/ (spec R23-R26). An older
# .yngorchestrator/ (1.2.0-1.4.0) or .orchestrator/ (1.1.0) moves into it
# first, item by item; when that is ambiguous, nothing moves or is created.
ynga="$root/.yngaiplaybook"
config="$ynga/yngorchestratorconfig.yml"
olds=""
for d in .yngorchestrator .orchestrator; do [ -d "$root/$d" ] && olds="$olds $d"; done
set -- $olds
if [ $# -gt 0 ] && { [ -d "$ynga" ] || [ $# -gt 1 ]; }; then
    names=""; [ -d "$ynga" ] && names=" .yngaiplaybook/"
    for d in "$@"; do names="$names $d/"; done
    step warning "found${names}; moved nothing and left each as it is: move what you need into .yngaiplaybook/ by hand"
else
    if [ $# -eq 1 ]; then
        old=$1
        mkdir -p "$ynga"
        for item in "$root/$old"/* "$root/$old"/.[!.]* "$root/$old"/..?*; do
            [ -e "$item" ] || [ -L "$item" ] || continue
            name=$(basename "$item")
            case "$name" in
                config.yml) dest=yngorchestratorconfig.yml ;;
                runs) dest=yngorchestratorruns ;;
                *) dest=$name ;;
            esac
            s=""; [ -d "$item" ] && s=/
            mv "$item" "$ynga/$dest"; step moved "$old/$name$s -> .yngaiplaybook/$dest$s"
        done
        if rmdir "$root/$old" 2>/dev/null; then step removed "$old/ (empty)"
        else step warning "$old/ is not empty; left in place"; fi
    fi
    mkdir -p "$ynga/yngorchestratorruns"
    if [ -f "$config" ]; then step kept ".yngaiplaybook/yngorchestratorconfig.yml (yours)"
    else cp "$playbook/templates/yngorchestratorconfig.yml" "$config"; step created ".yngaiplaybook/yngorchestratorconfig.yml (every path required)"; fi
    version=$(tr -d '\r\n' < "$playbook/VERSION")
    sed "s/{{VERSION}}/$version/g" "$playbook/templates/yngaiplaybookreadme.md" > "$ynga/README.md"
    step wrote ".yngaiplaybook/README.md (the folder explained, $version)"
fi

# 4. Exclude lines, only if missing; the 1.1.0 line goes.
exclude="$root/.bare/info/exclude"
mkdir -p "$(dirname "$exclude")"; touch "$exclude"
if grep -qxF /.claude/skills/orchestrate/ "$exclude"; then
    grep -vxF /.claude/skills/orchestrate/ "$exclude" > "$exclude.tmp" || true
    mv "$exclude.tmp" "$exclude"; step removed ".bare/info/exclude: /.claude/skills/orchestrate/"
fi
added=""
for line in /.claude/skills/yngorchestrator/ /.claude/agents/slice-worker.md; do
    grep -qxF "$line" "$exclude" || { printf '%s\n' "$line" >> "$exclude"; added="$added $line"; }
done
if [ -n "$added" ]; then step added ".bare/info/exclude:$added"; else step kept ".bare/info/exclude"; fi

# 5. Remove the 1.1.0 skill links from every worktree (links only; a real
# file is left with a warning), then link every worktree through yngshared,
# which must sit at the project root.
git --git-dir="$common" worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r wt; do
    dir="$wt/.claude/skills/orchestrate"
    [ -d "$dir" ] || continue
    find "$dir" -mindepth 1 -maxdepth 1 -type l -delete
    if rmdir "$dir" 2>/dev/null; then step removed "$dir (old links)"
    else step warning "$dir holds real files; left in place"; fi
done
cp "$here/yngshared.sh" "$root/yngshared.sh"; chmod +x "$root/yngshared.sh"
if out=$("$root/yngshared.sh" --link --all 2>&1); then step linked "every worktree and the root .claude/ (yngshared --link --all)"
else
    printf '%s\n' "$out" | grep -E '^(warn|error|ERROR)' | sed 's/^/  /' || true
    step warning "yngshared reported problems above"
fi

# 6. Labels, when gh is available.
if [ "$skip_labels" = 1 ]; then step skipped "labels (--skip-labels)"
elif ! command -v gh >/dev/null 2>&1; then step skipped "labels (gh not found)"
elif ! url=$(git --git-dir="$common" remote get-url origin 2>/dev/null); then step skipped "labels (no origin remote)"
else
    repo=${url%.git}
    failed=0; total=0
    while IFS='|' read -r name color desc; do
        total=$((total + 1))
        gh label create "$name" -R "$repo" -c "$color" -d "$desc" --force >/dev/null 2>&1 || failed=$((failed + 1))
    done <<'EOF'
epic|3e4b9e|Feature: tracker card plus integration branch
workflow:needs-triage|fbca04|Triage fills in every label
workflow:needs-info|d876e3|A person must answer before work starts
workflow:ready-for-agent|0e8a16|Gate 1 passed: an agent may pick it up (set by a person only)
workflow:ready-for-human|1d76db|Gate 1 passed: a person picks it up
workflow:in-progress|c5def5|Being worked; no PR yet (set by the dispatcher)
workflow:in-review|5319e7|PR open, waiting for a person (set by the dispatcher)
EOF
    if [ "$failed" -gt 0 ]; then step warning "labels: $failed of $total failed (is gh logged in? gh auth status)"
    else step labels "$total created or updated on $repo"; fi
fi

# 7. The yngv viewer, per user (not per project). The person's shell
# startup file is theirs: when bin_dir is not on PATH, print the line.
if [ "$skip_viewer" = 1 ]; then step skipped "yngv (--skip-viewer)"
else
    mkdir -p "$bin_dir"
    cp "$here/yngv.sh" "$bin_dir/yngv"; chmod +x "$bin_dir/yngv"
    bin_full=$(cd "$bin_dir" && pwd)
    step copied "yngv -> $bin_full/yngv"
    case ":$PATH:" in
        *":$bin_full:"*|*":$bin_full/:"*) step kept "$bin_full already on PATH" ;;
        *) step note "$bin_full is not on PATH; add this line to your shell's startup file (~/.bashrc, ~/.zshrc), then open a new terminal:"
           printf '             export PATH="%s:$PATH"\n' "$bin_full" ;;
    esac
fi

echo
echo "Done. Next:"
echo "  - Set your merge rules in $config"
echo "  - From an Epic worktree, start Claude Code and run: /yngorchestrator <epic issue>"
echo "  - After creating a new worktree, run this script again to link it."
