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

Ensure-Directory -Path $targetSkillRoot

$installed = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]

foreach ($skillDirectory in Get-UpstreamSkillDirectories -SourceRoot $sourceRoot) {
    $installedName = Get-InstalledSkillName -OriginalName $skillDirectory.Name -NamePrefix $NamePrefix
    $targetSkillPath = Join-Path $targetSkillRoot ("{0}.md" -f $installedName)
    $targetResourcePath = Join-Path $targetSkillRoot $installedName

    if ((Test-Path -LiteralPath $targetSkillPath) -or (Test-Path -LiteralPath $targetResourcePath)) {
        if ($Force) {
            Remove-ExistingTarget -Path $targetSkillPath
            Remove-ExistingTarget -Path $targetResourcePath
        }
        else {
            Write-Warning "Skipping existing OpenCode skill: $targetSkillPath"
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

Backup-ExistingFile -Path $agentsPath -Reason "Updating OpenCode AGENTS.md superpowers section." | Out-Null

Upsert-ManagedBlock `
    -Path $agentsPath `
    -BlockId "superpowers-opencode" `
    -Content $agentsBlock

Write-Host ""
Write-Host "OpenCode installation complete."
Write-Host "Source:      $sourceRoot"
Write-Host "Skills:      $targetSkillRoot"
Write-Host "AGENTS.md:   $agentsPath"
Write-Host "Installed:   $($installed.Count)"
Write-Host "Skipped:     $($skipped.Count)"
