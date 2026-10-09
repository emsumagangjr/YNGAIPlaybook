<#
.SYNOPSIS
    Installs or upgrades the YNGAIPlaybook orchestrator in a project, without
    committing anything to it.

.DESCRIPTION
    Author:  Emeterio M. Sumagang Jr.
    Company: YNGSoftware (www.yngsoftware.com)

    Works with any project laid out as a bare repository with one folder per
    worktree (the "Bare Repository + Git Worktrees" pattern). Everything goes
    into the project root, beside .bare\, outside every worktree and outside
    Git:

        <project-root>\
        |-- .bare\info\exclude          + hides the links in every worktree
        |-- .shared\.claude\
        |   |-- skills\yngorchestrator\ the orchestrator skill
        |   `-- agents\slice-worker.md  the worker it dispatches
        |-- .yngorchestrator\
        |   |-- config.yml              merge rules (written only if absent)
        |   `-- runs\                   one run log per Epic
        |-- yngshared.ps1               links .shared\ into the worktrees
        `-- main\, epic-...\, ...       worktrees, linked file by file

    Steps, all safe to repeat:
      1. Find the project root from -Project (default: the current folder).
      2. Copy the skill and worker into .shared\.claude\ (upgrades in place).
      3. Write .yngorchestrator\config.yml from the template, only if absent.
      4. Add the two exclude lines to .bare\info\exclude, only if missing.
      5. Copy yngshared.ps1 into the project root and link every worktree.
      6. Create or update the workflow labels with gh, when gh is available.

    Upgrading from 1.1.0 (the skill was named "orchestrate"): step 3 moves
    .orchestrator\ to .yngorchestrator\, keeping your config and run logs
    (when both exist it leaves both and warns), and steps 2, 4 and 5 remove
    the old skill folder, its exclude line and its links in every worktree.

    Run it again after creating a worktree, or to upgrade: it re-links every
    worktree and never overwrites your config.

    REQUIREMENTS
    - Windows PowerShell 5.1 or PowerShell 7+, on Windows.
    - Git on PATH.
    - Developer Mode or an elevated shell, for yngshared's symbolic links.
    - Optional: gh, authenticated, for the labels.

.PARAMETER Project
    Any folder inside the project: the root, or any worktree. Default: the
    current folder.

.PARAMETER SkipLabels
    Do not touch the repository's labels.

.EXAMPLE
    F:\YNGAIPlaybook\scripts\yngorch.ps1
    From anywhere inside the project: install, or upgrade.

.EXAMPLE
    F:\YNGAIPlaybook\scripts\yngorch.ps1 -Project D:\code\myproject
#>
[CmdletBinding()]
param(
    [string]$Project = (Get-Location).Path,
    [switch]$SkipLabels
)

$ErrorActionPreference = 'Stop'
$playbook = Split-Path -Parent $PSScriptRoot

function Step([string]$Status, [string]$Text) { Write-Host ("  {0,-8} {1}" -f $Status, $Text) }

# 1. The project root: the folder holding .bare\. From the root itself git
# fails; Windows PowerShell 5.1 turns that into a terminating error, hence try.
$common = try { & git -C $Project rev-parse --path-format=absolute --git-common-dir 2>$null } catch { $null }
if (-not $common -and (Test-Path (Join-Path $Project '.bare'))) { $common = Join-Path $Project '.bare' }
if (-not $common -or (Split-Path -Leaf $common) -ne '.bare') {
    throw "Not inside a bare-repository project (no .bare\ found from '$Project'). See guides/epic-workflow.md, sections 7-8."
}
$root = Split-Path -Parent ([IO.Path]::GetFullPath($common))
Write-Host "YNG Orchestrator -> $root"

# 2. Skill and worker into .shared\.claude\.
$skillDir = Join-Path $root '.shared\.claude\skills\yngorchestrator'
$agentDir = Join-Path $root '.shared\.claude\agents'
New-Item -ItemType Directory -Force $skillDir, $agentDir | Out-Null
Copy-Item -Force (Join-Path $playbook 'skills\yngorchestrator\*') $skillDir
Copy-Item -Force (Join-Path $playbook 'agents\slice-worker.md') $agentDir
Step 'copied' '.shared\.claude\skills\yngorchestrator\, .shared\.claude\agents\slice-worker.md'
# The 1.1.0 skill folder, which only this installer writes.
$oldSkill = Join-Path $root '.shared\.claude\skills\orchestrate'
if (Test-Path $oldSkill) { Remove-Item -Recurse -Force $oldSkill; Step 'removed' '.shared\.claude\skills\orchestrate\ (renamed yngorchestrator)' }

# 3. Config, only if absent; run logs folder. A 1.1.0 .orchestrator\ moves here.
$orch = Join-Path $root '.yngorchestrator'
$oldOrch = Join-Path $root '.orchestrator'
if (Test-Path $oldOrch) {
    if (Test-Path $orch) { Step 'warning' 'both .orchestrator\ and .yngorchestrator\ exist; left both, move what you need by hand' }
    else { Move-Item $oldOrch $orch; Step 'moved' '.orchestrator\ -> .yngorchestrator\ (config and run logs kept)' }
}
New-Item -ItemType Directory -Force (Join-Path $orch 'runs') | Out-Null
$config = Join-Path $orch 'config.yml'
if (Test-Path $config) { Step 'kept' '.yngorchestrator\config.yml (yours)' }
else { Copy-Item (Join-Path $playbook 'templates\orchestrator-config.yml') $config; Step 'created' '.yngorchestrator\config.yml (every path required)' }

# 4. Exclude lines, only if missing; the 1.1.0 line goes.
$exclude = Join-Path $root '.bare\info\exclude'
New-Item -ItemType Directory -Force (Split-Path $exclude) | Out-Null
$have = if (Test-Path $exclude) { @(Get-Content $exclude) } else { @() }
$oldLine = '/.claude/skills/orchestrate/'
if ($oldLine -in $have) {
    $have = @($have | Where-Object { $_ -ne $oldLine })
    Set-Content $exclude $have; Step 'removed' ".bare\info\exclude: $oldLine"
}
$add = @('/.claude/skills/yngorchestrator/', '/.claude/agents/slice-worker.md') | Where-Object { $_ -notin $have }
if ($add) { Add-Content $exclude $add; Step 'added' ".bare\info\exclude: $($add -join ', ')" }
else { Step 'kept' '.bare\info\exclude' }

# 5. Remove the 1.1.0 skill links from every worktree (links only; a real
# file is left with a warning), then link every worktree through yngshared,
# which must sit at the project root.
$worktrees = & git --git-dir=$common worktree list --porcelain |
    Where-Object { $_ -like 'worktree *' } | ForEach-Object { $_.Substring(9) }
foreach ($wt in $worktrees) {
    $dir = Join-Path $wt '.claude\skills\orchestrate'
    if (-not (Test-Path $dir)) { continue }
    $kept = 0
    foreach ($item in Get-ChildItem -Force $dir) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $item.Delete() }
        else { $kept++ }
    }
    if ($kept) { Step 'warning' "$dir holds $kept real file(s); left in place" }
    else { Remove-Item -Force $dir; Step 'removed' "$dir (old links)" }
}

$yngshared = Join-Path $root 'yngshared.ps1'
Copy-Item -Force (Join-Path $PSScriptRoot 'yngshared.ps1') $yngshared
$out = & $yngshared -link -All 6>&1 | ForEach-Object { "$_" }
$out | Where-Object { $_ -match '^(warn|error)\b' } | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
if ($LASTEXITCODE -ne 0) { Step 'warning' 'yngshared reported problems above (symlinks need Developer Mode or an elevated shell)' }
else { Step 'linked' 'every worktree (yngshared -link -All)' }

# 6. Labels, when gh is available.
if ($SkipLabels) { Step 'skipped' 'labels (-SkipLabels)' }
elseif (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Step 'skipped' 'labels (gh not found)' }
else {
    $url = try { & git --git-dir=$common remote get-url origin 2>$null } catch { $null }
    if (-not $url) { Step 'skipped' 'labels (no origin remote)' }
    else {
        $repo = $url -replace '\.git$', ''
        $labels = @(
            @('epic',                     '3e4b9e', 'Feature: tracker card plus integration branch'),
            @('workflow:needs-triage',    'fbca04', 'Triage fills in every label'),
            @('workflow:needs-info',      'd876e3', 'A person must answer before work starts'),
            @('workflow:ready-for-agent', '0e8a16', 'Gate 1 passed: an agent may pick it up (set by a person only)'),
            @('workflow:ready-for-human', '1d76db', 'Gate 1 passed: a person picks it up'),
            @('workflow:in-progress',     'c5def5', 'Being worked; no PR yet (set by the dispatcher)'),
            @('workflow:in-review',       '5319e7', 'PR open, waiting for a person (set by the dispatcher)'))
        $failed = 0
        foreach ($l in $labels) {
            & gh label create $l[0] -R $repo -c $l[1] -d $l[2] --force 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) { $failed++ }
        }
        if ($failed) { Step 'warning' "labels: $failed of $($labels.Count) failed (is gh logged in? gh auth status)" }
        else { Step 'labels' "$($labels.Count) created or updated on $repo" }
    }
}

Write-Host ''
Write-Host 'Done. Next:'
Write-Host "  - Set your merge rules in $config"
Write-Host '  - From an Epic worktree, start Claude Code and run: /yngorchestrator <epic issue>'
Write-Host '  - After creating a new worktree, run this script again to link it.'
