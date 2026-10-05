#!/usr/bin/env bash
#
# yngv - view a file in the terminal, rendered according to its type.
#
#   Name:     yngv.sh
#   Version:  1.1.0
#   Created:  2026-09-19
#   Author:   Emeterio M. Sumagang Jr.
#   Company:  YNGSoftware (www.yngsoftware.com)
#
# macOS / Linux counterpart of yngv.ps1.
#
# DESCRIPTION
#   Detects the file extension and renders it accordingly. Markdown (.md,
#   .markdown) opens rendered as HTML in your default web browser, using the
#   first of these that is installed:
#       1. pwsh (PowerShell 7+)  -> Show-Markdown -UseBrowser
#       2. pandoc                -> converts to a temporary HTML file
#   If neither is installed it falls back to an ANSI-styled rendering in the
#   terminal. Any unrecognized file type is shown as plain text (the default).
#
# REQUIREMENTS
#   - bash 3.2+ (the macOS default is fine), awk, sed.
#   - For the browser view: pwsh OR pandoc, plus 'open' (macOS) or 'xdg-open'
#     (Linux). Without them markdown still displays via the console renderer.
#
# INSTALL
#   1. Copy this file to a folder on your PATH, dropping the extension so the
#      bare command works, and make it executable:
#          cp yngv.sh ~/.local/bin/yngv
#          chmod +x ~/.local/bin/yngv
#   2. Make sure that folder is on your PATH (add to ~/.zshrc or ~/.bashrc):
#          export PATH="$HOME/.local/bin:$PATH"
#      Open a new terminal afterwards.
#
# RUN
#   yngv <file>            renders based on the file extension
#   yngv notes.md          markdown -> opens in the browser
#   yngv notes.md -c       markdown -> ANSI-styled in this terminal
#   yngv notes.md -r       any file -> plain text
#   yngv -h                show this help
#
# EXTENDING
#   Add a case to the 'case "$ext"' block at the bottom of this script that
#   calls a new show_<type> function, following the pattern of show_markdown_*.

set -u

usage() {
    # Print the header comment block (lines 2 up to the first non-comment line).
    sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

RAW=0
CONSOLE=0
FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        -r|--raw)     RAW=1 ;;
        -c|--console) CONSOLE=1 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           echo "yngv: unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)
            if [ -n "$FILE" ]; then
                echo "yngv: only one file at a time" >&2; exit 2
            fi
            FILE="$1"
            ;;
    esac
    shift
done

if [ -z "$FILE" ]; then
    echo "yngv: no file given" >&2
    usage >&2
    exit 2
fi

if [ ! -f "$FILE" ]; then
    echo "yngv: file not found: $FILE" >&2
    exit 1
fi

# Absolute path (pwsh and browsers need one).
FILE_DIR=$(cd "$(dirname "$FILE")" && pwd -P)
ABS_FILE="$FILE_DIR/$(basename "$FILE")"

# Lower-cased extension including the dot; empty when there is none.
base=$(basename "$FILE")
name_no_lead_dot="${base#.}"
case "$name_no_lead_dot" in
    *.*) ext=".$(printf '%s' "${base##*.}" | tr '[:upper:]' '[:lower:]')" ;;
    *)   ext="" ;;
esac

show_raw() {
    cat -- "$1"
}

# Open a file or URL with the platform's default handler.
open_default() {
    if command -v open >/dev/null 2>&1; then
        open "$1"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$1" >/dev/null 2>&1
    else
        return 1
    fi
}

# Returns 0 when it managed to open the browser, 1 when no converter/opener exists.
show_markdown_browser() {
    local file="$1"
    if command -v pwsh >/dev/null 2>&1; then
        local escaped=${file//\'/\'\'}
        pwsh -NoProfile -Command "Show-Markdown -Path '$escaped' -UseBrowser"
        return 0
    fi
    if command -v pandoc >/dev/null 2>&1; then
        local tmp
        tmp=$(mktemp "${TMPDIR:-/tmp}/yngv.XXXXXX") || return 1
        mv "$tmp" "$tmp.html"; tmp="$tmp.html"
        pandoc -f gfm -t html5 -s --metadata "title=$(basename "$file")" -o "$tmp" "$file" || return 1
        open_default "$tmp" || return 1
        return 0
    fi
    return 1
}

# ANSI-styled markdown in the terminal (headers, bold/italic, inline code,
# links, code fences, lists, quotes, rules).
show_markdown_console() {
    awk '
    function wrap(s, re, d, pre, post,    out, t) {
        out = ""
        while (match(s, re)) {
            t = substr(s, RSTART + d, RLENGTH - 2 * d)
            out = out substr(s, 1, RSTART - 1) pre t post
            s = substr(s, RSTART + RLENGTH)
        }
        return out s
    }
    function links(s,    out, t, txt, url, p) {
        out = ""
        while (match(s, /\[[^]]+\]\([^)]+\)/)) {
            t = substr(s, RSTART, RLENGTH)
            p = index(t, "](")
            txt = substr(t, 2, p - 2)
            url = substr(t, p + 2, length(t) - p - 2)
            out = out substr(s, 1, RSTART - 1) UL BLUE txt RESET DIM " (" url ")" RESET
            s = substr(s, RSTART + RLENGTH)
        }
        return out s
    }
    function inline(s) {
        s = wrap(s, "\\*\\*[^*]+\\*\\*", 2, BOLD, RESET)
        s = wrap(s, "__[^_]+__", 2, BOLD, RESET)
        s = wrap(s, "\\*[^*]+\\*", 1, ITAL, RESET)
        s = wrap(s, "`[^`]+`", 1, YEL, RESET)
        return links(s)
    }
    function rule(    i, r) { r = ""; for (i = 0; i < 60; i++) r = r "-"; return GRAY DIM r RESET }
    BEGIN {
        ESC = sprintf("%c", 27)
        RESET = ESC "[0m"; BOLD = ESC "[1m"; DIM = ESC "[2m"; ITAL = ESC "[3m"; UL = ESC "[4m"
        CYAN = ESC "[36m"; YEL = ESC "[33m"; GREEN = ESC "[32m"; BLUE = ESC "[34m"; GRAY = ESC "[90m"
        incode = 0
    }
    {
        line = $0
        sub(/\r$/, "", line)

        if (line ~ /^[ \t]*```/) { incode = !incode; print rule(); next }
        if (incode) { print YEL "  " line RESET; next }

        if (match(line, /^#+[ \t]+/)) {
            level = 0
            while (substr(line, level + 1, 1) == "#") level++
            if (level <= 6) {
                text = inline(substr(line, RLENGTH + 1))
                if (level == 1)      { print ""; print BOLD UL CYAN text RESET; print "" }
                else if (level == 2) { print ""; print BOLD CYAN text RESET }
                else                 { print BOLD BLUE text RESET }
                next
            }
        }
        if (line ~ /^[ \t]*>/) { sub(/^[ \t]*>[ \t]?/, "", line); print GRAY ITAL "| " inline(line) RESET; next }
        if (line ~ /^[ \t]*(-{3,}|\*{3,}|_{3,})[ \t]*$/) { print rule(); next }
        if (match(line, /^[ \t]*[-*+][ \t]+/)) {
            ind = line; sub(/[-*+][ \t]+.*$/, "", ind)
            print ind GREEN "*" RESET " " inline(substr(line, RLENGTH + 1)); next
        }
        if (match(line, /^[ \t]*[0-9]+\.[ \t]+/)) {
            head = substr(line, 1, RLENGTH); rest = substr(line, RLENGTH + 1)
            sub(/[ \t]+$/, "", head)
            print GREEN head RESET " " inline(rest); next
        }
        if (line ~ /^[ \t]*$/) { print ""; next }
        print inline(line)
    }' "$1"
}

if [ "$RAW" -eq 1 ]; then
    show_raw "$ABS_FILE"
    exit 0
fi

case "$ext" in
    .md|.markdown)
        if [ "$CONSOLE" -eq 1 ]; then
            show_markdown_console "$ABS_FILE"
        elif ! show_markdown_browser "$ABS_FILE"; then
            printf '\033[90m(no pwsh/pandoc/browser opener found - using the console renderer)\033[0m\n\n'
            show_markdown_console "$ABS_FILE"
        fi
        ;;
    *)
        # Unrecognized extension - view as plain text by design, not as an error.
        show_raw "$ABS_FILE"
        ;;
esac
