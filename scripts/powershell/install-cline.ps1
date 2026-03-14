[CmdletBinding()]
param(
    [ValidateSet("User", "Project")]
    [string]$Scope = "User",
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$SourcePath,
    [string]$VendorRoot,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [switch]$UpdateSource,
    [string]$NamePrefix = "superpowers-",
    [switch]$Force,
    [switch]$AssumeYes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking
Assert-WindowsOnly

$bundledVendorRoot = Join-Path $repoRoot "vendor/superpowers"

if ($Scope -eq "Project") {
    $ProjectRoot = Resolve-AbsolutePath -Path $ProjectRoot
}
else {
    $ProjectRoot = $null
}

if (-not $VendorRoot) {
    if ((-not $SourcePath) -and (Test-Path -LiteralPath (Join-Path $bundledVendorRoot "skills"))) {
        $VendorRoot = $bundledVendorRoot
    }
    else {
        $VendorRoot = if ($Scope -eq "User") {
            Join-Path $HOME ".superpowers/upstream"
        }
        else {
            Join-Path $ProjectRoot ".superpowers/upstream"
        }
    }
}

$sourceRoot = Resolve-SuperpowersSource `
    -SourcePath $SourcePath `
    -VendorRoot $VendorRoot `
    -RepositoryUrl $RepositoryUrl `
    -UpdateSource:$UpdateSource

$targetSkillRoot = if ($Scope -eq "User") {
    Join-Path $HOME ".cline/skills"
}
else {
    Join-Path $ProjectRoot ".cline/skills"
}

$targetRuleRoot = if ($Scope -eq "User") {
    Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Cline/Rules"
}
else {
    Join-Path $ProjectRoot ".clinerules"
}

$overlayRoot = Join-Path $repoRoot "templates/cline/skill-overlays"
$triggerDataPath = Join-Path $repoRoot "data/zh-cn-skill-triggers.json"
$triggerData = Get-SkillTriggerData -DataPath $triggerDataPath
$ruleFileNames = @{
    Bootstrap = "90-superpowers-bootstrap.md"
    Trigger   = "91-superpowers-skill-triggers-zh-cn.md"
    Output    = "92-superpowers-output-docs-zh-cn.md"
}
$legacyRuleFileNames = @(
    "00-superpowers-bootstrap.md",
    "05-skill-triggers-zh-cn.md",
    "10-output-docs-zh-cn.md"
)
$metadataRoot = Split-Path -Parent $targetSkillRoot

Ensure-Directory -Path $targetSkillRoot
Ensure-Directory -Path $targetRuleRoot

$skillDirectories = Get-UpstreamSkillDirectories -SourceRoot $sourceRoot
$installed = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
$existingSkillTargets = @(
    $skillDirectories | ForEach-Object {
        Join-Path $targetSkillRoot (Get-InstalledSkillName -OriginalName $_.Name -NamePrefix $NamePrefix)
    } | Where-Object { Test-Path -LiteralPath $_ }
)
$sourceVersionInfo = Get-SuperpowersSourceVersionInfo -SourceRoot $sourceRoot -RepositoryUrl $RepositoryUrl
$currentInstalledVersion = Get-InstalledSuperpowersVersionText `
    -MetadataRoot $metadataRoot `
    -HasExistingInstall:($existingSkillTargets.Count -gt 0)
Show-SuperpowersVersionBanner `
    -HostName "Cline" `
    -CurrentInstalledVersion $currentInstalledVersion `
    -PlannedVersion ([string]$sourceVersionInfo["Display"])
$overwriteExistingSkills = Resolve-ExistingSkillAction `
    -HostName "Cline" `
    -ExistingPaths $existingSkillTargets `
    -Force:$Force `
    -AssumeYes:$AssumeYes

if ($overwriteExistingSkills) {
    Backup-ExistingTargets -HostName "Cline" -Paths $existingSkillTargets | Out-Null
}

foreach ($skillDirectory in $skillDirectories) {
    $installedName = Get-InstalledSkillName -OriginalName $skillDirectory.Name -NamePrefix $NamePrefix
    $targetSkillPath = Join-Path $targetSkillRoot $installedName

    if (Test-Path -LiteralPath $targetSkillPath) {
        if ($overwriteExistingSkills) {
            Remove-ExistingTarget -Path $targetSkillPath -AssumeYes:$AssumeYes
        }
        else {
            $skipped.Add($installedName)
            continue
        }
    }

    Copy-DirectoryContents -SourcePath $skillDirectory.FullName -TargetPath $targetSkillPath

    $sourceSkillFile = Join-Path $skillDirectory.FullName "SKILL.md"
    if (Test-Path -LiteralPath $sourceSkillFile) {
        $overlayContent = Get-OverlayContent `
            -TemplateRoot $overlayRoot `
            -OriginalSkillName $skillDirectory.Name `
            -Tokens @{ NAME_PREFIX = $NamePrefix }

        $prompt = Convert-SuperpowersSkillToClinePrompt `
            -SkillFilePath $sourceSkillFile `
            -InstalledName $installedName `
            -OriginalName $skillDirectory.Name `
            -OverlayContent $overlayContent

        Set-Content -LiteralPath (Join-Path $targetSkillPath "prompt.md") -Value $prompt -Encoding utf8
    }

    $installed.Add($installedName)
}

$tokens = @{
    NAME_PREFIX = $NamePrefix
}

foreach ($legacyRuleFileName in $legacyRuleFileNames) {
    $legacyRulePath = Join-Path $targetRuleRoot $legacyRuleFileName
    if (Test-Path -LiteralPath $legacyRulePath) {
        Backup-ExistingFile -Path $legacyRulePath -Reason "准备人工检查旧版 Cline 规则文件，先备份。" | Out-Null

        Confirm-UserMergeAction `
            -Title "发现旧版 Cline 规则文件：$legacyRulePath" `
            -Guidance @"
新版本会把 superpowers 规则写到这 3 个新文件里：
- 90-superpowers-bootstrap.md
- 91-superpowers-skill-triggers-zh-cn.md
- 92-superpowers-output-docs-zh-cn.md

旧版本常见的是这 3 个文件：
- 00-superpowers-bootstrap.md
- 05-skill-triggers-zh-cn.md
- 10-output-docs-zh-cn.md

脚本不会替你删旧文件，避免误删你自己的内容。

建议你先这样处理：
1. 先备份旧文件
2. 看一下旧文件里是不是你自己写过规则
3. 如果只是旧版 superpowers 生成的，安装完成后手动删掉
4. 如果里面有你自己的内容，就自己合并到别的规则文件里
"@ `
            -AssumeYes:$AssumeYes
    }
}

$managedRulePaths = @(
    (Join-Path $targetRuleRoot $ruleFileNames.Bootstrap),
    (Join-Path $targetRuleRoot $ruleFileNames.Trigger),
    (Join-Path $targetRuleRoot $ruleFileNames.Output)
)

foreach ($managedRulePath in $managedRulePaths) {
    Backup-ExistingFile -Path $managedRulePath -Reason "更新 Cline 专用 superpowers 规则文件前先备份。" | Out-Null
}

$bootstrapRule = Expand-TemplateFile `
    -TemplatePath (Join-Path $repoRoot "templates/cline/rules/00-superpowers-bootstrap.md") `
    -Tokens $tokens
Set-Content -LiteralPath (Join-Path $targetRuleRoot $ruleFileNames.Bootstrap) -Value $bootstrapRule -Encoding utf8

$outputRule = Expand-TemplateFile `
    -TemplatePath (Join-Path $repoRoot "templates/cline/rules/10-output-docs-zh-cn.md") `
    -Tokens $tokens
Set-Content -LiteralPath (Join-Path $targetRuleRoot $ruleFileNames.Output) -Value $outputRule -Encoding utf8

$triggerRule = New-ClineChineseTriggerRule -TriggerData $triggerData -NamePrefix $NamePrefix
Set-Content -LiteralPath (Join-Path $targetRuleRoot $ruleFileNames.Trigger) -Value $triggerRule -Encoding utf8

$versionInfoToRecord = $null
if (($existingSkillTargets.Count -gt 0) -and (-not $overwriteExistingSkills)) {
    if ($installed.Count -gt 0) {
        $versionInfoToRecord = @{
            Display = "混合版本（保留旧安装，只补装了缺少的 skill）"
            Commit = ""
            CommitShort = ""
            Ref = ""
            RepositoryUrl = [string]$sourceVersionInfo["RepositoryUrl"]
            IsKnown = $false
        }
    }
}
else {
    $versionInfoToRecord = $sourceVersionInfo
}

if ($versionInfoToRecord) {
    Save-SuperpowersInstallMetadata `
        -MetadataRoot $metadataRoot `
        -HostName "Cline" `
        -VersionInfo $versionInfoToRecord `
        -SourceRoot $sourceRoot `
        -SkillCount ($installed.Count + $skipped.Count) `
        -NamePrefix $NamePrefix
}

Write-Host ""
Write-Host "Cline 安装完成。"
Write-Host "来源：        $sourceRoot"
Write-Host "Skill 目录：   $targetSkillRoot"
Write-Host "规则目录：     $targetRuleRoot"
Write-Host "规则文件：     $($ruleFileNames.Bootstrap), $($ruleFileNames.Trigger), $($ruleFileNames.Output)"
Write-Host "已安装：       $($installed.Count)"
Write-Host "已跳过：       $($skipped.Count)"
