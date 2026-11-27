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
#   A run board is one HTML file for one issue, written by /yngorchestrator
#   into <root>/.yngaiplaybook/yngboard-<issue>.html: an Epic's board, a
#   slice's own board, or a standalone issue's. yngboard finds the board of
#   the issue this worktree's branch names and hands it to yngv, which opens
#   it in the default browser - unless YNGV_HTML_BROWSER is off, when it
#   names the board and opens nothing.
#
#   WHAT IT CANNOT DO: refresh a board. It opens a file and nothing else -
#   no provider call, no gather, no ranking, no regeneration, no write - so
#   a board is as old as the timestamp it shows. The command that refreshes
#   one is /yngorchestrator board, in Claude Code: it gathers the board
#   fresh, writes it and opens it. Where Claude Code cannot be reached, a
#   whole run (/yngorchestrator <n>) writes one on its way past.
#
#   Which board, by the branch of the worktree the call is made in:
#
#       epic/<n>-...     that Epic's board, yngboard-<n>.html
#       slice/<n>-...    that slice's own board, yngboard-<n>.html
#       fix/<n>-...      that standalone issue's board, yngboard-<n>.html
#       no issue named   the most recently written yngboard-*.html
#
#   The branch names the issue directly: no run log is read to find one.
#   The last row is the project root, a worktree on main, a detached HEAD,
#   and any branch whose name does not start with an issue number.
#
#   With no board written for that issue, it says so in one line, names
#   /yngorchestrator board, and opens nothing. A branch that names an issue
#   never falls back to another issue's board: a board of the wrong issue
#   is worse than no board.
#
# ENVIRONMENT
#   YNGV_HTML_BROWSER   Whether a board is opened in the browser at all.
#                       Unset, empty, whitespace only, or any value other
#                       than 0, no, false or off: open it. 0 (or no, false,
#                       off): open nothing, and name the board's path so
#                       you have it. The value is matched with surrounding
#                       whitespace stripped and without regard to case, so
#                       "no ", " NO" and "no" all mean the same. That rule
#                       is stated in those same words in yngv.sh, yngv.ps1,
#                       yngboard.sh and yngboard.ps1, and the function
#                       applying it is character for character the same in
#                       each pair, so a reader comparing any two finds no
#                       difference to explain: one variable with four
#                       readers, and the defect #148 found was two of them
#                       drifting apart.
#
# REQUIREMENTS
#   - bash 3.2+ (the macOS default is fine), git, sed, tr, ls.
#   - yngv, beside this script or on PATH, to open a board in the browser.
#     yngorch installs the two together, into the same folder. With
#     YNGV_HTML_BROWSER off, nothing is opened and yngv is never needed.
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
#   0  the board was handed to yngv, or named because the browser is off
#   1  no board for this worktree's issue, no project around this folder,
#      or no yngv to open it with
#   2  an argument was given; yngboard takes none

set -u

usage() {
    # Print the header comment block (lines 2 up to the first non-comment line).
    sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

# The persisted default for HTML: the browser unless YNGV_HTML_BROWSER says no.
# The value is lower-cased and stripped of surrounding whitespace before it is
# matched, so 'no ', ' no' and 'NO' all mean no browser, as they do in yngv.sh,
# yngv.ps1 and yngboard.ps1; a value of whitespace only is left empty, and so
# means the browser. This function is yngv.sh's, character for character: four
# scripts read this one variable, and #148 was two of them reading it apart.
html_browser_wanted() {
    case "$(printf '%s' "${YNGV_HTML_BROWSER:-}" | tr '[:upper:]' '[:lower:]' \
            | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" in
        0|no|false|off) return 1 ;;
        *)              return 0 ;;
    esac
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

# 2. The issue from the branch, as locate.md's `continue` takes it: an
# Epic's, a slice's own and a standalone issue's number alike, since every
# board is named for the issue it is about. No branch, a detached HEAD and a
# branch like main all leave <n> empty.
branch=$(git branch --show-current 2>/dev/null)
n=$(printf '%s\n' "$branch" | sed -nE 's#^(epic|fix|slice)/([0-9]+)-.*#\2#p')

# 3. The board file itself: yngboard-<n>.html, or none at all. Another
# issue's board is not this worktree's, and a board of the wrong issue is
# worse than no board - a slice's Epic's board least of all, since it is the
# one a person in a slice worktree could mistake for theirs. Only a branch
# naming no issue falls back to the most recently written one.
board=""
why=""
if [ -n "$n" ]; then
    if [ -f "$boards/yngboard-$n.html" ]; then
        board="$boards/yngboard-$n.html"
        why="#$n"
    fi
else
    board=$(ls -t "$boards"/yngboard-*.html 2>/dev/null | sed -n 1p)
    [ -n "$board" ] && [ -f "$board" ] || board=""
    why="most recently written board"
fi

if [ -z "$board" ]; then
    if [ -n "$n" ]; then
        printf 'yngboard: no board written for #%s yet - write and open one: /yngorchestrator board\n' "$n" >&2
    else
        printf 'yngboard: no board written in %s yet - write and open one: /yngorchestrator board <issue>\n' "$boards" >&2
    fi
    exit 1
fi

# 4. Open it, unless YNGV_HTML_BROWSER says no. Opening is yngv's: it is
# beside this script, where yngorch puts the two together, else on PATH. The
# variable is read here rather than left to yngv, because "no browser" means
# something of yngboard's own - name the board, open nothing - and a board's
# source in a terminal is no use to anyone.
if html_browser_wanted; then
    browser=1
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
else
    browser=0
fi

printf 'yngboard: %s (%s; as of the timestamp on the page - /yngorchestrator board refreshes it)\n' "$board" "$why"

if [ "$browser" = 0 ]; then
    printf 'yngboard: YNGV_HTML_BROWSER is off: nothing was opened\n'
    exit 0
fi

"$@" "$board"
exit $?
