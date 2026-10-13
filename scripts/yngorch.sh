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
#   |   |-- yngorchestratorconfig.yml  issues repo, auto-promote, merge rules (yours; new settings added)
#   |   `-- yngorchestratorruns/    one run log per Epic, and run locks
#   |-- .claude/                    linked from .shared/.claude/, for a session at the root
#   |-- yngshared.sh                links .shared/ into the worktrees
#   `-- main/, epic-.../, ...       worktrees, linked file by file
#
# Steps, all safe to repeat:
#   1. Find the project root from --project (default: the current folder).
#   2. Copy the skill and worker into .shared/.claude/ (upgrades in place).
#   3. Fill .yngaiplaybook/: yngorchestratorconfig.yml from the template
#      if absent, else add the settings and keys it lacks, changing no line
#      of yours, after a backup to yngorchestratorconfig.yml.bak;
#      yngorchestratorruns/; README.md from the template.
#      With --issues-repo, write the config's issues: key, only if it has
#      no value yet; an existing value is kept and reported.
#   4. Add the two exclude lines to .bare/info/exclude, only if missing.
#   5. Copy yngshared.sh into the project root and link every worktree,
#      and .shared/.claude/ into the root's own .claude/.
#   6. Create or update the workflow labels with gh, when gh is available,
#      in the issues repo: --issues-repo, else the config's issues: value,
#      else origin's repo.
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
# worktree and never changes a line of your config.
#
# Usage: yngorch.sh [--project <path>] [--issues-repo <owner>/<repo>]
#                   [--skip-labels] [--skip-viewer] [--bin-dir <path>]
#
#   --issues-repo  the GitHub repository holding this project's issues, when
#                  they live apart from the code. Written into the config's
#                  issues: key only when it has no value yet, and used for the
#                  labels. Any other form stops the install before anything
#                  is written.
# Requires: bash, git. Optional: gh, authenticated, for the labels.

set -euo pipefail

usage() { sed -n '2,65p' "$0" | sed 's/^# \{0,1\}//'; }

project=$PWD
issues_repo=""
skip_labels=0
skip_viewer=0
bin_dir="$HOME/.local/bin"
while [ $# -gt 0 ]; do
    case "$1" in
        --project) project=${2:?--project needs a path}; shift 2 ;;
        --issues-repo) issues_repo=${2:?--issues-repo needs <owner>/<repo>}; shift 2 ;;
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

# The issues repo (spec R28, R31): <owner>/<repo>, checked before anything
# is written.
is_repo() { printf '%s' "$1" | grep -Eq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$'; }
if [ -n "$issues_repo" ] && ! is_repo "$issues_repo"; then
    echo "--issues-repo '$issues_repo' is not <owner>/<repo>; nothing was written." >&2
    exit 2
fi
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# The config's top-level issues: value; empty when absent or empty.
issues_value() {
    [ -f "$1" ] || return 0
    sed -n '/^issues:/{s/^issues:[[:space:]]*//p;q;}' "$1" | tr -d '\r' |
        sed -e 's/^#.*//' -e 's/[[:space:]]\{1,\}#.*$//' -e 's/[[:space:]]*$//' \
            -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/" -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Writes "issues: <value>" into the config: over its empty issues: line,
# else just after the template's commented-out one, else at the end.
# Keeps the file's line endings (BINMODE stops Windows gawk dropping CRs).
set_issues_value() {
    mode=after
    grep -q '^issues:' "$1" && mode=replace
    awk -v BINMODE=3 -v v="$2" -v mode="$mode" '
        { cr = sub(/\r$/, "") ? "\r" : "" }
        !done && mode == "replace" && /^issues:/ { print "issues: " v cr; done = 1; next }
        { print $0 cr }
        !done && mode == "after" && /^#[ \t]*issues:/ { print "issues: " v cr; done = 1 }
        END { if (!done) print "issues: " v cr }
    ' "$1" > "$1.tmp"
    mv "$1.tmp" "$1"
}

# The config upgrade (spec R39-R41). Reads a template, then the person's
# file, and writes the file with the settings and nested keys it lacks
# added to out. Prints one report line each: "A <text>" added,
# "W <text>" warning (R39.8), "N <text>" note (R40.3). Every line of the
# file is copied byte for byte; only whole new lines are inserted.
upgrade_awk='
function clean(s, first) {
    sub(/\r$/, "", s)
    if (first && bom != "" && substr(s, 1, length(bom)) == bom) s = substr(s, length(bom) + 1)
    return s
}
# An active key line: sets K_key, K_val (no trailing comment), K_ind, K_tab.
function parse(s,   ws, rest, p) {
    if (s ~ /^[ \t]*#/ || s ~ /^[ \t]*$/) return 0
    match(s, /^[ \t]*/); ws = substr(s, 1, RLENGTH); rest = substr(s, RLENGTH + 1)
    if (rest !~ /^[A-Za-z0-9_-]+:([ \t]|$)/) return 0
    p = index(rest, ":")
    K_key = substr(rest, 1, p - 1); K_val = substr(rest, p + 1)
    sub(/^[ \t]+/, "", K_val)
    if (K_val ~ /^#/) K_val = ""
    sub(/[ \t]+#.*$/, "", K_val); sub(/[ \t]+$/, "", K_val)
    K_ind = length(ws); K_tab = (ws ~ /\t/)
    return 1
}
# The <name> of a "# --- Setting: <name> ---" header line, else "".
function header(s,   r) {
    if (s !~ /^# --- Setting:[ \t]+[^ \t]/) return ""
    r = s; sub(/^# --- Setting:[ \t]+/, "", r); sub(/[ \t].*$/, "", r)
    return r
}
function spaces(n,   r) { r = ""; while (n-- > 0) r = r " "; return r }
# Records the keys written inside a flow-style value of q, {a: 1, b: 2},
# as flow[q, key]: they count as present (R39.5).
function flowkeys(q, v,   i, c, d, piece) {
    v = substr(v, 2); sub(/[}][ \t]*$/, "", v); d = 0; piece = ""
    for (i = 1; i <= length(v) + 1; i++) {
        c = (i <= length(v)) ? substr(v, i, 1) : ","
        if (c == "{" || c == "[") d++
        else if (c == "}" || c == "]") d--
        if (c == "," && d == 0) {
            sub(/^[ \t]+/, "", piece); sub(/^["\047]/, "", piece)
            if (match(piece, /^[A-Za-z0-9_-]+["\047]?:/)) {
                piece = substr(piece, 1, RLENGTH - 1); sub(/["\047]$/, "", piece)
                flow[q, piece] = 1
            }
            piece = ""
        } else piece = piece c
    }
}
# True when an ancestor of path p was inserted with its subtree.
function under(p,   x) {
    x = p
    while (sub(/\.[^.]*$/, "", x)) if (x in inserted) return 1
    return 0
}
function emit(s) {
    if (needbreak) { printf "%s", ((raw[N] ~ /\r$/) ? "\n" : eol) > out; needbreak = 0 }
    printf "%s", s > out
}
FILENAME == ARGV[1] { T++; traw[T] = $0; t[T] = clean($0, FNR == 1); next }
{ N++; raw[N] = $0; f[N] = clean($0, FNR == 1) }
END {
    # The template: its banner, its settings, and its active keys by path.
    tb = T + 1
    for (i = 1; i <= T; i++) if (t[i] ~ /^# ====/) { tb = i; break }
    ns = 0
    for (i = 1; i < tb; i++) {
        h = header(t[i])
        if (h != "") { ns++; sname[ns] = h; sstart[ns] = i; known[h] = 1 }
    }
    for (s = 1; s <= ns; s++) send[s] = (s < ns ? sstart[s + 1] : tb) - 1
    sp = 0; nk = 0
    for (i = 1; i < tb; i++) {
        if (!parse(t[i])) continue
        while (sp > 0 && sind[sp] >= K_ind) sp--
        p = sp ? spath[sp] "." K_key : K_key
        nk++; kpath[nk] = p; kline[nk] = i; kind[nk] = K_ind; kval[nk] = K_val
        kpar[nk] = sp ? spath[sp] : ""; kpind[nk] = sp ? sind[sp] : 0
        known[p] = 1
        sp++; sind[sp] = K_ind; spath[sp] = p
    }
    for (k = 1; k <= nk; k++) {
        kend[k] = kline[k]
        for (j = k + 1; j <= nk && kind[j] > kind[k]; j++) kend[k] = kline[j]
    }

    # The file: line endings, banner, headers, and its active keys by path.
    if (N > 1 || (N == 1 && !nofinal)) eol = (raw[1] ~ /\r$/) ? "\r\n" : "\n"
    else eol = (T > 1 && traw[1] ~ /\r$/) ? "\r\n" : "\n"
    fb = 0
    for (i = 1; i <= N; i++) if (f[i] ~ /^# ====/) { fb = i; break }
    for (i = 1; i <= N; i++) { h = header(f[i]); if (h != "") hdr[h] = 1 }
    sp = 0; notes = ""
    for (i = 1; i <= N; i++) {
        if (!parse(f[i])) continue
        while (sp > 0 && sind[sp] >= K_ind) sp--
        p = sp ? spath[sp] "." K_key : K_key
        cnt[p]++; hasval[p] = (K_val != ""); pind[p] = K_ind; last[p] = i
        if (K_val ~ /^[{]/) flowkeys(p, K_val)
        for (a = 1; a <= sp; a++) last[spath[a]] = i
        if (sp) {
            q = spath[sp]
            if (K_tab) tab[q] = 1
            if (q in cind) { if (cind[q] != K_ind) mixed[q] = 1 } else cind[q] = K_ind
        }
        if (!(p in known) && !(p in noted)) {
            noted[p] = 1
            notes = notes "N " disp ": " p " is not in the template; the orchestrator ignores it\n"
        }
        # A tab-indented key has no measurable depth: it parents nothing.
        if (!K_tab) { sp++; sind[sp] = K_ind; spath[sp] = p }
    }

    # Missing settings (R39.5, R39.6): whole sections, in template order.
    warns = ""; ins_set = ""
    for (s = 1; s <= ns; s++) {
        n = sname[s]
        if (cnt[n] > 0 || (n in hdr)) continue
        missing[n] = 1
        for (i = sstart[s]; i <= send[s]; i++) ins_set = ins_set t[i] eol
        addl[sstart[s]] = "A " disp ": " n " (new in the template)\n"
    }

    # Missing nested keys (R39.7, R39.8), in template order.
    for (k = 1; k <= nk; k++) {
        p = kpath[k]; q = kpar[k]
        if (q == "") continue
        top = p; sub(/\..*$/, "", top)
        if ((top in missing) || under(p) || cnt[p] > 0 || !(cnt[q] > 0)) continue
        kk = p; sub(/^.*[.]/, "", kk)
        if ((q, kk) in flow) continue
        why = ""
        if (cnt[q] > 1) why = q " is set more than once"
        else if (hasval[q]) why = q " has its value on the same line"
        else if (q in tab) why = "the keys under " q " are indented with a tab"
        else if (q in mixed) why = "the keys under " q " are not all at one indentation"
        if (why != "") {
            pk = q; sub(/^.*\./, "", pk)
            warns = warns "W " disp ": " p " not added, " why "; add it by hand under " pk ": as \"" t[kline[k]] "\"\n"
            continue
        }
        ind = (q in cind) ? cind[q] : pind[q] + kind[k] - kpind[k]
        pos = last[q]
        for (i = kline[k]; i <= kend[k]; i++) {
            l = t[i]; m = 0
            while (m < kind[k] && substr(l, m + 1, 1) == " ") m++
            ins[pos] = ins[pos] spaces(ind) substr(l, m + 1) eol
        }
        inserted[p] = 1
        addl[kline[k]] = "A " disp ": " p ": " kval[k] " (new in the template)\n"
    }

    # The file, every line as it was, with the new lines in place.
    printf "" > out
    needbreak = 0
    for (i = 1; i <= N; i++) {
        if (i == fb && ins_set != "") emit(ins_set)
        emit(raw[i])
        if (i < N || !nofinal) emit("\n"); else needbreak = 1
        if (i in ins) emit(ins[i])
    }
    if (!fb && ins_set != "") emit(ins_set)
    close(out)
    # Added lines, settings and nested keys mixed, in template order.
    adds = ""
    for (i = 1; i <= T; i++) if (i in addl) adds = adds addl[i]
    printf "%s%s%s", adds, warns, notes
}'

# Installs one config file from its template (spec R39-R41): writes it
# whole when absent, else adds what it lacks after a backup to <file>.bak.
# $1 template, $2 target, $3 the target as printed, $4 what a new copy holds.
install_config() {
    if [ ! -f "$2" ]; then
        cp "$1" "$2"; step created "$3 ($4)"; return
    fi
    nofinal=0
    [ -s "$2" ] && [ -n "$(tail -c1 "$2")" ] && nofinal=1
    report=$(LC_ALL=C awk -v BINMODE=3 -v bom="$(printf '\357\273\277')" -v nofinal="$nofinal" \
        -v disp="$3" -v out="$2.tmp" "$upgrade_awk" "$1" "$2")
    if printf '%s\n' "$report" | grep -q '^A '; then
        cp "$2" "$2.bak"; step "backed up" "$3 -> $(basename "$2").bak"
        cat "$2.tmp" > "$2"
    else
        step kept "$3 (yours, nothing new)"
    fi
    rm -f "$2.tmp"
    printf '%s\n' "$report" | while IFS= read -r line; do
        case "$line" in
            "A "*) step added "${line#A }" ;;
            "W "*) step warning "${line#W }" ;;
            "N "*) step note "${line#N }" ;;
        esac
    done
}

# Every config file yngorch installs from a template (spec R41.1), one per
# line: template (in the playbook) | file (in .yngaiplaybook/) | what a new
# copy holds. A config file added later is one more line here.
config_files='templates/yngorchestratorconfig.yml|yngorchestratorconfig.yml|auto-promote: no, every merge path required'

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
    while IFS='|' read -r tpl name holds; do
        step skipped ".yngaiplaybook/$name not upgraded (move .yngaiplaybook/ by hand first, then run again)"
    done <<EOF
$config_files
EOF
    if [ -n "$issues_repo" ]; then
        step skipped "issues: $issues_repo not written (move .yngaiplaybook/ by hand first, then run again)"
    fi
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
    while IFS='|' read -r tpl name holds; do
        install_config "$playbook/$tpl" "$ynga/$name" ".yngaiplaybook/$name" "$holds"
    done <<EOF
$config_files
EOF
    current=$(issues_value "$config")
    if [ -n "$issues_repo" ] && [ -z "$current" ]; then
        set_issues_value "$config" "$issues_repo"
        step wrote "issues: $issues_repo into .yngaiplaybook/yngorchestratorconfig.yml"
    elif [ -n "$issues_repo" ] && [ "$(lower "$current")" != "$(lower "$issues_repo")" ]; then
        step kept "issues: $current in .yngaiplaybook/yngorchestratorconfig.yml (yours; --issues-repo $issues_repo not written)"
    elif [ -n "$current" ]; then
        step kept "issues: $current in .yngaiplaybook/yngorchestratorconfig.yml"
    fi
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

# 6. Labels, when gh is available, in the issues repo: --issues-repo, else
# the config's issues: value, else origin's repo (spec R31.3).
config_issues=$(issues_value "$config")
repo=$issues_repo
[ -z "$repo" ] && repo=$config_issues
if [ "$skip_labels" = 1 ]; then step skipped "labels (--skip-labels)"
elif ! command -v gh >/dev/null 2>&1; then step skipped "labels (gh not found)"
elif [ -n "$repo" ] && ! is_repo "$repo"; then step warning "labels skipped: the config's issues: '$repo' is not <owner>/<repo>"
elif [ -z "$repo" ] && ! url=$(git --git-dir="$common" remote get-url origin 2>/dev/null); then step skipped "labels (no origin remote)"
else
    [ -z "$repo" ] && repo=${url%.git}
    failed=0; total=0
    while IFS='|' read -r name color desc; do
        total=$((total + 1))
        gh label create "$name" -R "$repo" -c "$color" -d "$desc" --force >/dev/null 2>&1 || failed=$((failed + 1))
    done <<'EOF'
epic|3e4b9e|Feature: tracker card plus integration branch
workflow:needs-triage|fbca04|Triage fills in every label
workflow:needs-info|d876e3|A person must answer before work starts
workflow:ready-for-agent|0e8a16|Gate 1 passed: an agent may pick it up (set by a person, or by plan approval if auto-promote: yes)
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
echo "  - Set auto-promote (Gate 1) and your merge rules (Gate 2) in $config"
echo "  - From an Epic worktree, start Claude Code and run: /yngorchestrator <epic issue>"
echo "  - After creating a new worktree, run this script again to link it."
