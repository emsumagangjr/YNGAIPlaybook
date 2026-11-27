<#
.SYNOPSIS
    Open this worktree's run board.
.DESCRIPTION
    A run board is one HTML file for one issue, written by /yngorchestrator
    into <root>\.yngaiplaybook\yngboard-<issue>.html: an Epic's board, a
    slice's own board, or a standalone issue's. yngboard finds the board of
    the issue this worktree's branch names and hands it to yngv, which opens
    it in the default browser - unless YNGV_HTML_BROWSER is off, when it
    names the board and opens nothing.

    WHAT IT CANNOT DO: refresh a board. It opens a file and nothing else -
    no provider call, no gather, no ranking, no regeneration, no write - so
    a board is as old as the timestamp it shows. The command that refreshes
    one is /yngorchestrator board, in Claude Code: it gathers the board
    fresh, writes it and opens it. Where Claude Code cannot be reached, a
    whole run (/yngorchestrator <n>) writes one on its way past.

    Which board, by the branch of the worktree the call is made in:

        epic/<n>-...     that Epic's board, yngboard-<n>.html
        slice/<n>-...    that slice's own board, yngboard-<n>.html
        fix/<n>-...      that standalone issue's board, yngboard-<n>.html
        no issue named   the most recently written yngboard-*.html

    The branch names the issue directly: no run log is read to find one.
    The last row is the project root, a worktree on main, a detached HEAD,
    and any branch whose name does not start with an issue number.

    With no board written for that issue, it says so in one line, names
    /yngorchestrator board, and opens nothing. A branch that names an issue
    never falls back to another issue's board: a board of the wrong issue
    is worse than no board.
.PARAMETER Help
    Show this help.
.EXAMPLE
    yngboard
    From any folder in a worktree: open that worktree's board.
.NOTES
    Name:         yngboard
    Version:      1.0.0
    Created:      2026-11-25
    Author:       Emeterio M. Sumagang Jr.
    Company:      YNGSoftware (www.yngsoftware.com)

    Windows counterpart of yngboard.sh. The two behave alike, message for
    message.

    REQUIREMENTS
    - Windows PowerShell 5.1 or PowerShell 7+, and Git on PATH.
    - yngv, beside this script or on PATH, to open a board in the browser.
      yngorch installs the two together, into the same folder. With
      YNGV_HTML_BROWSER off, nothing is opened and yngv is never needed.

    INSTALL
    yngorch installs it: yngboard.ps1 and a yngboard.cmd shim beside
    yngv in -BinDir, which it puts on your user PATH.

    ENVIRONMENT
    YNGV_HTML_BROWSER   Whether a board is opened in the browser at all.
                        Unset, empty, whitespace only, or any value other
                        than 0, no, false or off: open it. 0 (or no, false,
                        off): open nothing, and name the board's path so
                        you have it. The value is matched with surrounding
                        whitespace stripped and without regard to case, so
                        "no ", " NO" and "no" all mean the same. That rule
                        is stated in those same words in yngv.sh, yngv.ps1,
                        yngboard.sh and yngboard.ps1, and the function
                        applying it is character for character the same in
                        each pair, so a reader comparing any two finds no
                        difference to explain: one variable with four
                        readers, and the defect #148 found was two of them
                        drifting apart.

    EXIT
    0  the board was handed to yngv, or named because the browser is off
    1  no board for this worktree's issue, no project around this folder,
       or no yngv to open it with
    2  an argument was given; yngboard takes none
#>
[CmdletBinding()]
param(
    [Alias('h')]
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

# One line, on standard error, then the exit code: the whole of what this
# script says when it cannot open a board.
function Stop-Yngboard([string]$Message, [int]$Code) {
    [Console]::Error.WriteLine($Message)
    exit $Code
}

# The persisted default for HTML: the browser unless YNGV_HTML_BROWSER switches
# it off. This function is yngv.ps1's, character for character: four scripts
# read this one variable, and #148 was two of them reading it apart.
function Test-HtmlBrowserWanted {
    $value = $env:YNGV_HTML_BROWSER
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $true
    }
    return $value.Trim().ToLowerInvariant() -notin '0', 'no', 'false', 'off'
}

if ($Help) {
    Get-Help -Full $PSCommandPath
    exit 0
}
if ($Rest) {
    # The message and the usage, both on standard error, as yngboard.sh does.
    [Console]::Error.WriteLine("yngboard: takes no argument, and was given: $($Rest[0])")
    [Console]::Error.Write((Get-Help -Full $PSCommandPath | Out-String))
    exit 2
}

# Git's first line of output, or '' when the command fails. Native stderr is
# dropped rather than turned into an error record, so a folder outside a
# repository is an empty answer, not a failure.
function Get-GitLine([string[]]$Arguments) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $out = & git @Arguments 2>$null
    $ErrorActionPreference = $previous
    if ($LASTEXITCODE -ne 0) { return '' }
    return ([string](@($out)[0])).Trim()
}

# 1. The project root, as step 1 of locate.md finds it: the folder holding
# .bare\, which Git names inside a worktree and which is the folder itself
# at the root, where the session is outside Git.
$root = ''
$common = Get-GitLine @('rev-parse', '--path-format=absolute', '--git-common-dir')
if ($common) { $root = Split-Path -Parent $common }    # <root>\.bare -> <root>
elseif (Test-Path -LiteralPath (Join-Path (Get-Location).ProviderPath '.bare') -PathType Container) {
    $root = (Get-Location).ProviderPath                # the call was made at the root
}
if (-not $root -or -not (Test-Path -LiteralPath (Join-Path $root '.bare') -PathType Container)) {
    Stop-Yngboard 'yngboard: not inside a project laid out as a bare repository with worktrees (no .bare/ found)' 1
}
$root = (Resolve-Path -LiteralPath $root).ProviderPath
$boards = Join-Path $root '.yngaiplaybook'

# 2. The issue from the branch, as locate.md's `continue` takes it: an
# Epic's, a slice's own and a standalone issue's number alike, since every
# board is named for the issue it is about. No branch, a detached HEAD and a
# branch like main all leave <n> empty.
$branch = Get-GitLine @('branch', '--show-current')
$n = ''
if ($branch -match '^(epic|fix|slice)/([0-9]+)-') { $n = $Matches[2] }

# 3. The board file itself: yngboard-<n>.html, or none at all. Another
# issue's board is not this worktree's, and a board of the wrong issue is
# worse than no board - a slice's Epic's board least of all, since it is the
# one a person in a slice worktree could mistake for theirs. Only a branch
# naming no issue falls back to the most recently written one.
$board = ''
$why = ''
if ($n) {
    $candidate = Join-Path $boards ('yngboard-{0}.html' -f $n)
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $board = $candidate
        $why = "#$n"
    }
} else {
    $newest = Get-ChildItem -LiteralPath $boards -Filter 'yngboard-*.html' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($newest) { $board = $newest.FullName }
    $why = 'most recently written board'
}

if (-not $board) {
    if ($n) {
        Stop-Yngboard ('yngboard: no board written for #{0} yet - write and open one: /yngorchestrator board' -f $n) 1
    }
    Stop-Yngboard ('yngboard: no board written in {0} yet - write and open one: /yngorchestrator board <issue>' -f $boards) 1
}

# 4. Open it, unless YNGV_HTML_BROWSER says no. Opening is yngv's: it is
# beside this script, where yngorch puts the two together, else on PATH. The
# variable is read here rather than left to yngv, because "no browser" means
# something of yngboard's own - name the board, open nothing - and a board's
# source in a terminal is no use to anyone.
$browser = Test-HtmlBrowserWanted
$yngv = ''
if ($browser) {
    $beside = Join-Path $PSScriptRoot 'yngv.ps1'
    if (Test-Path -LiteralPath $beside -PathType Leaf) { $yngv = $beside }
    else {
        # Source is the path for a command on PATH, and empty for a function
        # or an alias someone has defined; its name runs either way.
        $found = Get-Command yngv -ErrorAction SilentlyContinue
        if ($found) { $yngv = if ($found.Source) { $found.Source } else { $found.Name } }
    }
    if (-not $yngv) {
        Stop-Yngboard ('yngboard: yngv not found beside this script or on PATH - open it yourself: {0}' -f $board) 1
    }
}

Write-Host ('yngboard: {0} ({1}; as of the timestamp on the page - /yngorchestrator board refreshes it)' -f $board, $why)

if (-not $browser) {
    Write-Host 'yngboard: YNGV_HTML_BROWSER is off: nothing was opened'
    exit 0
}

$LASTEXITCODE = 0
& $yngv $board
exit $LASTEXITCODE
