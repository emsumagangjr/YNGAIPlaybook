#!/usr/bin/env bash
#
# yngshared - share private files from .shared/ with git worktrees:
#             --link, --copy or --unlink.
#
#   Name:     yngshared.sh
#   Version:  1.1.0
#   Created:  2026-09-19
#   Author:   Emeterio M. Sumagang Jr.
#   Company:  YNGSoftware (www.yngsoftware.com)
#
# macOS / Linux counterpart of yngshared.ps1.
#
# DESCRIPTION
#   Works with any project laid out as a bare repository with one folder per
#   worktree (the "Bare Repository + Git Worktrees" pattern):
#
#       <project-root>/
#       |-- .bare/          shared git database
#       |-- .shared/        private, untracked files (.env, secrets/, ...)
#       |-- main/           worktree
#       |-- <other>/        more worktrees (epic, task, agent, ...)
#       `-- yngshared.sh    <- this script (must sit at the project root)
#
#   Every existing file inside .shared/, including subfolders, is an "item".
#   Matching destination folders are created as real folders; only files are
#   linked. Empty folders are ignored. Choose exactly one action, and the
#   worktree(s) to apply it to:
#
#       --link     Put a relative symbolic link to each item in the worktree.
#                  The worktree follows .shared/: edit the file through any
#                  worktree and every linked worktree sees the change.
#       --copy     Put a real, independent copy of each item in the worktree.
#                  Same result as --link followed by --unlink. Use it when a
#                  worktree needs its own .env values.
#       --unlink   Turn each link into a real copy of the item it pointed to.
#                  Only links into .shared/ are touched; real files are never
#                  changed.
#
#   Nothing inside .shared/ is ever changed, moved or deleted.
#
# PROJECT ROOT
#   --link also links every file of .shared/.claude/ into the project root's
#   own .claude/ (for example .claude/agents/slice-worker.md), by the same
#   rules as a worktree, so a Claude Code session started at the root finds
#   the same skills and agents. Only .claude/ goes to the root; .env and the
#   other items do not. The root is outside every worktree, so it needs no
#   exclude line. --copy and --unlink leave the root alone.
#
# REQUIREMENTS
#   - bash 3.2+ (the macOS default is fine) and standard tools: ln, cp, mv,
#     cmp, diff, readlink.
#   - Git on PATH (only needed for --all).
#   - A project root containing .bare/ and .shared/ as shown above.
#
# INSTALL
#   Copy this file into the project root, beside .bare/ and .shared/, and make
#   it executable (chmod +x yngshared.sh). The script treats its own folder as
#   the project root, so it cannot be run from anywhere else.
#
# HOW TO RUN
#   ./yngshared.sh --link main                 link every .shared file into main/,
#                                              and .shared/.claude/ into the root
#   ./yngshared.sh --link main epic-auth       several worktrees at once
#   ./yngshared.sh --link --all --what-if      preview every worktree
#   ./yngshared.sh --copy agent-x --name .env  agent-x gets its own .env only
#   ./yngshared.sh --copy dev --name config/app.ini   its own copy of a nested file
#   ./yngshared.sh --unlink dev                dev's links become real copies
#   ./yngshared.sh --link main dev --force     replace real files (backed up)
#
# OPTIONS
#   --link | --copy | --unlink   the action (exactly one)
#   --all                        every worktree from 'git worktree list'
#   --name a,b                   limit to these files from .shared/, as paths
#                                relative to .shared/ (e.g. --name .env,config/app.ini;
#                                backslashes are accepted too). A name is always
#                                a single file: a folder name, or a file that does
#                                not exist, is an error.
#   --force                      with --link/--copy: also replace a real file
#                                (after a backup) and a link that points
#                                somewhere else. Never replaces a folder. No
#                                effect with --unlink.
#   --what-if                    show what would happen, change nothing
#                                (recommended before --copy, --unlink, --force
#                                or --all)
#   -h, --help                   show this help
#
# WHAT HAPPENS TO WHAT IS ALREADY IN THE WORKTREE
#
#     At the path                  --link            --copy            --unlink
#     ---------------------------  ----------------  ----------------  ----------------
#     nothing there                symlink           real copy         skip
#     link into .shared/           keep (already     convert to a      convert to a
#                                  linked)           real copy         real copy
#     real file                    keep              keep              keep
#       ...with --force            back up, symlink  back up, copy     keep (no effect)
#     real folder (where a         warn and skip     warn and skip     keep
#     file should go)
#       ...with --force            warn and skip     warn and skip     keep (no effect)
#     link somewhere else, or      warn and skip     warn and skip     warn and skip
#     broken link
#       ...with --force            replace with a    replace with a    warn and skip
#                                  symlink           copy
#
#   Without --force nothing real is ever overwritten, so a worktree's own .env
#   survives and re-running is always safe. A worktree opts out of sharing
#   simply by having its own real file at that path.
#
#   --force only ever replaces files. A real folder sitting where a file should
#   go is never backed up, moved or replaced, with or without --force; it is
#   reported as a warning and you sort it out by hand.
#
# LINKED FOLDERS
#   If a folder between the worktree and the file is itself a symlink (older
#   versions of this script linked whole folders, e.g. secrets -> ../.shared/secrets),
#   anything done beneath it would land in the link's target, possibly inside
#   .shared/. So every action, --force included, warns and skips files beneath a
#   linked folder. Remove that folder link yourself with 'rm dev/secrets' (no
#   trailing slash; removes only the link, never what it points to), then run the
#   script again to create per-file links.
#
# --FORCE AND BACKUPS
#   With --force, a real file that differs from the shared item is
#   first renamed inside the same worktree to
#       <name>.yngshared-bak-<yyyyMMdd-HHmmss>
#   The first time a backup is made, the pattern *.yngshared-bak-* is added to
#   .bare/info/exclude, a local Git file that is never committed and applies to
#   every worktree, so backups (which may contain secrets) can never show up in
#   'git status'. No backup is made when the existing file is identical to the
#   shared one. The script never deletes backups; delete them yourself.
#
# SYMBOLIC LINKS
#   Each link points at one file, never at a folder, and is relative to its own
#   location: ../.shared/.env for dev/.env, ../../.shared/config/app.ini for
#   dev/config/app.ini. They keep working if the project folder is moved or
#   renamed.
#
# GIT
#   Links and copies must not be committed. Make sure each private name is
#   ignored in every branch's .gitignore (for example /.env). A pattern with a
#   trailing slash does not match a symlink. Afterwards 'git status --short'
#   should not list them.
#
# OUTPUT (one line per item; "would ..." instead when --what-if is used)
#   symlink  created a relative symbolic link      copy   created a real copy
#   backup   renamed an existing real file (force)  keep   left alone
#   skip     nothing to do                         warn   refused (a problem)
#   error    something failed (a problem)
#
# EXIT CODE
#   0 = success, 1 = a warning or error occurred, 2 = usage mistake.

set -u

ROOT=$(cd "$(dirname "$0")" && pwd -P)
SHARED="$ROOT/.shared"
STAMP=$(date +%Y%m%d-%H%M%S)
PROBLEMS=0
EXCLUDE_DONE=0

LINK=0; COPY=0; UNLINK=0; ALL=0; FORCE=0; WHATIF=0
NAMES=""
WORKTREES=()

usage() {
    # Print the header comment block (line 2 up to the first non-comment line).
    sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

die_usage() {
    echo "ERROR: $1" >&2
    echo >&2
    usage >&2
    exit 2
}

# --------------------------------------------------------------------------
# Command line
# --------------------------------------------------------------------------

while [ $# -gt 0 ]; do
    case "$1" in
        --link)    LINK=1 ;;
        --copy)    COPY=1 ;;
        --unlink)  UNLINK=1 ;;
        --all)     ALL=1 ;;
        --force)   FORCE=1 ;;
        --what-if) WHATIF=1 ;;
        --name)
            [ $# -ge 2 ] || die_usage "--name needs a value, e.g. --name .env,config/app.ini"
            NAMES="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        -*)        die_usage "Unknown option: $1" ;;
        *)         WORKTREES+=("$1") ;;
    esac
    shift
done

count=$((LINK + COPY + UNLINK))
[ "$count" -eq 0 ] && die_usage "Choose one action: --link, --copy or --unlink."
[ "$count" -gt 1 ] && die_usage "Choose only one of --link, --copy and --unlink."
if [ "$LINK" -eq 1 ]; then ACTION=link; elif [ "$COPY" -eq 1 ]; then ACTION=copy; else ACTION=unlink; fi

if [ "$ALL" -eq 1 ] && [ ${#WORKTREES[@]} -gt 0 ]; then die_usage "Use either --all or worktree names, not both."; fi
if [ "$ALL" -eq 0 ] && [ ${#WORKTREES[@]} -eq 0 ]; then die_usage "Name at least one worktree, or use --all."; fi

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

report() {   # report STATUS PATH [NOTE]
    local status="$1" path="$2" note="${3:-}" text
    text="$status"
    if [ "$WHATIF" -eq 1 ]; then
        case "$status" in symlink|copy|backup) text="would $status" ;; esac
    fi
    if [ -n "$note" ]; then text="$text  $path  ($note)"; else text="$text  $path"; fi
    case "$status" in
        warn)  printf '\033[33m%s\033[0m\n' "$text" ;;
        error) printf '\033[31m%s\033[0m\n' "$text" ;;
        *)     printf '%s\n' "$text" ;;
    esac
}

problem() { PROBLEMS=$((PROBLEMS + 1)); }

# Absolute path of a possibly-nonexistent entry: resolve its folder, keep the name.
abs_path() {
    local d b
    d=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) || return 1
    b=$(basename "$1")
    if [ "$d" = "/" ]; then printf '/%s' "$b"; else printf '%s/%s' "$d" "$b"; fi
}

# Classify what is at $1 relative to shared item $2:
#   none | shared (symlink to this item) | other (symlink elsewhere/broken) | real
get_state() {
    local dest="$1" item="$2" target
    if [ -L "$dest" ]; then
        target=$(readlink "$dest")
        case "$target" in /*) ;; *) target="$(dirname "$dest")/$target" ;; esac
        target=$(abs_path "$target") || target=""
        if [ -n "$target" ] && [ "$target" = "$(abs_path "$item")" ]; then echo shared; else echo other; fi
    elif [ -e "$dest" ]; then
        echo real
    else
        echo none
    fi
}

same_content() {   # same_content PATH SHARED_PATH  (files only)
    cmp -s "$1" "$2"
}

# Keep backups out of 'git status' for every worktree without touching a
# tracked file: .bare/info/exclude is local to this repository.
add_git_exclude() {
    [ "$EXCLUDE_DONE" -eq 1 ] && return 0
    local pattern='*.yngshared-bak-*' dir="$ROOT/.bare/info" file
    file="$dir/exclude"
    mkdir -p "$dir"
    if [ ! -f "$file" ] || ! grep -qxF "$pattern" "$file"; then
        # Make sure we start on a fresh line.
        if [ -s "$file" ] && [ "$(tail -c1 "$file" | wc -l)" -eq 0 ]; then printf '\n' >> "$file"; fi
        printf '%s\n' "$pattern" >> "$file"
    fi
    EXCLUDE_DONE=1
}

backup_existing() {   # prints the backup path
    local dest="$1" bak="$1.yngshared-bak-$STAMP"
    if [ -e "$bak" ] || [ -L "$bak" ]; then bak="$bak-$RANDOM"; fi
    mv "$dest" "$bak" || return 1
    add_git_exclude
    printf '%s' "$bak"
}

# Relative link target: climb from the destination file's folder back to the
# project root (one "../" per level of worktree label plus one per folder in
# the item's relative path), then down into .shared/.
make_symlink() {   # make_symlink DEST REL LABEL
    local dest="$1" rel="$2" label="$3" up="" levels i
    levels=$(( $(printf '%s' "$label" | awk -F/ '{print NF}') + $(printf '%s' "$rel" | awk -F/ '{print NF}') - 1 ))
    for ((i = 0; i < levels; i++)); do up="../$up"; done
    ln -s "${up}.shared/$rel" "$dest"
}

install_item() {   # install_item WHAT DEST REL LABEL   (WHAT = link|copy)
    local what="$1" dest="$2" rel="$3" label="$4"
    [ -f "$SHARED/$rel" ] || { echo "Shared source is not an existing file: $SHARED/$rel" >&2; return 1; }
    mkdir -p "$(dirname "$dest")" || return 1
    if [ "$what" = link ]; then make_symlink "$dest" "$rel" "$label"
    else cp "$SHARED/$rel" "$dest"
    fi
}

# Replace a link by a real copy. The copy is made first, so a failure leaves
# the link in place.
convert_to_copy() {   # convert_to_copy DEST ITEM
    local dest="$1" item="$2" tmp="$1.yngshared-tmp"
    if [ -e "$tmp" ] || [ -L "$tmp" ]; then echo "Leftover temporary path exists: $tmp" >&2; return 1; fi
    cp -R "$item" "$tmp" || { rm -rf "$tmp"; return 1; }
    rm -f "$dest" && mv "$tmp" "$dest"
}

# Print the first folder between the worktree root and DEST that is a symlink;
# return 1 when there is none. Anything done through such a folder would land
# wherever the link points (older versions of this script linked whole folders
# such as secrets/ into .shared/), so the script must not touch paths beneath it.
linked_parent() {   # linked_parent DEST WT_PATH
    local p
    p=$(dirname "$1")
    while [ "${#p}" -gt "${#2}" ]; do
        if [ -L "$p" ]; then printf '%s' "$p"; return 0; fi
        p=$(dirname "$p")
    done
    return 1
}

invoke_item_action() {   # invoke_item_action ACTION DEST REL LABEL WT_PATH
    local action="$1" dest="$2" rel_in="$3" label="$4" wt="$5" item rel state place same bak linked
    item="$SHARED/$rel_in"; rel="${label:+$label/}$rel_in"
    if linked=$(linked_parent "$dest" "$wt"); then
        report warn "$rel" "parent folder ${linked#"$wt"/} is a link (older version?); replace it with a real folder first"
        problem; return
    fi
    state=$(get_state "$dest" "$item")
    if [ "$action" = link ]; then place=symlink; else place=copy; fi

    case "$state" in
        none)
            if [ "$action" = unlink ]; then report skip "$rel" "not present"; return; fi
            if [ "$WHATIF" -eq 0 ]; then install_item "$action" "$dest" "$rel_in" "$label" || { report error "$rel" "could not create"; problem; return; }; fi
            report "$place" "$rel"
            ;;
        shared)
            if [ "$action" = link ]; then report keep "$rel" "already linked"; return; fi
            if [ "$WHATIF" -eq 0 ]; then convert_to_copy "$dest" "$item" || { report error "$rel" "could not convert"; problem; return; }; fi
            report copy "$rel" "replaced symlink"
            ;;
        real)
            if [ "$action" = unlink ]; then report keep "$rel" "not a link"; return; fi
            if [ -d "$dest" ]; then
                # --force only replaces files; never move or delete a folder.
                report warn "$rel" "a folder is in the way; only files are replaced"; problem; return
            fi
            if [ "$FORCE" -eq 0 ]; then report keep "$rel" "real file; --force replaces it"; return; fi
            if same_content "$dest" "$item"; then same=1; else same=0; fi
            if [ "$same" -eq 1 ] && [ "$action" = copy ]; then report keep "$rel" "already an identical copy"; return; fi
            bak=""
            if [ "$same" -eq 0 ]; then
                if [ "$WHATIF" -eq 0 ]; then bak=$(backup_existing "$dest") || { report error "$rel" "backup failed"; problem; return; }; fi
                report backup "$rel" "to $rel.yngshared-bak-$STAMP"
            elif [ "$WHATIF" -eq 0 ]; then
                rm -f "$dest"   # identical to the shared item: nothing to lose
            fi
            if [ "$WHATIF" -eq 0 ]; then
                if ! install_item "$action" "$dest" "$rel_in" "$label"; then
                    [ -n "$bak" ] && mv "$bak" "$dest"
                    report error "$rel" "could not create"; problem; return
                fi
            fi
            report "$place" "$rel"
            ;;
        other)
            if [ "$action" = unlink ] || [ "$FORCE" -eq 0 ]; then
                report warn "$rel" "link points somewhere else or is broken; --force replaces it"
                problem; return
            fi
            if [ "$WHATIF" -eq 0 ]; then
                rm -f "$dest"
                install_item "$action" "$dest" "$rel_in" "$label" || { report error "$rel" "could not create"; problem; return; }
            fi
            report "$place" "$rel" "replaced other link"
            ;;
    esac
}

# Resolve a worktree argument: sets WT_PATH and WT_LABEL, or returns 1 with a message.
resolve_worktree() {
    local arg="$1" p
    if [ -d "$arg" ]; then p=$(cd "$arg" && pwd -P)
    elif [ -d "$ROOT/$arg" ]; then p=$(cd "$ROOT/$arg" && pwd -P)
    else WT_ERR="Not a folder: $arg"; return 1
    fi
    case "$p/" in
        "$ROOT"/*) ;;
        *) WT_ERR="Not inside the project root ($ROOT): $p"; return 1 ;;
    esac
    WT_PATH="$p"
    WT_LABEL="${p#"$ROOT"/}"
    if [ "$p" = "$ROOT" ]; then WT_ERR="Not a worktree: the project root itself"; return 1; fi
    case "$WT_LABEL" in .shared|.bare) WT_ERR="Not a worktree: $WT_LABEL"; return 1 ;; esac
    return 0
}

# --------------------------------------------------------------------------
# Preconditions
# --------------------------------------------------------------------------

if [ ! -d "$SHARED" ]; then
    echo "ERROR: $SHARED does not exist. Create it and put the private files there first." >&2
    exit 1
fi

# ITEMS holds paths relative to .shared/ (e.g. ".env", "config/app.ini"). Only
# entries that resolve to an existing file count, so folders and broken links
# are left out.
ITEMS=()
while IFS= read -r line; do
    rel="${line#"$SHARED"/}"
    [ -f "$SHARED/$rel" ] && ITEMS+=("$rel")
done < <(find "$SHARED" \( -type f -o -type l \) | sort)

if [ -n "$NAMES" ]; then
    FILTERED=()
    IFS=',' read -r -a WANTED <<< "$NAMES"
    missing=""
    for w in "${WANTED[@]}"; do
        w="${w//\\//}"   # accept backslashes as folder separators
        found=0
        for it in "${ITEMS[@]+"${ITEMS[@]}"}"; do
            if [ "$it" = "$w" ]; then found=1; FILTERED+=("$it"); fi
        done
        [ "$found" -eq 0 ] && missing="$missing $w"
    done
    if [ -n "$missing" ]; then echo "ERROR: not an existing file inside .shared/:$missing" >&2; exit 1; fi
    ITEMS=("${FILTERED[@]}")
fi

if [ ${#ITEMS[@]} -eq 0 ]; then echo "Nothing to do: .shared/ contains no existing files."; exit 0; fi

# --------------------------------------------------------------------------
# Work out the worktrees, then apply the action
# --------------------------------------------------------------------------

TARGETS=()
if [ "$ALL" -eq 1 ]; then
    if ! out=$(git --git-dir="$ROOT/.bare" worktree list --porcelain 2>&1); then
        echo "ERROR: 'git worktree list' failed: $out" >&2
        exit 1
    fi
    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                wp="${line#worktree }"
                # Canonicalize so the comparison with $ROOT is not fooled by
                # symlinked folders (e.g. /tmp -> /private/tmp on macOS).
                wp=$(cd "$wp" 2>/dev/null && pwd -P) || continue
                case "$wp" in
                    "$ROOT"/*) case "$wp" in */.bare) ;; *) TARGETS+=("$wp") ;; esac ;;
                esac ;;
        esac
    done <<< "$out"
else
    TARGETS=("${WORKTREES[@]}")
fi

for arg in "${TARGETS[@]+"${TARGETS[@]}"}"; do
    if ! resolve_worktree "$arg"; then
        printf '\033[31merror  %s  (%s)\033[0m\n' "$arg" "$WT_ERR"
        problem
        continue
    fi
    for item in "${ITEMS[@]}"; do
        invoke_item_action "$ACTION" "$WT_PATH/$item" "$item" "$WT_LABEL" "$WT_PATH"
    done
done

# --link also links .shared/.claude/ into the project root's own .claude/, so
# a Claude Code session started at the root finds the same skills and agents.
# The root is outside every worktree, so no exclude line is needed.
if [ "$ACTION" = link ]; then
    for item in "${ITEMS[@]}"; do
        case "$item" in
            .claude/*) invoke_item_action link "$ROOT/$item" "$item" "" "$ROOT" ;;
        esac
    done
fi

[ "$WHATIF" -eq 1 ] && echo "WhatIf: nothing was changed."
[ "$PROBLEMS" -gt 0 ] && exit 1
exit 0
