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
         Then settle the git provider and its host, writing nothing yet:
         the config's provider: and host: when set; else -Provider; else
         detected from origin's host: github.com, gitlab.com and
         bitbucket.org by name, any other host by which of
         "gh auth status --hostname" and "glab auth status --hostname"
         succeeds. Neither or both stops the install, asking for
         -Provider. Bitbucket on a host other than bitbucket.org (Data
         Center) stops it too: planned, not supported. GitLab and Bitbucket
         without jq on PATH stop it as well, naming jq.
      2. Copy the skill and worker into .shared\.claude\ (upgrades in place).
      3. Fill .yngaiplaybook\: yngorchestratorconfig.yml from the template
         when absent; when present, add the settings and keys the template
         has and it lacks, changing no line, after a backup to
         yngorchestratorconfig.yml.bak; yngorchestratorruns\; README.md from
         the template.
         Write the config's provider: and host: keys, each only if it has
         no value yet; an existing value is kept and reported.
         With -IssuesRepo, write the config's issues: key, only if it has
         no value yet; an existing value is kept and reported.
      4. Add the two exclude lines to .bare\info\exclude, only if missing.
      5. Copy yngshared.ps1 into the project root and link every worktree,
         and .shared\.claude\ into the root's own .claude\.
      6. Check the provider's tool, and only that one: gh or glab logged in
         to the host, or, for Bitbucket, curl and the Bitbucket API
         answering for BITBUCKET_EMAIL and BITBUCKET_API_TOKEN. Then set up
         the workflow states in the issues repo (-IssuesRepo, else the
         config's issues: value, else origin's repo): labels on GitHub and
         GitLab; on Bitbucket, whose API cannot create them, a warning
         naming each component and the epic milestone to create by hand.
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
    - The provider's tool, for the check and the workflow states: gh
      (GitHub) or glab (GitLab) logged in to the host, or curl with
      BITBUCKET_EMAIL and BITBUCKET_API_TOKEN set (Bitbucket Cloud). The
      token is never printed or written anywhere.
    - jq on PATH, for GitLab and Bitbucket; GitHub does not need it.

.PARAMETER Project
    Any folder inside the project: the root, or any worktree. Default: the
    current folder.

.PARAMETER Provider
    github, gitlab or bitbucket: the git provider, when it cannot be
    detected from origin, or to skip detection. Written into the config's
    provider: key only when it has no value yet; a different value already
    there wins, with a warning.

.PARAMETER IssuesRepo
    <owner>/<repo> of the repository holding this project's issues, on the
    same provider, when they live apart from the code. Written into the
    config's issues: key only when it has no value yet, and used for the
    workflow states. Any other form stops the install before anything is
    written.

.PARAMETER SkipLabels
    Do not touch the repository's workflow states (labels, or Bitbucket
    components and milestone).

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

.EXAMPLE
    F:\YNGAIPlaybook\scripts\yngorch.ps1 -Provider gitlab
    origin is on a self-managed host that detection cannot name.
#>
[CmdletBinding()]
param(
    [string]$Project = (Get-Location).Path,
    [ValidateSet('github', 'gitlab', 'bitbucket')]
    [string]$Provider,
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

# The config's top-level <Key>: value (issues, provider, host); '' when
# absent or empty.
function Get-ConfigValue([string]$Path, [string]$Key) {
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    $m = [regex]::Match([IO.File]::ReadAllText($Path), "(?m)^$([regex]::Escape($Key)):[ \t]*([^\r\n]*)")
    if (-not $m.Success) { return '' }
    $v = ($m.Groups[1].Value -replace '^#.*', '' -replace '\s+#.*$', '').Trim()
    if ($v -match '^"(.*)"$' -or $v -match "^'(.*)'$") { $v = $Matches[1].Trim() }
    return $v
}

# Writes "<Key>: <Value>" into the config, one line: over its empty <Key>:
# line, else just after the template's commented-out one, else at the end.
# Read and written as Latin-1, so every other byte stays as it was.
function Set-ConfigValue([string]$Path, [string]$Key, [string]$Value) {
    $latin = [Text.Encoding]::GetEncoding(28591)
    $text = $latin.GetString([IO.File]::ReadAllBytes($Path))
    $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $line = "${Key}: $Value"
    $k = [regex]::Escape($Key)
    $m = [regex]::Match($text, "(?m)^${k}:[^\r\n]*")
    if ($m.Success) { $text = $text.Substring(0, $m.Index) + $line + $text.Substring($m.Index + $m.Length) }
    else {
        $m = [regex]::Match($text, "(?m)^#[ \t]*${k}:[^\r\n]*")
        if ($m.Success) { $at = $m.Index + $m.Length; $text = $text.Substring(0, $at) + $nl + $line + $text.Substring($at) }
        else {
            if ($text -and -not $text.EndsWith("`n")) { $text += $nl }
            $text += $line + $nl
        }
    }
    [IO.File]::WriteAllBytes($Path, $latin.GetBytes($text))
}

# The supported providers (spec R1.1): each one's cloud host, and what the
# install checks for it (R6.1). A provider added later is one more entry.
$providers = [ordered]@{
    github    = @{ Cloud = 'github.com';    Cli = 'gh';   Check = 'gh auth status' }
    gitlab    = @{ Cloud = 'gitlab.com';    Cli = 'glab'; Check = 'glab auth status' }
    bitbucket = @{ Cloud = 'bitbucket.org'; Cli = 'curl'; Check = 'curl and the Bitbucket API (BITBUCKET_EMAIL, BITBUCKET_API_TOKEN)' }
}
$providerNames = @($providers.Keys) -join ', '

# The workflow states (spec R8): the same names on every provider. GitHub
# and GitLab hold them as labels; Bitbucket as components, named without
# workflow:, with epic as a milestone.
$states = @(
    @('epic',                     '3e4b9e', 'Feature: tracker card plus integration branch'),
    @('workflow:needs-triage',    'fbca04', 'Triage fills in every label'),
    @('workflow:needs-info',      'd876e3', 'A person must answer before work starts'),
    @('workflow:ready-for-agent', '0e8a16', 'Gate 1 passed: an agent may pick it up (set by a person, or by plan approval if auto-promote: yes)'),
    @('workflow:ready-for-human', '1d76db', 'Gate 1 passed: a person picks it up'),
    @('workflow:in-progress',     'c5def5', 'Being worked; no PR yet (set by the dispatcher)'),
    @('workflow:in-review',       '5319e7', 'PR open, waiting for a person (set by the dispatcher)'))

# Runs a native command, its errors discarded, so Windows PowerShell 5.1
# never turns its stderr into a terminating error. Returns its output
# lines; the exit code is in $LASTEXITCODE. -Stdin, when given, is its input.
function Invoke-Native([string]$Exe, [string[]]$Arguments, [string]$Stdin) {
    $ErrorActionPreference = 'Continue'
    if ($PSBoundParameters.ContainsKey('Stdin')) { $Stdin | & $Exe @Arguments 2>$null }
    else { & $Exe @Arguments 2>$null }
}

# origin's host and repository path from its URL, HTTPS or SSH form
# (https://host/owner/repo.git, git@host:owner/repo.git,
# ssh://git@host:22/group/sub/project.git); $null without an origin.
function Get-Origin([string]$GitDir) {
    $url = @(Invoke-Native 'git' @("--git-dir=$GitDir", 'remote', 'get-url', 'origin'))
    if ($LASTEXITCODE -ne 0 -or -not $url) { return $null }
    $u = $url[0].Trim() -replace '/+$', '' -replace '\.git$', ''
    if ($u -match '^[A-Za-z][A-Za-z0-9+.-]*://(?:[^@/]*@)?([^/:]+)(?::\d*)?/(.+)$' -or
        $u -match '^(?:[^@/]+@)?([^/:]{2,}):(.+)$') {
        return @{ Host = $Matches[1].ToLower(); Path = $Matches[2].TrimStart('/') }
    }
    return $null
}

# What "<Tool> auth status --hostname <HostName>" says: 'logged in',
# 'not found', or 'not logged in to <host>'.
function Test-CliAuth([string]$Tool, [string]$HostName) {
    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) { return 'not found' }
    $null = Invoke-Native $Tool @('auth', 'status', '--hostname', $HostName)
    if ($LASTEXITCODE -eq 0) { return 'logged in' }
    return "not logged in to $HostName"
}

# One GET from the Bitbucket Cloud API (spec R6.1-2), as @{ Code; Body }.
# The credentials reach curl on its standard input, never on its command
# line, in output, or in a file.
function Invoke-BitbucketGet([string]$Path) {
    $user = "${env:BITBUCKET_EMAIL}:${env:BITBUCKET_API_TOKEN}".Replace('\', '\\').Replace('"', '\"')
    $out = @(Invoke-Native 'curl.exe' @('-s', '-K', '-', '-w', '\n%{http_code}', "https://api.bitbucket.org/2.0/$Path") "user = `"$user`"")
    $code = if ($out.Count) { "$($out[$out.Count - 1])".Trim() } else { '' }
    if ($code -notmatch '^\d{3}$') { $code = '000' }
    $body = if ($out.Count -gt 1) { $out[0..($out.Count - 2)] -join "`n" } else { '' }
    return @{ Code = $code; Body = $body }
}

# The provider's own tool, and only it (spec R6.1): '' when it works, else
# what failed.
function Test-ProviderTool([string]$Name, [string]$HostName) {
    if ($Name -eq 'github' -or $Name -eq 'gitlab') {
        $tool = if ($Name -eq 'github') { 'gh' } else { 'glab' }
        $r = Test-CliAuth $tool $HostName
        if ($r -eq 'logged in') { return '' }
        return "$tool $r (run: $tool auth login --hostname $HostName)"
    }
    if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) { return 'curl not found' }
    if (-not $env:BITBUCKET_EMAIL -or -not $env:BITBUCKET_API_TOKEN) {
        return 'BITBUCKET_EMAIL and BITBUCKET_API_TOKEN are not both set (see INSTALL.md)'
    }
    $r = Invoke-BitbucketGet 'user'
    if ($r.Code -eq '200') { return '' }
    return "GET https://api.bitbucket.org/2.0/user answered HTTP $($r.Code) for BITBUCKET_EMAIL and BITBUCKET_API_TOKEN"
}

# Setup states (spec R8.4), one routine per provider, each printing one
# line: what it set up, or a warning naming what to create by hand.
function Set-GitHubStates([string]$HostName, [string]$Repo) {
    $failed = @()
    foreach ($s in $states) {
        $null = Invoke-Native 'gh' @('label', 'create', $s[0], '-R', "$HostName/$Repo", '-c', $s[1], '-d', $s[2], '--force')
        if ($LASTEXITCODE -ne 0) { $failed += $s[0] }
    }
    if ($failed) { Step 'warning' "labels: $($failed.Count) of $($states.Count) not created on $Repo; create them by hand in its Issues > Labels: $($failed -join ', ')" }
    else { Step 'labels' "$($states.Count) created or updated on $Repo" }
}

function Set-GitLabStates([string]$HostName, [string]$Repo) {
    $api = "projects/$([uri]::EscapeDataString($Repo))/labels"
    $out = @(Invoke-Native 'glab' @('api', '--hostname', $HostName, "${api}?per_page=100"))
    $have = if ($LASTEXITCODE -eq 0) { @(($out -join "`n" | ConvertFrom-Json) | ForEach-Object { $_.name }) } else { $null }
    $failed = @(); $created = 0
    foreach ($s in $states) {
        if ($null -ne $have -and $have -contains $s[0]) { continue }
        if ($null -eq $have) { $failed += $s[0]; continue }
        $null = Invoke-Native 'glab' @('api', '--hostname', $HostName, '-X', 'POST', $api,
            '-f', "name=$($s[0])", '-f', "color=#$($s[1])", '-f', "description=$($s[2])")
        if ($LASTEXITCODE -eq 0) { $created++ } else { $failed += $s[0] }
    }
    if ($failed) { Step 'warning' "labels: $($failed.Count) of $($states.Count) not created on $Repo; create them by hand in its Manage > Labels: $($failed -join ', ')" }
    else { Step 'labels' "$created created, $($states.Count - $created) already there on $Repo" }
}

# Bitbucket's API reads components and milestones but cannot create them,
# so this checks which exist and names the rest to create by hand.
function Set-BitbucketStates([string]$Repo) {
    $missing = @(); $others = @()
    $wanted = @{
        components = @($states | Where-Object { $_[0] -like 'workflow:*' } | ForEach-Object { $_[0].Substring(9) })
        milestones = @('epic') }
    foreach ($kind in 'components', 'milestones') {
        $r = Invoke-BitbucketGet "repositories/$Repo/${kind}?pagelen=100"
        $have = if ($r.Code -eq '200') { @(($r.Body | ConvertFrom-Json).values | ForEach-Object { $_.name }) } else { @() }
        $absent = @($wanted[$kind] | Where-Object { $have -notcontains $_ })
        if ($absent) { $missing += "$($kind.TrimEnd('s')) $($absent -join ', ')" }
        # Components of the person's own: the workflow takes the field over.
        if ($kind -eq 'components') { $others = @($have | Where-Object { $wanted.components -notcontains $_ }) }
    }
    if ($missing) {
        Step 'warning' "states: Bitbucket's API cannot create components or milestones; create them by hand in https://bitbucket.org/$Repo/admin (Repository settings > Issues, with the issue tracker on): $($missing -join '; ')"
    }
    else { Step 'states' "$($wanted.components.Count) components and the epic milestone found on $Repo" }
    if ($others) {
        Step 'note' "states: $Repo has components other than the workflow states: $($others -join ', '); the workflow takes components over (each issue's component holds its state)"
    }
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
    $flow = $false; $tab = $false; $mixed = $false
    foreach ($fp in $Fps) {
        if ($fk[$fp].Value) {
            $flow = $true
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
            if ($k.Indent.Contains("`t")) { $tab = $true }
            if ($k.Indent.Length -eq $bi) {
                $last = $k
                if (-not $have.ContainsKey($k.Name)) { $have[$k.Name] = @() }
                $have[$k.Name] += $q
            }
            elseif ($k.Indent.Length -lt $bi -or $last.Value) { $mixed = $true }
        }
    }
    # The first reason that holds, in this order (R39.8).
    $reason = if ($Fps.Count -gt 1) { "$parent is set more than once" }
              elseif ($flow) { "$parent has its value on the same line" }
              elseif ($tab) { "the keys under $parent are indented with a tab" }
              elseif ($mixed) { "the keys under $parent are not all at one indentation" }
              else { '' }
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
            $Ctx.Warnings.Add("$($Ctx.Display): $Path.$name not added, $reason; add it by hand under ${parent}: as `"$keyLine`"")
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

# 1b. The provider and its host (spec R2, R3), settled before anything is
# written: the config's value wins, then -Provider, then detection from
# origin's host. Written in step 3, each key only when it has no value.
$ynga = Join-Path $root '.yngaiplaybook'
$config = Join-Path $ynga 'yngorchestratorconfig.yml'
$origin = Get-Origin $common
$providerKept = Get-ConfigValue $config 'provider'
$hostKept = Get-ConfigValue $config 'host'
$detectHost = if ($hostKept) { $hostKept } elseif ($origin) { $origin.Host } else { '' }
# PowerShell names are case-blind, so the result is $gitProvider, apart
# from the -Provider parameter.
if ($Provider) { $Provider = $Provider.ToLower() }
if ($providerKept) {
    $gitProvider = $providerKept.ToLower()
    if (-not $providers.Contains($gitProvider)) {
        throw "provider: '$providerKept' in $config is not one of $providerNames; nothing was written."
    }
    if ($Provider -and $Provider -ne $gitProvider) {
        Step 'warning' "-Provider $Provider differs from provider: $providerKept in .yngaiplaybook\yngorchestratorconfig.yml; kept $providerKept (the config wins; edit it by hand to change it)"
    }
}
elseif ($Provider) { $gitProvider = $Provider; $providerFrom = 'from -Provider' }
elseif (-not $detectHost) {
    throw "Cannot detect the git provider: there is no origin remote. Run again with -Provider github|gitlab|bitbucket; nothing was written."
}
else {
    $gitProvider = ''
    foreach ($p in $providers.Keys) { if ($providers[$p].Cloud -eq $detectHost) { $gitProvider = $p } }
    if (-not $gitProvider) {
        $gh = Test-CliAuth 'gh' $detectHost
        $glab = Test-CliAuth 'glab' $detectHost
        if ($gh -eq 'logged in' -and $glab -ne 'logged in') { $gitProvider = 'github' }
        elseif ($glab -eq 'logged in' -and $gh -ne 'logged in') { $gitProvider = 'gitlab' }
        else {
            throw "Cannot tell the git provider of $detectHost (gh auth status: $gh; glab auth status: $glab). Run again with -Provider github|gitlab|bitbucket; nothing was written."
        }
    }
    $providerFrom = 'detected from origin'
}
$gitHost = if ($detectHost) { $detectHost } else { $providers[$gitProvider].Cloud }
$gitHostFrom = if ($origin) { 'from origin' } else { "$($gitProvider)'s cloud host" }
if ($gitProvider -eq 'bitbucket' -and $gitHost -ne 'bitbucket.org') {
    throw "Bitbucket on $gitHost is Bitbucket Data Center: planned, not supported. Only Bitbucket Cloud (bitbucket.org) is; nothing was written."
}
# GitLab and Bitbucket are worked with jq, besides glab or curl; GitHub
# needs none (gh reads JSON itself).
if ($gitProvider -ne 'github' -and -not (Get-Command jq -ErrorAction SilentlyContinue)) {
    throw "jq not found: the $gitProvider provider needs jq on PATH, besides $($providers[$gitProvider].Cli). Install jq and run again; nothing was written."
}

# 2. Skill and worker into .shared\.claude\.
$skillDir = Join-Path $root '.shared\.claude\skills\yngorchestrator'
$agentDir = Join-Path $root '.shared\.claude\agents'
New-Item -ItemType Directory -Force $skillDir, $agentDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $playbook 'skills\yngorchestrator\*') $skillDir
Copy-Item -Force (Join-Path $playbook 'agents\slice-worker.md') $agentDir
Step 'copied' '.shared\.claude\skills\yngorchestrator\, .shared\.claude\agents\slice-worker.md'
# The 1.1.0 skill folder, which only this installer writes.
$oldSkill = Join-Path $root '.shared\.claude\skills\orchestrate'
if (Test-Path $oldSkill) { Remove-Item -Recurse -Force $oldSkill; Step 'removed' '.shared\.claude\skills\orchestrate\ (renamed yngorchestrator)' }

# 3. The playbook's root folder, .yngaiplaybook\ (spec R23-R26). An older
# .yngorchestrator\ (1.2.0-1.4.0) or .orchestrator\ (1.1.0) moves into it
# first, item by item; when that is ambiguous, nothing moves or is created.
$olds = @('.yngorchestrator', '.orchestrator') | Where-Object { Test-Path -PathType Container (Join-Path $root $_) }
$hasYnga = Test-Path -PathType Container $ynga
if ($olds -and ($hasYnga -or @($olds).Count -gt 1)) {
    $names = @(if ($hasYnga) { '.yngaiplaybook\' }) + @($olds | ForEach-Object { "$_\" })
    Step 'warning' "found $($names -join ' '); moved nothing and left each as it is: move what you need into .yngaiplaybook\ by hand"
    foreach ($pair in $configPairs) { Step 'skipped' ".yngaiplaybook\$($pair.Target) not upgraded (move .yngaiplaybook\ by hand first, then run again)" }
    if (-not $providerKept) { Step 'skipped' "provider: $gitProvider not written (move .yngaiplaybook\ by hand first, then run again)" }
    if (-not $hostKept) { Step 'skipped' "host: $gitHost not written (move .yngaiplaybook\ by hand first, then run again)" }
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
    # after the migration and before the provider:, host: and issues:
    # writes (R39.10; yngproviders R14.2).
    foreach ($pair in $configPairs) {
        Update-ConfigFile (Join-Path $playbook $pair.Template) (Join-Path $ynga $pair.Target) ".yngaiplaybook\$($pair.Target)" $pair.Created
    }
    # provider: and host:, each only when it has no value yet, one line
    # each (yngproviders R2.3, R3.2-3). A -Provider the config contradicts
    # changes nothing (warned in step 1b).
    if ($providerKept) { Step 'kept' "provider: $providerKept (yours)" }
    else {
        Set-ConfigValue $config 'provider' $gitProvider
        Step 'wrote' "provider: $gitProvider ($providerFrom)"
    }
    if ($hostKept) { Step 'kept' "host: $hostKept (yours)" }
    else {
        Set-ConfigValue $config 'host' $gitHost
        Step 'wrote' "host: $gitHost ($gitHostFrom)"
    }
    $current = Get-ConfigValue $config 'issues'
    if ($IssuesRepo -and -not $current) {
        Set-ConfigValue $config 'issues' $IssuesRepo
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

# 6. The provider's tool, and only its tool (yngproviders R6.1), then the
# workflow states (R8.4) in the issues repo: -IssuesRepo, else the config's
# issues: value, else origin's repo (spec R31.3).
$toolProblem = Test-ProviderTool $gitProvider $gitHost
if ($toolProblem) { Step 'warning' "$($gitProvider): $toolProblem" }
else { Step 'checked' "$($providers[$gitProvider].Check) on $gitHost" }
$configIssues = Get-ConfigValue $config 'issues'
if ($SkipLabels) { Step 'skipped' 'workflow states (-SkipLabels)' }
elseif ($toolProblem) { Step 'skipped' "workflow states (the $gitProvider check above failed)" }
elseif (-not $IssuesRepo -and $configIssues -and $configIssues -notmatch $repoPattern) {
    Step 'warning' "workflow states skipped: the config's issues: '$configIssues' is not <owner>/<repo>"
}
else {
    $repo = if ($IssuesRepo) { $IssuesRepo } elseif ($configIssues) { $configIssues } elseif ($origin) { $origin.Path }
    if (-not $repo) { Step 'skipped' 'workflow states (no origin remote)' }
    elseif ($gitProvider -eq 'github') { Set-GitHubStates $gitHost $repo }
    elseif ($gitProvider -eq 'gitlab') { Set-GitLabStates $gitHost $repo }
    else { Set-BitbucketStates $repo }
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
