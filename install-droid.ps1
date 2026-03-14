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
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "scripts/Install-Superpowers.Common.psm1") -Force -DisableNameChecking

$bundledVendorRoot = Join-Path $PSScriptRoot "vendor/superpowers"

if ($Scope -eq "Project") {
    $ProjectRoot = Resolve-AbsolutePath -Path $ProjectRoot
}
else {
    $ProjectRoot = $null
}

if ($InstallMode -eq "Junction" -and -not [string]::IsNullOrWhiteSpace($NamePrefix)) {
    throw "Junction mode cannot rename installed skills. Use -NamePrefix '' or switch to -InstallMode Copy."
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

$overlayRoot = Join-Path $PSScriptRoot "templates/droid/skill-overlays"
$triggerDataPath = Join-Path $PSScriptRoot "data/zh-cn-skill-triggers.json"
$triggerData = Get-SkillTriggerData -DataPath $triggerDataPath

Ensure-Directory -Path $targetSkillRoot

$installed = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]

foreach ($skillDirectory in Get-UpstreamSkillDirectories -SourceRoot $sourceRoot) {
    $installedName = Get-InstalledSkillName -OriginalName $skillDirectory.Name -NamePrefix $NamePrefix
    $targetSkillPath = Join-Path $targetSkillRoot $installedName

    if (Test-Path -LiteralPath $targetSkillPath) {
        if ($Force) {
            Remove-ExistingTarget -Path $targetSkillPath
        }
        else {
            Write-Warning "Skipping existing Droid skill: $targetSkillPath"
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
    -TemplatePath (Join-Path $PSScriptRoot "templates/droid/AGENTS.block.md") `
    -Tokens @{
        NAME_PREFIX = $NamePrefix
    }
$triggerGuide = New-DroidChineseTriggerGuide -TriggerData $triggerData -NamePrefix $NamePrefix
if (-not [string]::IsNullOrWhiteSpace($triggerGuide)) {
    $agentsBlock = $agentsBlock.TrimEnd() + "`n`n" + $triggerGuide
}

Upsert-ManagedBlock `
    -Path $agentsPath `
    -BlockId "superpowers-compat" `
    -Content $agentsBlock

Write-Host ""
Write-Host "Droid installation complete."
Write-Host "Source:      $sourceRoot"
Write-Host "Skills:      $targetSkillRoot"
Write-Host "AGENTS.md:   $agentsPath"
Write-Host "Installed:   $($installed.Count)"
Write-Host "Skipped:     $($skipped.Count)"
