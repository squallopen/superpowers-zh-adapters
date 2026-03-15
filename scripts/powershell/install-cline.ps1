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
    [string]$BackupSessionRoot,
    [switch]$Force,
    [switch]$AssumeYes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

. (Join-Path $PSScriptRoot "Assert-Pwsh7.ps1")
Exit-IfUnsupportedPowerShell -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking
Assert-WindowsOnly

$hostName = "Cline"
Show-HostSectionStart -HostName $hostName

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
$backupSessionBase = if ($Scope -eq "User") {
    Join-Path $HOME ".superpowers-backups"
}
else {
    Join-Path $ProjectRoot ".superpowers-backups"
}
$backupSessionWasProvided = -not [string]::IsNullOrWhiteSpace($BackupSessionRoot)
$BackupSessionRoot = Resolve-BackupSessionRoot -BaseRoot $backupSessionBase -BackupSessionRoot $BackupSessionRoot
if (-not $backupSessionWasProvided) {
    Write-Host ("本次备份目录：{0}" -f $BackupSessionRoot)
}
$skillBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "Cline" -Subdirectory "skills"
$fileBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "Cline" -Subdirectory "files"
$legacyBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "Cline" -Subdirectory "legacy-skill-backups"
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
Show-HostStep -HostName $hostName -Message "检查旧版备份目录..."
Move-LegacyBackupDirectories -HostName "Cline" -TargetRoot $targetSkillRoot -BackupRoot $legacyBackupRoot | Out-Null

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
Show-HostStep -HostName $hostName -Message "检查版本信息..."
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
    Show-HostStep -HostName $hostName -Message "备份已有 skill..."
    Backup-ExistingTargets -HostName "Cline" -Paths $existingSkillTargets -BackupRoot $skillBackupRoot | Out-Null
}

Show-HostStep -HostName $hostName -Message "开始安装 skill..."
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

        Write-TextFileWithRetry -Path (Join-Path $targetSkillPath "prompt.md") -Value $prompt -Purpose "写入 Cline prompt"
    }

    $installed.Add($installedName)
}

$tokens = @{
    NAME_PREFIX = $NamePrefix
}

foreach ($legacyRuleFileName in $legacyRuleFileNames) {
    $legacyRulePath = Join-Path $targetRuleRoot $legacyRuleFileName
    if (Test-Path -LiteralPath $legacyRulePath) {
        Show-HostStep -HostName $hostName -Message "备份旧版 Cline 规则文件..."
        Backup-ExistingFile -Path $legacyRulePath -Reason "准备人工检查旧版 Cline 规则文件，先备份。" -BackupRoot $fileBackupRoot | Out-Null

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
    Show-HostStep -HostName $hostName -Message "备份并更新 Cline 规则文件..."
    Backup-ExistingFile -Path $managedRulePath -Reason "更新 Cline 专用 superpowers 规则文件前先备份。" -BackupRoot $fileBackupRoot | Out-Null
}

$bootstrapRule = Expand-TemplateFile `
    -TemplatePath (Join-Path $repoRoot "templates/cline/rules/00-superpowers-bootstrap.md") `
    -Tokens $tokens
Write-TextFileWithRetry -Path (Join-Path $targetRuleRoot $ruleFileNames.Bootstrap) -Value $bootstrapRule -Purpose "写入 Cline bootstrap 规则"

$outputRule = Expand-TemplateFile `
    -TemplatePath (Join-Path $repoRoot "templates/cline/rules/10-output-docs-zh-cn.md") `
    -Tokens $tokens
Write-TextFileWithRetry -Path (Join-Path $targetRuleRoot $ruleFileNames.Output) -Value $outputRule -Purpose "写入 Cline 中文输出规则"

$triggerRule = New-ClineChineseTriggerRule -TriggerData $triggerData -NamePrefix $NamePrefix
Write-TextFileWithRetry -Path (Join-Path $targetRuleRoot $ruleFileNames.Trigger) -Value $triggerRule -Purpose "写入 Cline 中文触发规则"

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
Write-Host ("[{0}] 安装已完成。" -f $hostName)
Write-Host "来源：        $sourceRoot"
Write-Host "Skill 目录：   $targetSkillRoot"
Write-Host "规则目录：     $targetRuleRoot"
Write-Host "规则文件：     $($ruleFileNames.Bootstrap), $($ruleFileNames.Trigger), $($ruleFileNames.Output)"
Write-Host "已安装：       $($installed.Count)"
Write-Host "已跳过：       $($skipped.Count)"
