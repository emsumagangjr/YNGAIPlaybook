#!/usr/bin/env bash
#
# yngboard - open this worktree's run board.
#
#   Name:     yngboard.sh
#   Version:  1.0.0
#   Created:  2026-11-25
#   Author:   Emeterio M. Sumagang Jr.
#   Company:  YNGSoftware (www.yngsoftware.com)
#
# macOS / Linux counterpart of yngboard.ps1. The two behave alike, message
# for message.
#
# DESCRIPTION
#   A run board is one HTML file for one run log, written by
#   /yngorchestrator at every run-log event into
#   <root>/.yngaiplaybook/yngboard-<n>.html. It shows every slice of the
#   Epic, each slice's state, and whether each needs a person. yngboard
#   finds the board this worktree belongs to and hands it to yngv, which
#   opens it in the default browser.
#
#   It opens a file and nothing else: no provider call, no gather, no
#   ranking, no regeneration, no write. A board is as old as the timestamp
#   it shows, and a run is what refreshes it.
#
#   Which board, by the branch of the worktree the call is made in:
#
#       epic/<n>-...     that Epic's own board, run log <n>
#       slice/<n>-...    its Epic's board: the run log holding #<n>'s events
#       fix/<n>-...      that standalone issue's own board, run log <n>
#       no issue named   the most recently written yngboard-*.html
#
#   The last row is the project root, a worktree on main, a detached HEAD,
#   and any branch whose name does not start with an issue number.
#
#   With no board written for that log, it says so in one line, names the
#   run that would write one, and opens nothing. A branch that names an
#   issue never falls back to another log's board: a board of the wrong
#   Epic is worse than no board.
#
# ENVIRONMENT
#   yngboard reads no environment variable of its own. YNGV_HTML_BROWSER
#   belongs to yngv and reaches it through yngv, which trims and matches
#   the value the same way in both of its scripts: one reader, one rule.
#
# REQUIREMENTS
#   - bash 3.2+ (the macOS default is fine), git, sed, grep, ls.
#   - yngv, beside this script or on PATH. yngorch installs the two
#     together, into the same folder.
#
# INSTALL
#   yngorch installs it. By hand it is the two steps yngv takes:
#       cp yngboard.sh ~/.local/bin/yngboard
#       chmod +x ~/.local/bin/yngboard
#   with ~/.local/bin on PATH.
#
# RUN
#   yngboard        open this worktree's board
#   yngboard -h     show this help
#
# EXIT
#   0  the board was handed to yngv
#   1  no board for this worktree's log, no project around this folder,
#      or no yngv to open it with
#   2  an argument was given; yngboard takes none

set -u

usage() {
    # Print the header comment block (lines 2 up to the first non-comment line).
    sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *) echo "yngboard: takes no argument, and was given: $1" >&2; usage >&2; exit 2 ;;
    esac
done

# 1. The project root, as step 1 of locate.md finds it: the folder holding
# .bare/, which Git names inside a worktree and which is the folder itself
# at the root, where the session is outside Git.
root=""
if common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    root=$(dirname "$common")        # <root>/.bare -> <root>
elif [ -d .bare ]; then
    root=$(pwd -P)                   # the call was made at the root
fi
if [ -z "$root" ] || [ ! -d "$root/.bare" ]; then
    echo "yngboard: not inside a project laid out as a bare repository with worktrees (no .bare/ found)" >&2
    exit 1
fi
boards="$root/.yngaiplaybook"

# 2. <n> from the branch, as locate.md's `continue` takes it. No branch, a
# detached HEAD and a branch like main all leave both empty.
branch=$(git branch --show-current 2>/dev/null)
kind=$(printf '%s\n' "$branch" | sed -nE 's#^(epic|fix|slice)/([0-9]+)-.*#\1#p')
n=$(printf '%s\n' "$branch"    | sed -nE 's#^(epic|fix|slice)/([0-9]+)-.*#\2#p')

# 3. The run log the board is named for: an Epic's and a standalone issue's
# own number, a slice's its Epic's (SKILL.md, Run log). A slice's Epic is
# the log holding the slice's own events, which is a local file read: no
# provider call finds it.
log=""
case "$kind" in
    epic|fix) log=$n ;;
    slice)
        for f in "$boards/yngorchestratorruns"/*.md; do
            [ -f "$f" ] || continue
            if grep -Eq "^[^ ]+ #${n}([[:space:]]|\$)" "$f"; then
                log=$(basename "$f" .md)
                break
            fi
        done
        ;;
esac

# 4. The board file itself. A branch that names an issue gets that issue's
# log's board or none at all: another log's board is not this worktree's,
# and a board of the wrong Epic is worse than no board. Only a branch naming
# no issue falls back to the most recently written one.
board=""
why=""
if [ -n "$n" ]; then
    if [ -n "$log" ] && [ -f "$boards/yngboard-$log.html" ]; then
        board="$boards/yngboard-$log.html"
        why="run log $log"
    fi
else
    board=$(ls -t "$boards"/yngboard-*.html 2>/dev/null | sed -n 1p)
    [ -n "$board" ] && [ -f "$board" ] || board=""
    why="most recently written board"
fi

if [ -z "$board" ]; then
    if [ -n "$n" ]; then
        printf 'yngboard: no board written for #%s yet - start a run to write one: /yngorchestrator %s\n' "$n" "$n" >&2
    else
        printf 'yngboard: no board written in %s yet - start a run to write one: /yngorchestrator <issue>\n' "$boards" >&2
    fi
    exit 1
fi

# 5. Hand it to yngv, which opens an .html file in the default browser:
# beside this script, where yngorch puts the two together, else on PATH.
here=$(cd "$(dirname "$0")" && pwd -P)
if [ -x "$here/yngv" ]; then
    set -- "$here/yngv"
elif [ -f "$here/yngv.sh" ]; then
    set -- bash "$here/yngv.sh"
elif yngv=$(command -v yngv 2>/dev/null); then
    set -- "$yngv"
else
    printf 'yngboard: yngv not found beside this script or on PATH - open it yourself: %s\n' "$board" >&2
    exit 1
fi

printf 'yngboard: %s (%s; as of the timestamp on the page - a run refreshes it)\n' "$board" "$why"
"$@" "$board"
exit $?
