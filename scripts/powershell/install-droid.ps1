[CmdletBinding()]
param(
    [ValidateSet("User", "Project")]
    [string]$Scope = "User",
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$SourcePath,
    [string]$VendorRoot,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [switch]$UpdateSource,
    [ValidateSet("Copy", "Junction")]
    [string]$InstallMode = "Copy",
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

$hostName = "Droid"
Show-HostSectionStart -HostName $hostName

$bundledVendorRoot = Join-Path $repoRoot "vendor/superpowers"

if ($Scope -eq "Project") {
    $ProjectRoot = Resolve-AbsolutePath -Path $ProjectRoot
}
else {
    $ProjectRoot = $null
}

if ($InstallMode -eq "Junction" -and -not [string]::IsNullOrWhiteSpace($NamePrefix)) {
    throw "Junction 模式下不能重命名已安装的 skill。请改用 -NamePrefix ''，或者切换到 -InstallMode Copy。"
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
    Join-Path $HOME ".factory/skills"
}
else {
    Join-Path $ProjectRoot ".factory/skills"
}

$agentsPath = if ($Scope -eq "User") {
    Join-Path $HOME ".factory/AGENTS.md"
}
else {
    Join-Path $ProjectRoot "AGENTS.md"
}

$overlayRoot = Join-Path $repoRoot "templates/droid/skill-overlays"
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
$skillBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "Droid" -Subdirectory "skills"
$fileBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "Droid" -Subdirectory "files"
$legacyBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "Droid" -Subdirectory "legacy-skill-backups"
$metadataRoot = Split-Path -Parent $targetSkillRoot

Ensure-Directory -Path $targetSkillRoot
Show-HostStep -HostName $hostName -Message "检查旧版备份目录..."
Move-LegacyBackupDirectories -HostName "Droid" -TargetRoot $targetSkillRoot -BackupRoot $legacyBackupRoot | Out-Null

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
    -HostName "Droid" `
    -CurrentInstalledVersion $currentInstalledVersion `
    -PlannedVersion ([string]$sourceVersionInfo["Display"])
$overwriteExistingSkills = Resolve-ExistingSkillAction `
    -HostName "Droid" `
    -ExistingPaths $existingSkillTargets `
    -Force:$Force `
    -AssumeYes:$AssumeYes

if ($overwriteExistingSkills) {
    Show-HostStep -HostName $hostName -Message "备份已有 skill..."
    Backup-ExistingTargets -HostName "Droid" -Paths $existingSkillTargets -BackupRoot $skillBackupRoot | Out-Null
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

    if ($InstallMode -eq "Copy") {
        Copy-DirectoryContents -SourcePath $skillDirectory.FullName -TargetPath $targetSkillPath

        $skillFilePath = Join-Path $targetSkillPath "SKILL.md"
        if (Test-Path -LiteralPath $skillFilePath) {
            $overlayContent = Get-OverlayContent `
                -TemplateRoot $overlayRoot `
                -OriginalSkillName $skillDirectory.Name `
                -Tokens @{ NAME_PREFIX = $NamePrefix }
            $triggerEntry = Get-SkillTriggerEntry `
                -TriggerData $triggerData `
                -OriginalSkillName $skillDirectory.Name

            if (-not [string]::IsNullOrWhiteSpace($NamePrefix)) {
                Rename-SkillFrontMatter -SkillFilePath $skillFilePath -NewName $installedName
            }

            if ($triggerEntry) {
                Add-SkillDescriptionTriggerHints `
                    -SkillFilePath $skillFilePath `
                    -TriggerEntry $triggerEntry
            }

            if (-not [string]::IsNullOrWhiteSpace($overlayContent)) {
                Append-SkillOverlay `
                    -SkillFilePath $skillFilePath `
                    -OverlayContent $overlayContent `
                    -Heading "Factory Adaptation"
            }
        }
    }
    else {
        New-Item -ItemType Junction -Path $targetSkillPath -Target $skillDirectory.FullName | Out-Null
    }

    $installed.Add($installedName)
}

$agentsBlock = Expand-TemplateFile `
    -TemplatePath (Join-Path $repoRoot "templates/droid/AGENTS.block.md") `
    -Tokens @{
        NAME_PREFIX = $NamePrefix
    }
$triggerGuide = New-DroidChineseTriggerGuide -TriggerData $triggerData -NamePrefix $NamePrefix
if (-not [string]::IsNullOrWhiteSpace($triggerGuide)) {
    $agentsBlock = $agentsBlock.TrimEnd() + "`n`n" + $triggerGuide
}

Show-HostStep -HostName $hostName -Message "备份并更新 AGENTS.md..."
Backup-ExistingFile -Path $agentsPath -Reason "更新 Droid 的 AGENTS.md 中 superpowers 说明段前先备份。" -BackupRoot $fileBackupRoot | Out-Null

Upsert-ManagedBlock `
    -Path $agentsPath `
    -BlockId "superpowers-compat" `
    -Content $agentsBlock

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
        -HostName "Droid" `
        -VersionInfo $versionInfoToRecord `
        -SourceRoot $sourceRoot `
        -SkillCount ($installed.Count + $skipped.Count) `
        -NamePrefix $NamePrefix
}

Write-Host ""
Write-Host ("[{0}] 安装已完成。" -f $hostName)
Write-Host "来源：        $sourceRoot"
Write-Host "Skill 目录：   $targetSkillRoot"
Write-Host "AGENTS.md：   $agentsPath"
Write-Host "已安装：       $($installed.Count)"
Write-Host "已跳过：       $($skipped.Count)"
