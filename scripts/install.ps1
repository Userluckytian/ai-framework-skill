<#
.SYNOPSIS
  Install AI framework templates into a project root (project-level only).

.PARAMETER TargetRoot
  Destination project root.

.PARAMETER Tool
  opencode | codex | claude | all | others

.PARAMETER ProjectName
  Replaces {{PROJECT_NAME}}

.PARAMETER CssPrefix
  Replaces {{CSS_PREFIX}} (CSS vars become --prefix-*)

.PARAMETER Conflict
  overwrite | skip | backup

.PARAMETER SkillRoot
  This repo root (defaults to parent of scripts/)
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$TargetRoot,

  [Parameter(Mandatory = $true)]
  [ValidateSet('opencode', 'codex', 'claude', 'all', 'others')]
  [string]$Tool,

  [string]$ProjectName = '',
  [string]$CssPrefix = 'app',
  [ValidateSet('overwrite', 'skip', 'backup')]
  [string]$Conflict = 'backup',
  [string]$SkillRoot = ''
)

$ErrorActionPreference = 'Stop'

if (-not $SkillRoot) {
  $SkillRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
  # scripts/ is directly under repo root
  $SkillRoot = Split-Path $PSScriptRoot -Parent
}

$TargetRoot = (Resolve-Path -LiteralPath $TargetRoot).Path
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$Templates = Join-Path $SkillRoot 'templates'

if (-not (Test-Path $Templates)) {
  throw "templates/ not found under SkillRoot: $SkillRoot"
}

if (-not $ProjectName) {
  $pkg = Join-Path $TargetRoot 'package.json'
  if (Test-Path $pkg) {
    try {
      $ProjectName = (Get-Content $pkg -Raw | ConvertFrom-Json).name
    } catch { }
  }
  if (-not $ProjectName) {
    $ProjectName = Split-Path $TargetRoot -Leaf
  }
}

function Write-Log([string]$msg) {
  Write-Host $msg
}

function Ensure-Dir([string]$path) {
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

function Render-Text([string]$text) {
  return $text.Replace('{{PROJECT_NAME}}', $ProjectName).Replace('{{CSS_PREFIX}}', $CssPrefix)
}

function Place-File {
  param(
    [string]$SourcePath,
    [string]$DestPath,
    [switch]$Render
  )

  Ensure-Dir (Split-Path $DestPath -Parent)

  if (Test-Path $DestPath) {
    switch ($Conflict) {
      'skip' {
        Write-Log "SKIP  $DestPath"
        return
      }
      'backup' {
        $bak = "$DestPath.bak"
        Copy-Item -LiteralPath $DestPath -Destination $bak -Force
        Write-Log "BACKUP $DestPath -> $bak"
      }
      'overwrite' {
        Write-Log "OVERWRITE $DestPath"
      }
    }
  }

  if ($Render) {
    $raw = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8
    $out = Render-Text $raw
    [System.IO.File]::WriteAllText($DestPath, $out, [System.Text.UTF8Encoding]::new($false))
  } else {
    Copy-Item -LiteralPath $SourcePath -Destination $DestPath -Force
  }
  Write-Log "WRITE $DestPath"
}

function Copy-Tree {
  param(
    [string]$SourceDir,
    [string]$DestDir,
    [switch]$RenderMarkdown
  )
  if (-not (Test-Path $SourceDir)) {
    Write-Log "MISSING source $SourceDir"
    return
  }
  Get-ChildItem -LiteralPath $SourceDir -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
    $dest = Join-Path $DestDir $rel
    $render = $RenderMarkdown -and ($_.Extension -match '\.(md|template|jsonc|mdc)$' -or $_.Name -like '*.template')
    # never render binary hooks without extension carefully
    if ($_.Name -eq 'run-hook.cmd' -or $_.FullName -match '\\session-start') {
      $render = $false
    }
    Place-File -SourcePath $_.FullName -DestPath $dest -Render:$render
  }
}

function Install-OpenCode {
  Write-Log "=== OpenCode ==="
  $src = Join-Path $Templates 'opencode'
  $dst = Join-Path $TargetRoot '.opencode'
  Ensure-Dir $dst
  Place-File (Join-Path $src 'opencode.jsonc') (Join-Path $dst 'opencode.jsonc')
  Copy-Tree (Join-Path $src 'agents') (Join-Path $dst 'agents') -RenderMarkdown
  Copy-Tree (Join-Path $src 'commands') (Join-Path $dst 'commands') -RenderMarkdown

  $common = Join-Path $Templates 'common'
  Place-File (Join-Path $common 'AGENTS.md.template') (Join-Path $TargetRoot 'AGENTS.md') -Render
  Place-File (Join-Path $common 'CODE_REVIEW.md') (Join-Path $TargetRoot 'CODE_REVIEW.md')
  Place-File (Join-Path $common 'coding-standards.md.template') (Join-Path $TargetRoot 'coding-standards.md') -Render
  Place-File (Join-Path $common 'architecture.md.template') (Join-Path $TargetRoot 'architecture.md') -Render
}

function Install-Codex {
  Write-Log "=== Codex ==="
  $src = Join-Path $Templates 'codex'
  Copy-Tree (Join-Path $src '.codex-plugin') (Join-Path $TargetRoot '.codex-plugin')
  $docs = Join-Path $TargetRoot 'docs\ai-framework'
  Ensure-Dir $docs
  if (Test-Path (Join-Path $src 'references\codex-tools.md')) {
    Place-File (Join-Path $src 'references\codex-tools.md') (Join-Path $docs 'codex-tools.md')
  }
  Place-File (Join-Path $src 'INSTALL.md') (Join-Path $docs 'codex-INSTALL.md')
}

function Install-Claude {
  Write-Log "=== Claude ==="
  $src = Join-Path $Templates 'claude'
  Copy-Tree (Join-Path $src '.claude-plugin') (Join-Path $TargetRoot '.claude-plugin')
  # project-level hooks under .claude/hooks for clarity
  Copy-Tree (Join-Path $src 'hooks') (Join-Path $TargetRoot '.claude\hooks')
  $common = Join-Path $Templates 'common'
  Place-File (Join-Path $common 'CLAUDE.md.template') (Join-Path $TargetRoot 'CLAUDE.md') -Render
  $docs = Join-Path $TargetRoot 'docs\ai-framework'
  Ensure-Dir $docs
  Place-File (Join-Path $src 'INSTALL.md') (Join-Path $docs 'claude-INSTALL.md')
}

function Install-Others {
  Write-Log "=== Others ==="
  $src = Join-Path $Templates 'others'
  $docs = Join-Path $TargetRoot 'docs\ai-framework\others'
  Ensure-Dir $docs
  Copy-Tree $src $docs
}

Write-Log "SkillRoot  = $SkillRoot"
Write-Log "TargetRoot = $TargetRoot"
Write-Log "Tool       = $Tool"
Write-Log "ProjectName= $ProjectName"
Write-Log "CssPrefix  = $CssPrefix"
Write-Log "Conflict   = $Conflict"
Write-Log ""

switch ($Tool) {
  'opencode' { Install-OpenCode }
  'codex' { Install-Codex }
  'claude' { Install-Claude }
  'all' {
    Install-OpenCode
    Install-Codex
    Install-Claude
  }
  'others' { Install-Others }
}

Write-Log ""
Write-Log "Done. Reload your IDE / agent session if needed."
Write-Log "Global harness dirs were NOT modified."
