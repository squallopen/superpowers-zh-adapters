[CmdletBinding()]
param(
    [ValidateSet("User", "Project")]
    [string]$Scope = "User",
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet("All", "Cline", "Droid", "OpenCode", "CodeBuddy")]
    [string[]]$Targets = @("All"),
    [string]$SourcePath,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [string]$Ref = "main",
    [string]$NamePrefix = "superpowers-",
    [ValidateSet("Copy", "Junction")]
    [string]$OpenCodeInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$DroidInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$CodeBuddyInstallMode = "Copy"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "scripts/Install-Superpowers.Common.psm1") -Force -DisableNameChecking

$vendorRoot = Join-Path $PSScriptRoot "vendor/superpowers"
$refreshScript = Join-Path $PSScriptRoot "scripts/Refresh-VendoredSuperpowers.ps1"
$installScript = Join-Path $PSScriptRoot "install-all.ps1"
$triggerDataPath = Join-Path $PSScriptRoot "data/zh-cn-skill-triggers.json"

Write-Host "Refreshing vendored superpowers..."

& $refreshScript `
    -SourcePath $SourcePath `
    -RepositoryUrl $RepositoryUrl `
    -Ref $Ref `
    -TargetPath $vendorRoot

$triggerData = Get-SkillTriggerData -DataPath $triggerDataPath
$skillDirectories = Get-UpstreamSkillDirectories -SourceRoot $vendorRoot

$installedSkillNames = $skillDirectories | ForEach-Object { $_.Name }
$missingTriggerNames = New-Object System.Collections.Generic.List[string]
$extraTriggerNames = New-Object System.Collections.Generic.List[string]

foreach ($skillName in $installedSkillNames) {
    $entry = Get-SkillTriggerEntry -TriggerData $triggerData -OriginalSkillName $skillName
    if (-not $entry) {
        $missingTriggerNames.Add($skillName)
    }
}

foreach ($entry in $triggerData) {
    if ($installedSkillNames -notcontains $entry.name) {
        $extraTriggerNames.Add([string]$entry.name)
    }
}

Write-Host ""
Write-Host "Upstream refresh summary"
Write-Host "Skills found:          $($installedSkillNames.Count)"
Write-Host "Missing zh triggers:   $($missingTriggerNames.Count)"
Write-Host "Stale zh triggers:     $($extraTriggerNames.Count)"

if ($missingTriggerNames.Count -gt 0) {
    Write-Warning ("Missing zh-cn trigger entries: " + ($missingTriggerNames -join ", "))
}

if ($extraTriggerNames.Count -gt 0) {
    Write-Warning ("Trigger entries without upstream skill: " + ($extraTriggerNames -join ", "))
}

Write-Host ""
Write-Host "Reinstalling adapted skills into target hosts..."

& $installScript `
    -Scope $Scope `
    -ProjectRoot $ProjectRoot `
    -Targets $Targets `
    -VendorRoot $vendorRoot `
    -NamePrefix $NamePrefix `
    -OpenCodeInstallMode $OpenCodeInstallMode `
    -DroidInstallMode $DroidInstallMode `
    -CodeBuddyInstallMode $CodeBuddyInstallMode `
    -Force

Write-Host ""
Write-Host "Refresh and reinstall complete."
