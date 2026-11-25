<#
.SYNOPSIS
    Open this worktree's run board.
.DESCRIPTION
    A run board is one HTML file for one run log, written by
    /yngorchestrator at every run-log event into
    <root>\.yngaiplaybook\yngboard-<n>.html. It shows every slice of the
    Epic, each slice's state, and whether each needs a person. yngboard
    finds the board this worktree belongs to and hands it to yngv, which
    opens it in the default browser - unless YNGV_HTML_BROWSER is off, when
    it names the board and opens nothing.

    It opens a file and nothing else: no provider call, no gather, no
    ranking, no regeneration, no write. A board is as old as the timestamp
    it shows, and a run is what refreshes it.

    Which board, by the branch of the worktree the call is made in:

        epic/<n>-...     that Epic's own board, run log <n>
        slice/<n>-...    its Epic's board: the run log holding #<n>'s events
        fix/<n>-...      that standalone issue's own board, run log <n>
        no issue named   the most recently written yngboard-*.html

    The last row is the project root, a worktree on main, a detached HEAD,
    and any branch whose name does not start with an issue number.

    With no board written for that log, it says so in one line, names the
    run that would write one, and opens nothing. A branch that names an
    issue never falls back to another log's board: a board of the wrong
    Epic is worse than no board.
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
    1  no board for this worktree's log, no project around this folder,
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

# 2. <n> from the branch, as locate.md's `continue` takes it. No branch, a
# detached HEAD and a branch like main all leave both empty.
$branch = Get-GitLine @('branch', '--show-current')
$kind = ''
$n = ''
if ($branch -match '^(epic|fix|slice)/([0-9]+)-') { $kind = $Matches[1]; $n = $Matches[2] }

# 3. The run log the board is named for: an Epic's and a standalone issue's
# own number, a slice's its Epic's (SKILL.md, Run log). A slice's Epic is
# the log holding the slice's own events, which is a local file read: no
# provider call finds it.
$log = ''
if ($kind -eq 'epic' -or $kind -eq 'fix') { $log = $n }
elseif ($kind -eq 'slice') {
    $pattern = '^[^ ]+ #{0}(\s|$)' -f $n
    $logs = @(Get-ChildItem -LiteralPath (Join-Path $boards 'yngorchestratorruns') `
            -Filter '*.md' -File -ErrorAction SilentlyContinue | Sort-Object Name)
    foreach ($file in $logs) {
        if (Select-String -LiteralPath $file.FullName -Pattern $pattern -Quiet) {
            $log = $file.BaseName
            break
        }
    }
}

# 4. The board file itself. A branch that names an issue gets that issue's
# log's board or none at all: another log's board is not this worktree's,
# and a board of the wrong Epic is worse than no board. Only a branch naming
# no issue falls back to the most recently written one.
$board = ''
$why = ''
if ($n) {
    if ($log) {
        $candidate = Join-Path $boards ('yngboard-{0}.html' -f $log)
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $board = $candidate
            $why = "run log $log"
        }
    }
} else {
    $newest = Get-ChildItem -LiteralPath $boards -Filter 'yngboard-*.html' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($newest) { $board = $newest.FullName }
    $why = 'most recently written board'
}

if (-not $board) {
    if ($n) {
        Stop-Yngboard ('yngboard: no board written for #{0} yet - start a run to write one: /yngorchestrator {0}' -f $n) 1
    }
    Stop-Yngboard ('yngboard: no board written in {0} yet - start a run to write one: /yngorchestrator <issue>' -f $boards) 1
}

# 5. Open it, unless YNGV_HTML_BROWSER says no. Opening is yngv's: it is
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

Write-Host ('yngboard: {0} ({1}; as of the timestamp on the page - a run refreshes it)' -f $board, $why)

if (-not $browser) {
    Write-Host 'yngboard: YNGV_HTML_BROWSER is off: nothing was opened'
    exit 0
}

$LASTEXITCODE = 0
& $yngv $board
exit $LASTEXITCODE
