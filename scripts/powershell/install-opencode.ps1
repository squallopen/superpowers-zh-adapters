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
$metadataRoot = Split-Path -Parent $targetSkillRoot

Ensure-Directory -Path $targetSkillRoot

$skillDirectories = Get-UpstreamSkillDirectories -SourceRoot $sourceRoot
$installed = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
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
    -HasExistingInstall:($existingSkillTargets.Count -gt 0)
Show-SuperpowersVersionBanner `
    -HostName "OpenCode" `
    -CurrentInstalledVersion $currentInstalledVersion `
    -PlannedVersion ([string]$sourceVersionInfo["Display"])
$overwriteExistingSkills = Resolve-ExistingSkillAction `
    -HostName "OpenCode" `
    -ExistingPaths $existingSkillTargets `
    -Force:$Force `
    -AssumeYes:$AssumeYes

if ($overwriteExistingSkills) {
    Backup-ExistingTargets -HostName "OpenCode" -Paths $existingSkillTargets | Out-Null
}

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

        Set-Content -LiteralPath $targetSkillPath -Value $skillMarkdown -Encoding utf8

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

Backup-ExistingFile -Path $agentsPath -Reason "更新 OpenCode 的 AGENTS.md 中 superpowers 说明段前先备份。" | Out-Null

Upsert-ManagedBlock `
    -Path $agentsPath `
    -BlockId "superpowers-opencode" `
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
        -HostName "OpenCode" `
        -VersionInfo $versionInfoToRecord `
        -SourceRoot $sourceRoot `
        -SkillCount ($installed.Count + $skipped.Count) `
        -NamePrefix $NamePrefix
}

Write-Host ""
Write-Host "OpenCode 安装完成。"
Write-Host "来源：        $sourceRoot"
Write-Host "Skill 目录：   $targetSkillRoot"
Write-Host "AGENTS.md：   $agentsPath"
Write-Host "已安装：       $($installed.Count)"
Write-Host "已跳过：       $($skipped.Count)"
