<#
.SYNOPSIS
  Install AI framework templates into a project root (project-level only).

.PARAMETER TargetRoot
  Destination project root.

.PARAMETER Tool
  opencode | codex | claude | all | others | jspace

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
  [ValidateSet('opencode', 'codex', 'claude', 'all', 'others', 'jspace')]
  [string]$Tool,

  [string]$ProjectName = '',
  [string]$CssPrefix = 'app',
  [string]$VisionModel = 'oc-local/mimo-v2.5',
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

function Ensure-Dir {
  param([string]$Dir)
  if ([string]::IsNullOrWhiteSpace($Dir)) { return }
  if (-not [System.IO.Directory]::Exists($Dir)) {
    [void][System.IO.Directory]::CreateDirectory($Dir)
  }
}

function Render-Text([string]$text) {
  return $text.Replace('{{PROJECT_NAME}}', $ProjectName).Replace('{{CSS_PREFIX}}', $CssPrefix).Replace('{{VISION_MODEL}}', $VisionModel)
}

function Place-File {
  param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$DestPath,
    [switch]$Render
  )

  if (-not [System.IO.File]::Exists($SourcePath)) {
    Write-Log "MISSING source $SourcePath"
    return
  }

  $parentDir = [System.IO.Path]::GetDirectoryName($DestPath)
  Ensure-Dir -Dir $parentDir

  if ([System.IO.File]::Exists($DestPath)) {
    switch ($Conflict) {
      'skip' {
        Write-Log "SKIP  $DestPath"
        return
      }
      'backup' {
        $bak = "$DestPath.bak"
        [System.IO.File]::Copy($DestPath, $bak, $true)
        Write-Log "BACKUP $DestPath -> $bak"
      }
      'overwrite' {
        Write-Log "OVERWRITE $DestPath"
      }
    }
  }

  if ($Render) {
    $raw = [System.IO.File]::ReadAllText($SourcePath, [System.Text.UTF8Encoding]::new($false))
    $out = Render-Text $raw
    [System.IO.File]::WriteAllText($DestPath, $out, [System.Text.UTF8Encoding]::new($false))
  } else {
    [System.IO.File]::Copy($SourcePath, $DestPath, $true)
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
  Get-ChildItem -LiteralPath $SourceDir -Recurse -File | Where-Object {
    $_.FullName -notmatch '__pycache__' -and $_.Extension -ne '.pyc'
  } | ForEach-Object {
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
  Ensure-Dir -Dir $dst
  Place-File -SourcePath (Join-Path $src 'opencode.jsonc') -DestPath (Join-Path $dst 'opencode.jsonc')
  Copy-Tree (Join-Path $src 'agents') (Join-Path $dst 'agents') -RenderMarkdown
  Copy-Tree (Join-Path $src 'commands') (Join-Path $dst 'commands') -RenderMarkdown
  # 视觉子代理配套桥脚本（python，不渲染）
  if (Test-Path (Join-Path $src 'scripts')) {
    Copy-Tree (Join-Path $src 'scripts') (Join-Path $dst 'scripts')
  }

  $common = Join-Path $Templates 'common'
  Place-File -SourcePath (Join-Path $common 'AGENTS.md.template') -DestPath (Join-Path $TargetRoot 'AGENTS.md') -Render
  Place-File -SourcePath (Join-Path $common 'CODE_REVIEW.md') -DestPath (Join-Path $TargetRoot 'CODE_REVIEW.md')
  Place-File -SourcePath (Join-Path $common 'coding-standards.md.template') -DestPath (Join-Path $TargetRoot 'coding-standards.md') -Render
  Place-File -SourcePath (Join-Path $common 'architecture.md.template') -DestPath (Join-Path $TargetRoot 'architecture.md') -Render

  # 阶段化计划驱动（元规范 + 空白计划模板 + plans 目录）
  # 使用 Combine，避免 Join-Path 多段 ChildPath 在部分主机上异常
  $afDocs = [System.IO.Path]::Combine($TargetRoot, 'docs', 'ai-framework')
  $afPlans = [System.IO.Path]::Combine($afDocs, 'plans')
  Ensure-Dir -Dir $afPlans
  $commonDocs = [System.IO.Path]::Combine($common, 'docs')
  Place-File -SourcePath ([System.IO.Path]::Combine($commonDocs, 'phased-plan-driven.md.template')) -DestPath ([System.IO.Path]::Combine($afDocs, 'phased-plan-driven.md')) -Render
  Place-File -SourcePath ([System.IO.Path]::Combine($commonDocs, 'phase-plan.template.md')) -DestPath ([System.IO.Path]::Combine($afDocs, 'phase-plan.template.md')) -Render
  Place-File -SourcePath ([System.IO.Path]::Combine($commonDocs, 'plan-layering.md.template')) -DestPath ([System.IO.Path]::Combine($afDocs, 'plan-layering.md')) -Render
  Place-File -SourcePath ([System.IO.Path]::Combine($commonDocs, 'plans-README.md.template')) -DestPath ([System.IO.Path]::Combine($afPlans, 'README.md')) -Render
}

function Install-Codex {
  Write-Log "=== Codex ==="
  $src = Join-Path $Templates 'codex'
  Copy-Tree (Join-Path $src '.codex-plugin') (Join-Path $TargetRoot '.codex-plugin')
  $docs = [System.IO.Path]::Combine($TargetRoot, 'docs', 'ai-framework')
  Ensure-Dir -Dir $docs
  $codexTools = [System.IO.Path]::Combine($src, 'references', 'codex-tools.md')
  if (Test-Path -LiteralPath $codexTools) {
    Place-File -SourcePath $codexTools -DestPath ([System.IO.Path]::Combine($docs, 'codex-tools.md'))
  }
  Place-File -SourcePath (Join-Path $src 'INSTALL.md') -DestPath ([System.IO.Path]::Combine($docs, 'codex-INSTALL.md'))
}

function Install-Claude {
  Write-Log "=== Claude ==="
  $src = Join-Path $Templates 'claude'
  Copy-Tree (Join-Path $src '.claude-plugin') (Join-Path $TargetRoot '.claude-plugin')
  # project-level hooks under .claude/hooks for clarity
  Copy-Tree (Join-Path $src 'hooks') (Join-Path $TargetRoot '.claude\hooks')
  $common = Join-Path $Templates 'common'
  Place-File -SourcePath (Join-Path $common 'CLAUDE.md.template') -DestPath (Join-Path $TargetRoot 'CLAUDE.md') -Render
  $docs = [System.IO.Path]::Combine($TargetRoot, 'docs', 'ai-framework')
  Ensure-Dir -Dir $docs
  Place-File -SourcePath (Join-Path $src 'INSTALL.md') -DestPath ([System.IO.Path]::Combine($docs, 'claude-INSTALL.md'))
}

function Install-Others {
  Write-Log "=== Others ==="
  $src = Join-Path $Templates 'others'
  $docs = [System.IO.Path]::Combine($TargetRoot, 'docs', 'ai-framework', 'others')
  Ensure-Dir -Dir $docs
  Copy-Tree $src $docs
}

function Install-JSpace {
  Write-Log "=== J-Space (project-level skill) ==="
  $src = Join-Path $Templates 'j-space'
  $dst = [System.IO.Path]::Combine($TargetRoot, '.grok', 'skills', 'j-space')
  if (-not (Test-Path -LiteralPath $src)) {
    Write-Log "MISSING source $src"
    return
  }
  if (Test-Path -LiteralPath $dst) {
    switch ($Conflict) {
      'skip' {
        Write-Log "SKIP  $dst"
        return
      }
      'backup' {
        $bak = "$dst.bak"
        if (Test-Path -LiteralPath $bak) { Remove-Item -LiteralPath $bak -Recurse -Force }
        Rename-Item -LiteralPath $dst -NewName ([System.IO.Path]::GetFileName($bak))
        Write-Log "BACKUP $dst -> $bak"
      }
      'overwrite' {
        Write-Log "OVERWRITE $dst"
        Remove-Item -LiteralPath $dst -Recurse -Force
      }
    }
  }
  Ensure-Dir -Dir ([System.IO.Path]::GetDirectoryName($dst))
  Copy-Item -LiteralPath $src -Destination $dst -Recurse
  Write-Log "WRITE $dst"

  # 桥接文档（J-Space × 阶段化计划驱动）：进 docs/ai-framework/，随仓库走
  $bridgeDoc = [System.IO.Path]::Combine($TargetRoot, 'docs', 'ai-framework', 'j-space-bridge.md')
  Place-File -SourcePath (Join-Path $Templates (Join-Path 'common' (Join-Path 'docs' 'j-space-bridge.md.template'))) -DestPath $bridgeDoc -Render

  # 默认启用规则（Grok 常驻）：进 .grok/rules/，装上即默认
  $rulesDir = [System.IO.Path]::Combine($TargetRoot, '.grok', 'rules')
  Ensure-Dir -Dir $rulesDir
  $rulesFile = Join-Path $src 'rules\j-space-default.md'
  if (Test-Path -LiteralPath $rulesFile) {
    Place-File -SourcePath $rulesFile -DestPath ([System.IO.Path]::Combine($rulesDir, 'j-space-default.md'))
  }
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
    Install-JSpace
  }
  'others' { Install-Others }
  'jspace' { Install-JSpace }
}

Write-Log ""
Write-Log "Done. Reload your IDE / agent session if needed."
Write-Log "Global harness dirs were NOT modified."
