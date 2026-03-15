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

$hostName = "OpenCode"
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
    Join-Path $HOME ".config/opencode/skill"
}
else {
    Join-Path $ProjectRoot ".opencode/skill"
}

$agentsPath = if ($Scope -eq "User") {
    Join-Path $HOME ".config/opencode/AGENTS.md"
}
else {
    Join-Path $ProjectRoot "AGENTS.md"
}

$overlayRoot = Join-Path $repoRoot "templates/opencode/skill-overlays"
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
$skillBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "OpenCode" -Subdirectory "skills"
$fileBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "OpenCode" -Subdirectory "files"
$legacyBackupRoot = Get-HostBackupRoot -BackupSessionRoot $BackupSessionRoot -HostName "OpenCode" -Subdirectory "legacy-skill-backups"
$metadataRoot = Split-Path -Parent $targetSkillRoot

Ensure-Directory -Path $targetSkillRoot
Show-HostStep -HostName $hostName -Message "检查旧版备份目录..."
Move-LegacyBackupDirectories -HostName "OpenCode" -TargetRoot $targetSkillRoot -BackupRoot $legacyBackupRoot | Out-Null

$skillDirectories = Get-UpstreamSkillDirectories -SourceRoot $sourceRoot
$installed = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
$existingInstalledSkills = @(
    foreach ($skillDirectory in $skillDirectories) {
        $installedName = Get-InstalledSkillName -OriginalName $skillDirectory.Name -NamePrefix $NamePrefix
        $targetSkillPath = Join-Path $targetSkillRoot ("{0}.md" -f $installedName)
        $targetResourcePath = Join-Path $targetSkillRoot $installedName

        if ((Test-Path -LiteralPath $targetSkillPath) -or (Test-Path -LiteralPath $targetResourcePath)) {
            $installedName
        }
    }
)
$existingSkillTargets = @(
    foreach ($skillDirectory in $skillDirectories) {
        $installedName = Get-InstalledSkillName -OriginalName $skillDirectory.Name -NamePrefix $NamePrefix
        $targetSkillPath = Join-Path $targetSkillRoot ("{0}.md" -f $installedName)
        $targetResourcePath = Join-Path $targetSkillRoot $installedName

        if (Test-Path -LiteralPath $targetSkillPath) { $targetSkillPath }
        if (Test-Path -LiteralPath $targetResourcePath) { $targetResourcePath }
    }
)
$sourceVersionInfo = Get-SuperpowersSourceVersionInfo -SourceRoot $sourceRoot -RepositoryUrl $RepositoryUrl
$currentInstalledVersion = Get-InstalledSuperpowersVersionText `
    -MetadataRoot $metadataRoot `
    -HasExistingInstall:($existingInstalledSkills.Count -gt 0)
Show-HostStep -HostName $hostName -Message "检查版本信息..."
Show-SuperpowersVersionBanner `
    -HostName "OpenCode" `
    -CurrentInstalledVersion $currentInstalledVersion `
    -PlannedVersion ([string]$sourceVersionInfo["Display"])
$overwriteExistingSkills = Resolve-ExistingSkillAction `
    -HostName "OpenCode" `
    -ExistingPaths $existingSkillTargets `
    -DisplayCount $existingInstalledSkills.Count `
    -Force:$Force `
    -AssumeYes:$AssumeYes

if ($overwriteExistingSkills) {
    Show-HostStep -HostName $hostName -Message "备份已有 skill..."
    Backup-ExistingTargets -HostName "OpenCode" -Paths $existingSkillTargets -BackupRoot $skillBackupRoot | Out-Null
}

Show-HostStep -HostName $hostName -Message "开始安装 skill..."
foreach ($skillDirectory in $skillDirectories) {
    $installedName = Get-InstalledSkillName -OriginalName $skillDirectory.Name -NamePrefix $NamePrefix
    $targetSkillPath = Join-Path $targetSkillRoot ("{0}.md" -f $installedName)
    $targetResourcePath = Join-Path $targetSkillRoot $installedName

    if ((Test-Path -LiteralPath $targetSkillPath) -or (Test-Path -LiteralPath $targetResourcePath)) {
        if ($overwriteExistingSkills) {
            Remove-ExistingTarget -Path $targetSkillPath -AssumeYes:$AssumeYes
            Remove-ExistingTarget -Path $targetResourcePath -AssumeYes:$AssumeYes
        }
        else {
            $skipped.Add($installedName)
            continue
        }
    }

    $sourceSkillFile = Join-Path $skillDirectory.FullName "SKILL.md"
    $overlayContent = Get-OverlayContent `
        -TemplateRoot $overlayRoot `
        -OriginalSkillName $skillDirectory.Name `
        -Tokens @{ NAME_PREFIX = $NamePrefix }
    $triggerEntry = Get-SkillTriggerEntry `
        -TriggerData $triggerData `
        -OriginalSkillName $skillDirectory.Name

    if ($InstallMode -eq "Copy") {
        Copy-DirectoryContents -SourcePath $skillDirectory.FullName -TargetPath $targetResourcePath
    }
    else {
        New-Item -ItemType Junction -Path $targetResourcePath -Target $skillDirectory.FullName | Out-Null
    }

    if (Test-Path -LiteralPath $sourceSkillFile) {
        $skillMarkdown = Convert-SuperpowersSkillToSingleFileMarkdown `
            -SkillFilePath $sourceSkillFile `
            -InstalledName $installedName `
            -OriginalName $skillDirectory.Name `
            -ResourceRoot $installedName `
            -OverlayContent $overlayContent `
            -OverlayHeading "OpenCode Adaptation"

        Write-TextFileWithRetry -Path $targetSkillPath -Value $skillMarkdown -Purpose "写入 OpenCode skill 入口文件"

        if (-not [string]::IsNullOrWhiteSpace($NamePrefix)) {
            Rename-SkillFrontMatter -SkillFilePath $targetSkillPath -NewName $installedName
        }

        if ($triggerEntry) {
            Add-SkillDescriptionTriggerHints `
                -SkillFilePath $targetSkillPath `
                -TriggerEntry $triggerEntry
        }
    }

    $installed.Add($installedName)
}

$agentsBlock = Expand-TemplateFile `
    -TemplatePath (Join-Path $repoRoot "templates/opencode/AGENTS.block.md") `
    -Tokens @{
        NAME_PREFIX = $NamePrefix
    }

$triggerGuide = New-DroidChineseTriggerGuide -TriggerData $triggerData -NamePrefix $NamePrefix
if (-not [string]::IsNullOrWhiteSpace($triggerGuide)) {
    $agentsBlock = $agentsBlock.TrimEnd() + "`n`n" + $triggerGuide
}

Show-HostStep -HostName $hostName -Message "备份并更新 AGENTS.md..."
Backup-ExistingFile -Path $agentsPath -Reason "更新 OpenCode 的 AGENTS.md 中 superpowers 说明段前先备份。" -BackupRoot $fileBackupRoot | Out-Null

Upsert-ManagedBlock `
    -Path $agentsPath `
    -BlockId "superpowers-opencode" `
    -Content $agentsBlock

$versionInfoToRecord = $null
if (($existingInstalledSkills.Count -gt 0) -and (-not $overwriteExistingSkills)) {
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
        -HostName "OpenCode" `
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
