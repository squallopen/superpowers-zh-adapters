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
    [string]$BackupSessionRoot,
    [switch]$Force,
    [switch]$AssumeYes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Assert-Pwsh7.ps1")
Exit-IfUnsupportedPowerShell -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking
Assert-WindowsOnly

$backupSessionBase = if ($Scope -eq "User") {
    Join-Path $HOME ".superpowers-backups"
}
else {
    Join-Path (Resolve-AbsolutePath -Path $ProjectRoot) ".superpowers-backups"
}
$BackupSessionRoot = Resolve-BackupSessionRoot -BaseRoot $backupSessionBase -BackupSessionRoot $BackupSessionRoot
Write-Host ("本次备份目录：{0}" -f $BackupSessionRoot)

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
        -BackupSessionRoot $BackupSessionRoot `
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
        -BackupSessionRoot $BackupSessionRoot `
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
        -BackupSessionRoot $BackupSessionRoot `
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
        -BackupSessionRoot $BackupSessionRoot `
        -Force:$Force `
        -AssumeYes:$AssumeYes
}
