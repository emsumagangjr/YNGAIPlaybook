<#
.SYNOPSIS
    View a file, rendered according to its type.
.DESCRIPTION
    Detects the file extension and renders it accordingly. Markdown (.md, .markdown)
    opens rendered as HTML in your default web browser, via PowerShell 7's built-in
    Show-Markdown -UseBrowser (auto-hopping into pwsh if run from Windows PowerShell
    5.1, which doesn't ship that cmdlet). If pwsh isn't available at all, it falls
    back to an ANSI-styled rendering in the console. Unknown extensions fall back to
    plain text. New renderers can be added by adding a case to the switch statement
    at the bottom of this file.
.PARAMETER Path
    Path to the file to view.
.PARAMETER Raw
    Force plain-text output regardless of file extension.
.PARAMETER Console
    Force the ANSI-styled in-console renderer for markdown instead of opening it
    in the browser.
.EXAMPLE
    yngv README.md
.EXAMPLE
    yngv notes.md -Raw
.EXAMPLE
    yngv notes.md -Console
.NOTES
    Name:         yngv
    Version:      1.1.0
    Created:      2026-09-19
    Author:       Emeterio M. Sumagang Jr.
    Company:      YNGSoftware (www.yngsoftware.com)

    REQUIREMENTS
    - Windows PowerShell 5.1 or later (works standalone; falls back to the
      console renderer for markdown).
    - PowerShell 7+ (pwsh) recommended for the default browser view, since
      it supplies the Show-Markdown -UseBrowser cmdlet this script calls.
      Without pwsh on PATH, markdown still displays fine via the built-in
      console renderer.

    INSTALL
    1. Save this file as yngv.ps1 in a folder that is on your PATH,
       e.g. C:\Users\<you>\.local\bin\yngv.ps1
    2. (Recommended) Add a yngv.cmd shim next to it in the same folder,
       so the bare command "yngv" resolves from cmd.exe, PowerShell and
       bash alike, not just PowerShell's own script resolution:

           @echo off
           powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0yngv.ps1" %*

    3. Make sure that folder is on your PATH:
           [Environment]::SetEnvironmentVariable(
               'Path',
               "$([Environment]::GetEnvironmentVariable('Path','User'));C:\Users\<you>\.local\bin",
               'User'
           )
       Open a new terminal afterwards so it picks up the updated PATH.

    RUN
        yngv <path-to-file>              # renders based on extension
        yngv notes.md                    # markdown -> opens in browser
        yngv notes.md -Console           # markdown -> ANSI in this console
        yngv notes.md -Raw               # any file -> plain text
        yngv file.unknownext             # unrecognized type -> plain text (the default)

    EXTENDING
    To support another file type, add a case to the switch statement at
    the bottom of this script that dispatches to a new Show-<Type>File
    function, following the same pattern as Show-MarkdownFile.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,

    [switch]$Raw,

    [switch]$Console
)

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Error "File not found: $Path"
    exit 1
}

$resolvedPath = (Resolve-Path -LiteralPath $Path).ProviderPath
$extension = [System.IO.Path]::GetExtension($resolvedPath).ToLowerInvariant()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # Not all hosts allow changing OutputEncoding (e.g. some redirected/non-interactive hosts); ignore.
}

$esc = [char]27
$reset = "$esc[0m"
$bold = "$esc[1m"
$dim = "$esc[2m"
$italic = "$esc[3m"
$underline = "$esc[4m"

$fg = @{
    Cyan    = "$esc[36m"
    Yellow  = "$esc[33m"
    Green   = "$esc[32m"
    Blue    = "$esc[34m"
    Gray    = "$esc[90m"
}

function Format-InlineMarkdown {
    param([string]$Text)

    $Text = [regex]::Replace($Text, '\*\*(.+?)\*\*', { param($m) "$bold$($m.Groups[1].Value)$reset" })
    $Text = [regex]::Replace($Text, '__(.+?)__', { param($m) "$bold$($m.Groups[1].Value)$reset" })
    $Text = [regex]::Replace($Text, '(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', { param($m) "$italic$($m.Groups[1].Value)$reset" })
    $Text = [regex]::Replace($Text, '`([^`]+?)`', { param($m) "$($fg.Yellow)$($m.Groups[1].Value)$reset" })
    $Text = [regex]::Replace($Text, '\[(.+?)\]\((.+?)\)', { param($m) "$underline$($fg.Blue)$($m.Groups[1].Value)$reset$dim ($($m.Groups[2].Value))$reset" })

    return $Text
}

function Show-MarkdownFile {
    param([string]$FilePath)

    $lines = Get-Content -LiteralPath $FilePath -Encoding UTF8
    $inCodeBlock = $false
    $ruleLine = "$($fg.Gray)$dim" + ('-' * 60) + $reset

    foreach ($line in $lines) {

        if ($line -match '^\s*```') {
            $inCodeBlock = -not $inCodeBlock
            Write-Host $ruleLine
            continue
        }

        if ($inCodeBlock) {
            Write-Host "$($fg.Yellow)  $line$reset"
            continue
        }

        if ($line -match '^(#{1,6})\s+(.*)$') {
            $level = $matches[1].Length
            $text = Format-InlineMarkdown $matches[2]
            if ($level -eq 1) {
                Write-Host ""
                Write-Host "$bold$underline$($fg.Cyan)$text$reset"
                Write-Host ""
            } elseif ($level -eq 2) {
                Write-Host ""
                Write-Host "$bold$($fg.Cyan)$text$reset"
            } else {
                Write-Host "$bold$($fg.Blue)$text$reset"
            }
            continue
        }

        if ($line -match '^\s*>\s?(.*)$') {
            Write-Host "$($fg.Gray)$italic| $(Format-InlineMarkdown $matches[1])$reset"
            continue
        }

        if ($line -match '^\s*([-*_]){3,}\s*$') {
            Write-Host $ruleLine
            continue
        }

        if ($line -match '^(\s*)[-*+]\s+(.*)$') {
            Write-Host "$($matches[1])$($fg.Green)*$reset $(Format-InlineMarkdown $matches[2])"
            continue
        }

        if ($line -match '^(\s*)(\d+\.)\s+(.*)$') {
            Write-Host "$($matches[1])$($fg.Green)$($matches[2])$reset $(Format-InlineMarkdown $matches[3])"
            continue
        }

        if ($line.Trim() -eq '') {
            Write-Host ""
        } else {
            Write-Host (Format-InlineMarkdown $line)
        }
    }
}

function Show-RawFile {
    param([string]$FilePath)
    Get-Content -LiteralPath $FilePath -Encoding UTF8 | ForEach-Object { Write-Host $_ }
}

function Show-MarkdownInBrowser {
    param([string]$FilePath)

    if (Get-Command Show-Markdown -ErrorAction SilentlyContinue) {
        # Already running in pwsh (PowerShell 7+), which ships Show-Markdown natively.
        Show-Markdown -Path $FilePath -UseBrowser
        return $true
    }

    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwshCmd) {
        return $false
    }

    # Running under Windows PowerShell 5.1, which doesn't have Show-Markdown; hop into pwsh for it.
    & $pwshCmd.Source -NoProfile -Command "Show-Markdown -Path '$FilePath' -UseBrowser"
    return $true
}

if ($Raw) {
    Show-RawFile -FilePath $resolvedPath
    exit 0
}

switch ($extension) {
    { $_ -in '.md', '.markdown' } {
        if ($Console) {
            Show-MarkdownFile -FilePath $resolvedPath
        } else {
            $opened = Show-MarkdownInBrowser -FilePath $resolvedPath
            if (-not $opened) {
                Write-Host "$($fg.Gray)(pwsh not found - falling back to console renderer; install PowerShell 7 for the browser view)$reset"
                Write-Host ""
                Show-MarkdownFile -FilePath $resolvedPath
            }
        }
    }
    default {
        # Unrecognized extension - view as plain text by design, not as an error.
        Show-RawFile -FilePath $resolvedPath
    }
}
