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
        |-- .yngaiplaybook\             the playbook's files for this project
        |   |-- README.md               the folder explained (rewritten every run)
        |   |-- yngorchestratorconfig.yml  issues repo, auto-promote, merge rules (yours; new settings added)
        |   `-- yngorchestratorruns\    one run log per Epic, and run locks
        |-- .claude\                    linked from .shared\.claude\, for a session at the root
        |-- yngshared.ps1               links .shared\ into the worktrees
        `-- main\, epic-...\, ...       worktrees, linked file by file

    Steps, all safe to repeat:
      1. Find the project root from -Project (default: the current folder).
      2. Copy the skill and worker into .shared\.claude\ (upgrades in place).
      3. Fill .yngaiplaybook\: yngorchestratorconfig.yml from the template
         when absent; when present, add the settings and keys the template
         has and it lacks, changing no line, after a backup to
         yngorchestratorconfig.yml.bak; yngorchestratorruns\; README.md from
         the template.
         With -IssuesRepo, write the config's issues: key, only if it has
         no value yet; an existing value is kept and reported.
      4. Add the two exclude lines to .bare\info\exclude, only if missing.
      5. Copy yngshared.ps1 into the project root and link every worktree,
         and .shared\.claude\ into the root's own .claude\.
      6. Create or update the workflow labels with gh, when gh is available,
         in the issues repo: -IssuesRepo, else the config's issues: value,
         else origin's repo.
      7. Copy yngv, the file viewer, into -BinDir and put it on your user
         PATH, only if missing. Per user, not per project.

    Upgrading from 1.1.0-1.4.0: step 3 moves .yngorchestrator\ (1.2.0-1.4.0)
    or .orchestrator\ (1.1.0) into .yngaiplaybook\, one line per item:
    config.yml becomes yngorchestratorconfig.yml, runs\ becomes
    yngorchestratorruns\, any other file keeps its name, and the emptied old
    folder goes. When .yngaiplaybook\ already exists, or both old folders do,
    it moves nothing, leaves each folder as it is, and warns: move what you
    need by hand. From 1.1.0 (the skill was named "orchestrate"), steps 2, 4
    and 5 also remove the old skill folder, its exclude line and its links in
    every worktree.

    Run it again after creating a worktree, or to upgrade: it re-links every
    worktree, never overwrites your config, and adds to it only the settings
    a newer template brings.

    REQUIREMENTS
    - Windows PowerShell 5.1 or PowerShell 7+, on Windows.
    - Git on PATH.
    - Developer Mode or an elevated shell, for yngshared's symbolic links.
    - Optional: gh, authenticated, for the labels.

.PARAMETER Project
    Any folder inside the project: the root, or any worktree. Default: the
    current folder.

.PARAMETER IssuesRepo
    <owner>/<repo> of the GitHub repository holding this project's issues,
    when they live apart from the code. Written into the config's issues:
    key only when it has no value yet, and used for the labels. Any other
    form stops the install before anything is written.

.PARAMETER SkipLabels
    Do not touch the repository's labels.

.PARAMETER SkipViewer
    Do not install yngv.

.PARAMETER BinDir
    Where yngv goes. Default: $HOME\.local\bin.

.EXAMPLE
    F:\YNGAIPlaybook\scripts\yngorch.ps1
    From anywhere inside the project: install, or upgrade.

.EXAMPLE
    F:\YNGAIPlaybook\scripts\yngorch.ps1 -Project D:\code\myproject

.EXAMPLE
    F:\YNGAIPlaybook\scripts\yngorch.ps1 -IssuesRepo acme/tracker
    Issues live in acme/tracker; code, branches and pull requests in origin.
#>
[CmdletBinding()]
param(
    [string]$Project = (Get-Location).Path,
    [string]$IssuesRepo,
    [switch]$SkipLabels,
    [switch]$SkipViewer,
    [string]$BinDir = (Join-Path $HOME '.local\bin')
)

$ErrorActionPreference = 'Stop'
$playbook = Split-Path -Parent $PSScriptRoot

function Step([string]$Status, [string]$Text) { Write-Host ("  {0,-8} {1}" -f $Status, $Text) }

# The issues repo (spec R28, R31): <owner>/<repo>, checked before anything
# is written.
$repoPattern = '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$'
if ($PSBoundParameters.ContainsKey('IssuesRepo') -and $IssuesRepo -notmatch $repoPattern) {
    throw "-IssuesRepo '$IssuesRepo' is not <owner>/<repo>; nothing was written."
}

# The config's top-level issues: value; '' when absent or empty.
function Get-IssuesValue([string]$Path) {
    if (-not (Test-Path $Path)) { return '' }
    $m = [regex]::Match([IO.File]::ReadAllText($Path), '(?m)^issues:[ \t]*([^\r\n]*)')
    if (-not $m.Success) { return '' }
    $v = ($m.Groups[1].Value -replace '^#.*', '' -replace '\s+#.*$', '').Trim()
    if ($v -match '^"(.*)"$' -or $v -match "^'(.*)'$") { $v = $Matches[1].Trim() }
    return $v
}

# Writes "issues: <Value>" into the config: over its empty issues: line,
# else just after the template's commented-out one, else at the end.
function Set-IssuesValue([string]$Path, [string]$Value) {
    $text = [IO.File]::ReadAllText($Path)
    $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $line = "issues: $Value"
    $m = [regex]::Match($text, '(?m)^issues:[^\r\n]*')
    if ($m.Success) { $text = $text.Substring(0, $m.Index) + $line + $text.Substring($m.Index + $m.Length) }
    else {
        $m = [regex]::Match($text, '(?m)^#[ \t]*issues:[^\r\n]*')
        if ($m.Success) { $at = $m.Index + $m.Length; $text = $text.Substring(0, $at) + $nl + $line + $text.Substring($at) }
        else {
            if ($text -and -not $text.EndsWith("`n")) { $text += $nl }
            $text += $line + $nl
        }
    }
    [IO.File]::WriteAllText($Path, $text, (New-Object Text.UTF8Encoding $false))
}

# The config files yngorch installs from a template (spec R41.1), one pair
# each: the template, its target in .yngaiplaybook\, and what a new file
# holds. A config file added later is one more pair.
$configPairs = @(
    @{ Template = 'templates\yngorchestratorconfig.yml'; Target = 'yngorchestratorconfig.yml'
       Created = 'auto-promote: no, every merge path required' }
)

# Config upgrade on reinstall (spec R39-R41). Files are read and written as
# Latin-1, one character per byte, so every byte yngorch does not insert is
# written back as it was, whatever the file's encoding.
$keyPattern = '^([ \t]*)([A-Za-z0-9_][A-Za-z0-9_.-]*):(?:[ \t](.*))?$'
$headerPattern = '^# --- Setting: (\S+)'

# $Text's lines, each with its own line ending.
function Split-Lines([string]$Text) {
    $segs = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($Text, '[^\n]*\n|[^\n]+$')) { $segs.Add($m.Value) }
    return ,$segs
}

# The index of the worked-examples banner (R39.3), else the line count.
function Find-Banner([string[]]$Lines) {
    for ($i = 0; $i -lt $Lines.Count; $i++) { if ($Lines[$i].StartsWith('# ====')) { return $i } }
    return $Lines.Count
}

# The active key lines among the first $End lines: indentation, name and
# value, its trailing comment dropped. A comment line is never one.
function Get-Keys([string[]]$Lines, [int]$End) {
    $keys = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $End; $i++) {
        $m = [regex]::Match($Lines[$i], $keyPattern)
        if (-not $m.Success) { continue }
        $keys.Add([pscustomobject]@{
            Index = $i; Pos = $keys.Count; Indent = $m.Groups[1].Value; Name = $m.Groups[2].Value
            Value = ($m.Groups[3].Value -replace '(^|[ \t])#.*$', '').Trim() })
    }
    return ,$keys
}

# The positions of the keys in key $P's block: each key after it indented
# deeper, up to the first one that is not.
function Get-Block($Keys, [int]$P) {
    $block = New-Object System.Collections.Generic.List[int]
    $len = $Keys[$P].Indent.Length
    for ($q = $P + 1; $q -lt $Keys.Count -and $Keys[$q].Indent.Length -gt $len; $q++) { $block.Add($q) }
    return ,$block
}

# Each key's dotted path, merge.slice-to-epic, from the indentation.
function Get-KeyPaths($Keys) {
    $paths = New-Object System.Collections.Generic.List[string]
    $stack = New-Object System.Collections.Generic.List[object]
    foreach ($k in $Keys) {
        while ($stack.Count -and $stack[$stack.Count - 1].Indent.Length -ge $k.Indent.Length) { $stack.RemoveAt($stack.Count - 1) }
        $stack.Add($k)
        $paths.Add((@($stack | ForEach-Object { $_.Name }) -join '.'))
    }
    return ,$paths
}

function Add-Insert($Ctx, [int]$After, [string]$Line) {
    if (-not $Ctx.Inserts.ContainsKey($After)) { $Ctx.Inserts[$After] = New-Object System.Collections.Generic.List[string] }
    $Ctx.Inserts[$After].Add($Line)
}

# The nested keys (R39.4) under template key $Tp that the file's
# occurrences $Fps of the same key lack: inserted after the block's last key
# line (R39.7), or, when the block cannot be extended line by line, a
# warning (R39.8). Present keys are compared level by level first, so a
# deeper key lands before a sibling inserted at the same line.
function Add-MissingKeys($Ctx, [int]$Tp, [int[]]$Fps, [string]$Path) {
    $tk = $Ctx.TKeys; $fk = $Ctx.FKeys
    $tBlock = Get-Block $tk $Tp
    if ($tBlock.Count -eq 0 -or $Fps.Count -eq 0) { return }
    $tIndent = $tk[$tBlock[0]].Indent
    $tChildren = @($tBlock | Where-Object { $tk[$_].Indent.Length -eq $tIndent.Length })
    $parent = $tk[$Tp].Name
    $have = New-Object Collections.Hashtable ([StringComparer]::Ordinal)
    $reason = if ($Fps.Count -gt 1) { "${parent}: is set more than once" } else { '' }
    foreach ($fp in $Fps) {
        if ($fk[$fp].Value) {
            if (-not $reason) { $reason = "${parent}: has its value on its own line" }
            foreach ($m in [regex]::Matches($fk[$fp].Value, '[{,][ \t]*["'']?([A-Za-z0-9_][A-Za-z0-9_.-]*)["'']?[ \t]*:')) {
                $have[$m.Groups[1].Value] = @()
            }
            continue
        }
        $block = Get-Block $fk $fp
        if ($block.Count -eq 0) { continue }
        $bi = $fk[$block[0]].Indent.Length
        $last = $null
        foreach ($q in $block) {
            $k = $fk[$q]
            if ($k.Indent.Contains("`t") -and -not $reason) { $reason = "${parent}:'s keys are indented with a tab" }
            if ($k.Indent.Length -eq $bi) {
                $last = $k
                if (-not $have.ContainsKey($k.Name)) { $have[$k.Name] = @() }
                $have[$k.Name] += $q
            }
            elseif (($k.Indent.Length -lt $bi -or $last.Value) -and -not $reason) {
                $reason = "${parent}:'s keys are not all at one indentation"
            }
        }
    }
    if (-not $reason) {
        foreach ($tc in $tChildren) {
            $name = $tk[$tc].Name
            if ($have.ContainsKey($name)) { Add-MissingKeys $Ctx $tc ([int[]]$have[$name]) "$Path.$name" }
        }
    }
    foreach ($tc in $tChildren) {
        $name = $tk[$tc].Name
        if ($have.ContainsKey($name)) { continue }
        $keyLine = $Ctx.TLines[$tk[$tc].Index].TrimStart()
        if ($reason) {
            $Ctx.Warnings.Add("$($Ctx.Display): $Path.$name not added ($reason); add it by hand: $keyLine")
            continue
        }
        $block = Get-Block $fk $Fps[0]
        if ($block.Count) { $after = $fk[$block[$block.Count - 1]].Index; $indent = $fk[$block[0]].Indent }
        else { $after = $fk[$Fps[0]].Index; $indent = $fk[$Fps[0]].Indent + $tIndent.Substring($tk[$Tp].Indent.Length) }
        $tSub = Get-Block $tk $tc
        $tEnd = if ($tSub.Count) { $tk[$tSub[$tSub.Count - 1]].Index } else { $tk[$tc].Index }
        for ($i = $tk[$tc].Index; $i -le $tEnd; $i++) {
            $line = $Ctx.TLines[$i]
            if ($line.StartsWith($tIndent)) { $line = $indent + $line.Substring($tIndent.Length) }
            Add-Insert $Ctx $after $line
        }
        $Ctx.Added.Add("$($Ctx.Display): $Path.${name}: $($tk[$tc].Value) (new in the template)")
    }
}

# Installs $Target from $Template when absent; otherwise adds every setting
# (R39.2) and nested key the template has and the file lacks, backing the
# file up first (R40.1), and reports each (R40.2-R40.4).
function Update-ConfigFile([string]$Template, [string]$Target, [string]$Display, [string]$Created) {
    if (-not (Test-Path -LiteralPath $Target)) {
        Copy-Item -LiteralPath $Template $Target
        Step 'created' "$Display ($Created)"
        return
    }
    $latin = [Text.Encoding]::GetEncoding(28591)
    $tText = $latin.GetString([IO.File]::ReadAllBytes($Template))
    if ($tText.StartsWith("$([char]0xEF)$([char]0xBB)$([char]0xBF)")) { $tText = $tText.Substring(3) }
    $fText = $latin.GetString([IO.File]::ReadAllBytes($Target))
    $tLines = [string[]]@((Split-Lines $tText) | ForEach-Object { $_ -replace '\r?\n$', '' })
    $fSegs = Split-Lines $fText
    $fLines = [string[]]@($fSegs | ForEach-Object { $_ -replace '\r?\n$', '' })

    # Inserted lines take the file's line ending, else the template's (R39.9).
    $source = if ($fText.Contains("`n")) { $fText } else { $tText }
    $at = $source.IndexOf("`n")
    $nl = if ($at -gt 0 -and $source[$at - 1] -eq "`r") { "`r`n" } else { "`n" }

    $tBanner = Find-Banner $tLines
    $fBanner = Find-Banner $fLines
    $ctx = @{
        Display = $Display; TLines = $tLines; TKeys = (Get-Keys $tLines $tBanner); FKeys = (Get-Keys $fLines $fLines.Count)
        Inserts = @{}; Added = (New-Object System.Collections.Generic.List[string])
        Warnings = (New-Object System.Collections.Generic.List[string]) }
    $fHeaders = New-Object Collections.Hashtable ([StringComparer]::Ordinal)
    foreach ($line in $fLines) { if ($line -cmatch $headerPattern) { $fHeaders[$Matches[1]] = $true } }
    $known = New-Object Collections.Hashtable ([StringComparer]::Ordinal)
    foreach ($p in (Get-KeyPaths $ctx.TKeys)) { $known[$p] = $true }

    # Settings in template order (R39.2, R39.5, R39.6).
    $headers = @(for ($i = 0; $i -lt $tBanner; $i++) { if ($tLines[$i] -cmatch $headerPattern) { $i } })
    $sections = New-Object System.Collections.Generic.List[string]
    for ($h = 0; $h -lt $headers.Count; $h++) {
        $start = $headers[$h]
        $end = if ($h + 1 -lt $headers.Count) { $headers[$h + 1] } else { $tBanner }
        $null = $tLines[$start] -cmatch $headerPattern
        $name = $Matches[1]
        $known[$name] = $true
        $fTop = [int[]]@($ctx.FKeys | Where-Object { $_.Indent -eq '' -and $_.Name -ceq $name } | ForEach-Object { $_.Pos })
        $tTop = @($ctx.TKeys | Where-Object { $_.Indent -eq '' -and $_.Name -ceq $name -and $_.Index -ge $start -and $_.Index -lt $end })
        if (-not $fTop.Count -and -not $fHeaders.ContainsKey($name)) {
            for ($i = $start; $i -lt $end; $i++) { $sections.Add($tLines[$i]) }
            $ctx.Added.Add("${Display}: $name (new in the template)")
        }
        elseif ($tTop.Count) { Add-MissingKeys $ctx $tTop[0].Pos $fTop $name }
    }
    foreach ($line in $sections) { Add-Insert $ctx ($fBanner - 1) $line }

    if ($ctx.Added.Count) {
        $sb = New-Object Text.StringBuilder
        if ($ctx.Inserts.ContainsKey(-1)) { foreach ($line in $ctx.Inserts[-1]) { [void]$sb.Append($line + $nl) } }
        for ($i = 0; $i -lt $fSegs.Count; $i++) {
            [void]$sb.Append($fSegs[$i])
            if (-not $ctx.Inserts.ContainsKey($i)) { continue }
            if (-not $fSegs[$i].EndsWith("`n")) { [void]$sb.Append($nl) }
            foreach ($line in $ctx.Inserts[$i]) { [void]$sb.Append($line + $nl) }
        }
        Copy-Item -LiteralPath $Target "$Target.bak" -Force
        Step 'backed up' "$Display -> $(Split-Path -Leaf $Target).bak"
        [IO.File]::WriteAllBytes($Target, $latin.GetBytes($sb.ToString()))
        foreach ($a in $ctx.Added) { Step 'added' $a }
    }
    else { Step 'kept' "$Display (yours, nothing new)" }
    foreach ($w in $ctx.Warnings) { Step 'warning' $w }
    $noted = New-Object Collections.Hashtable ([StringComparer]::Ordinal)
    foreach ($p in (Get-KeyPaths $ctx.FKeys)) {
        if ($known.ContainsKey($p) -or $noted.ContainsKey($p)) { continue }
        $noted[$p] = $true
        Step 'note' "${Display}: $p is not in the template; the orchestrator ignores it"
    }
}

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

# 3. The playbook's root folder, .yngaiplaybook\ (spec R23-R26). An older
# .yngorchestrator\ (1.2.0-1.4.0) or .orchestrator\ (1.1.0) moves into it
# first, item by item; when that is ambiguous, nothing moves or is created.
$ynga = Join-Path $root '.yngaiplaybook'
$config = Join-Path $ynga 'yngorchestratorconfig.yml'
$olds = @('.yngorchestrator', '.orchestrator') | Where-Object { Test-Path -PathType Container (Join-Path $root $_) }
$hasYnga = Test-Path -PathType Container $ynga
if ($olds -and ($hasYnga -or @($olds).Count -gt 1)) {
    $names = @(if ($hasYnga) { '.yngaiplaybook\' }) + @($olds | ForEach-Object { "$_\" })
    Step 'warning' "found $($names -join ' '); moved nothing and left each as it is: move what you need into .yngaiplaybook\ by hand"
    foreach ($pair in $configPairs) { Step 'skipped' ".yngaiplaybook\$($pair.Target) not upgraded (move .yngaiplaybook\ by hand first, then run again)" }
    if ($IssuesRepo) { Step 'skipped' "issues: $IssuesRepo not written (move .yngaiplaybook\ by hand first, then run again)" }
}
else {
    if ($olds) {
        $old = @($olds)[0]
        $oldDir = Join-Path $root $old
        New-Item -ItemType Directory -Force $ynga | Out-Null
        foreach ($item in Get-ChildItem -Force $oldDir) {
            $dest = switch -CaseSensitive ($item.Name) {
                'config.yml' { 'yngorchestratorconfig.yml' }
                'runs'       { 'yngorchestratorruns' }
                default      { $item.Name }
            }
            $s = if ($item.PSIsContainer) { '\' } else { '' }
            Move-Item -LiteralPath $item.FullName (Join-Path $ynga $dest)
            Step 'moved' "$old\$($item.Name)$s -> .yngaiplaybook\$dest$s"
        }
        if (Get-ChildItem -Force $oldDir) { Step 'warning' "$old\ is not empty; left in place" }
        else { Remove-Item -Force $oldDir; Step 'removed' "$old\ (empty)" }
    }
    New-Item -ItemType Directory -Force (Join-Path $ynga 'yngorchestratorruns') | Out-Null
    # Each config file: written whole when absent, else upgraded (R39-R41),
    # after the migration and before the issues: write (R39.10).
    foreach ($pair in $configPairs) {
        Update-ConfigFile (Join-Path $playbook $pair.Template) (Join-Path $ynga $pair.Target) ".yngaiplaybook\$($pair.Target)" $pair.Created
    }
    $current = Get-IssuesValue $config
    if ($IssuesRepo -and -not $current) {
        Set-IssuesValue $config $IssuesRepo
        Step 'wrote' "issues: $IssuesRepo into .yngaiplaybook\yngorchestratorconfig.yml"
    }
    elseif ($IssuesRepo -and $current -ne $IssuesRepo) {
        Step 'kept' "issues: $current in .yngaiplaybook\yngorchestratorconfig.yml (yours; -IssuesRepo $IssuesRepo not written)"
    }
    elseif ($current) { Step 'kept' "issues: $current in .yngaiplaybook\yngorchestratorconfig.yml" }
    $version = ([IO.File]::ReadAllText((Join-Path $playbook 'VERSION'))).Trim()
    $readme = [IO.File]::ReadAllText((Join-Path $playbook 'templates\yngaiplaybookreadme.md')).Replace('{{VERSION}}', $version)
    [IO.File]::WriteAllText((Join-Path $ynga 'README.md'), $readme, (New-Object Text.UTF8Encoding $false))
    Step 'wrote' ".yngaiplaybook\README.md (the folder explained, $version)"
}

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
else { Step 'linked' 'every worktree and the root .claude\ (yngshared -link -All)' }

# 6. Labels, when gh is available, in the issues repo: -IssuesRepo, else
# the config's issues: value, else origin's repo (spec R31.3).
$configIssues = Get-IssuesValue $config
if ($SkipLabels) { Step 'skipped' 'labels (-SkipLabels)' }
elseif (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Step 'skipped' 'labels (gh not found)' }
elseif (-not $IssuesRepo -and $configIssues -and $configIssues -notmatch $repoPattern) {
    Step 'warning' "labels skipped: the config's issues: '$configIssues' is not <owner>/<repo>"
}
else {
    $repo = if ($IssuesRepo) { $IssuesRepo }
            elseif ($configIssues) { $configIssues }
            else {
                $url = try { & git --git-dir=$common remote get-url origin 2>$null } catch { $null }
                if ($url) { $url -replace '\.git$', '' }
            }
    if (-not $repo) { Step 'skipped' 'labels (no origin remote)' }
    else {
        $labels = @(
            @('epic',                     '3e4b9e', 'Feature: tracker card plus integration branch'),
            @('workflow:needs-triage',    'fbca04', 'Triage fills in every label'),
            @('workflow:needs-info',      'd876e3', 'A person must answer before work starts'),
            @('workflow:ready-for-agent', '0e8a16', 'Gate 1 passed: an agent may pick it up (set by a person, or by plan approval if auto-promote: yes)'),
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

# 7. The yngv viewer, per user (not per project): yngv.ps1 and a yngv.cmd
# shim in BinDir, which goes on the user PATH when it is not there yet.
if ($SkipViewer) { Step 'skipped' 'yngv (-SkipViewer)' }
else {
    New-Item -ItemType Directory -Force $BinDir | Out-Null
    Copy-Item -Force (Join-Path $PSScriptRoot 'yngv.ps1') (Join-Path $BinDir 'yngv.ps1')
    Set-Content -Encoding Ascii (Join-Path $BinDir 'yngv.cmd') @(
        '@echo off',
        'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0yngv.ps1" %*')
    Step 'copied' "yngv -> $BinDir (yngv.ps1, yngv.cmd)"

    # Read the raw user PATH so %VAR% entries stay unexpanded, and write it
    # back with the same registry type.
    $envKey = Get-Item 'HKCU:\Environment'
    $rawPath = $envKey.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    $full = [IO.Path]::GetFullPath($BinDir).TrimEnd('\')
    $onPath = @($rawPath, [Environment]::GetEnvironmentVariable('Path', 'Machine')) -split ';' |
        Where-Object { $_ } |
        Where-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') -eq $full }
    if ($onPath) { Step 'kept' "$full already on PATH" }
    else {
        $newPath = if ($rawPath) { $rawPath.TrimEnd(';') + ';' + $full } else { $full }
        Set-ItemProperty 'HKCU:\Environment' -Name Path -Value $newPath -Type ExpandString
        # Tell running programs (Explorer, new terminals) the environment changed.
        if (-not ('YngEnv' -as [type])) {
            Add-Type -Namespace '' -Name YngEnv -MemberDefinition '[DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'
        }
        $r = [UIntPtr]::Zero
        [void][YngEnv]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$r)
        Step 'added' "$full to your user PATH (open a new terminal to use yngv)"
    }
}

Write-Host ''
Write-Host 'Done. Next:'
Write-Host "  - Set auto-promote (Gate 1) and your merge rules (Gate 2) in $config"
Write-Host '  - From an Epic worktree, start Claude Code and run: /yngorchestrator <epic issue>'
Write-Host '  - After creating a new worktree, run this script again to link it.'
