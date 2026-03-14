[CmdletBinding()]
param(
    [ValidateSet("User", "Project")]
    [string]$Scope = "User",
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet("All", "Cline", "Droid", "OpenCode", "CodeBuddy")]
    [string[]]$Targets = @("All"),
    [string]$SourcePath,
    [string]$VendorRoot,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [switch]$UpdateSource,
    [string]$NamePrefix = "superpowers-",
    [ValidateSet("Copy", "Junction")]
    [string]$OpenCodeInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$DroidInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$CodeBuddyInstallMode = "Copy",
    [switch]$Force,
    [switch]$AssumeYes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking
Assert-WindowsOnly

$resolvedTargets = if ($Targets -contains "All") {
    @("Cline", "Droid", "OpenCode", "CodeBuddy")
}
else {
    $Targets | Select-Object -Unique
}

if ($resolvedTargets -contains "Cline") {
    & (Join-Path $PSScriptRoot "install-cline.ps1") `
        -Scope $Scope `
        -ProjectRoot $ProjectRoot `
        -SourcePath $SourcePath `
        -VendorRoot $VendorRoot `
        -RepositoryUrl $RepositoryUrl `
        -UpdateSource:$UpdateSource `
        -NamePrefix $NamePrefix `
        -Force:$Force `
        -AssumeYes:$AssumeYes
}

if ($resolvedTargets -contains "Droid") {
    & (Join-Path $PSScriptRoot "install-droid.ps1") `
        -Scope $Scope `
        -ProjectRoot $ProjectRoot `
        -SourcePath $SourcePath `
        -VendorRoot $VendorRoot `
        -RepositoryUrl $RepositoryUrl `
        -UpdateSource:$UpdateSource `
        -InstallMode $DroidInstallMode `
        -NamePrefix $NamePrefix `
        -Force:$Force `
        -AssumeYes:$AssumeYes
}

if ($resolvedTargets -contains "OpenCode") {
    & (Join-Path $PSScriptRoot "install-opencode.ps1") `
        -Scope $Scope `
        -ProjectRoot $ProjectRoot `
        -SourcePath $SourcePath `
        -VendorRoot $VendorRoot `
        -RepositoryUrl $RepositoryUrl `
        -UpdateSource:$UpdateSource `
        -InstallMode $OpenCodeInstallMode `
        -NamePrefix $NamePrefix `
        -Force:$Force `
        -AssumeYes:$AssumeYes
}

if ($resolvedTargets -contains "CodeBuddy") {
    & (Join-Path $PSScriptRoot "install-codebuddy.ps1") `
        -Scope $Scope `
        -ProjectRoot $ProjectRoot `
        -SourcePath $SourcePath `
        -VendorRoot $VendorRoot `
        -RepositoryUrl $RepositoryUrl `
        -UpdateSource:$UpdateSource `
        -InstallMode $CodeBuddyInstallMode `
        -NamePrefix $NamePrefix `
        -Force:$Force `
        -AssumeYes:$AssumeYes
}
