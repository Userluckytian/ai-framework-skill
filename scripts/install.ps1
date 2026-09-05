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

function Install-IssueLog {
  # 按天问题日志（强制）：约定文档。入口文档（AGENTS/CLAUDE）会引用 docs/issue-log/README.md
  $issueLog = [System.IO.Path]::Combine($TargetRoot, 'docs', 'issue-log')
  Ensure-Dir -Dir $issueLog
  $commonDocs = Join-Path $Templates 'common\docs'
  Place-File -SourcePath ([System.IO.Path]::Combine($commonDocs, 'issue-log-README.md.template')) -DestPath ([System.IO.Path]::Combine($issueLog, 'README.md')) -Render
  # 开放事项索引（只放未关闭项，AI 每天开工第一读）
  Place-File -SourcePath ([System.IO.Path]::Combine($commonDocs, 'issue-log-OPEN.md.template')) -DestPath ([System.IO.Path]::Combine($issueLog, 'OPEN.md')) -Render

  # 入库策略：只入库 README.md，每日日志不入库（自动写入/追加 .gitignore）
  $gi = [System.IO.Path]::Combine($TargetRoot, '.gitignore')
  $giBlock = '# 按天问题日志（只入库约定文档 README.md，每日日志本地保留不入库）'
  $giRule = "docs/issue-log/*`n!docs/issue-log/README.md"
  if (-not [System.IO.File]::Exists($gi)) {
    $content = "# ai-framework: 按天问题日志入库策略`n$giBlock`n$giRule`n"
    [System.IO.File]::WriteAllText($gi, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Log "WRITE $gi (created with issue-log ignore rule)"
  } elseif (-not ([System.IO.File]::ReadAllText($gi) -match 'docs/issue-log/\*')) {
    $content = "`n# ai-framework: 按天问题日志入库策略`n$giBlock`n$giRule`n"
    [System.IO.File]::AppendAllText($gi, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Log "APPEND $gi (issue-log ignore rule)"
  } else {
    Write-Log "SKIP  $gi (issue-log ignore rule already present)"
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

  # 子代理脚手架（配 /new-agent 命令生成项目专属 agent）
  Place-File -SourcePath ([System.IO.Path]::Combine($commonDocs, 'agent.template.md')) -DestPath ([System.IO.Path]::Combine($afDocs, 'agent.template.md')) -Render

  Install-IssueLog
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
  Install-IssueLog
}

function Install-Others {
  Write-Log "=== Others ==="
  $src = Join-Path $Templates 'others'
  $docs = [System.IO.Path]::Combine($TargetRoot, 'docs', 'ai-framework', 'others')
  Ensure-Dir -Dir $docs
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
