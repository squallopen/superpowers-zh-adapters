[CmdletBinding()]
param(
    [ValidateSet("User", "Project")]
    [string]$Scope = "User",
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet("All", "Cline", "ClaudeCode", "Codex", "Droid", "OpenCode", "CodeBuddy")]
    [string[]]$Targets = @("All"),
    [string]$SourcePath,
    [string]$VendorRoot,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [switch]$UpdateSource,
    [string]$NamePrefix = "superpowers-",
    [ValidateSet("Copy", "Junction")]
    [string]$ClaudeCodeInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$CodexInstallMode = "Copy",
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
    @("Cline", "ClaudeCode", "Codex", "Droid", "OpenCode", "CodeBuddy")
}
else {
    $Targets | Select-Object -Unique
}
$targetDisplayNames = @{
    Cline = "Cline"
    ClaudeCode = "Claude Code"
    Codex = "Codex"
    Droid = "Droid"
    OpenCode = "OpenCode"
    CodeBuddy = "CodeBuddy"
}
$resolvedTargetLabels = $resolvedTargets | ForEach-Object { $targetDisplayNames[$_] }

Write-Host ("本次目标工具：{0}" -f ($resolvedTargetLabels -join "、"))
if ($Targets -contains "All") {
    if ($PSBoundParameters.ContainsKey("Targets")) {
        Write-Host "当前使用的是 -Targets All，会安装全部支持工具。"
    }
    else {
        Write-Host "当前未单独指定 -Targets，默认会安装全部支持工具。"
    }
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

if ($resolvedTargets -contains "ClaudeCode") {
    & (Join-Path $PSScriptRoot "install-claudecode.ps1") `
        -Scope $Scope `
        -ProjectRoot $ProjectRoot `
        -SourcePath $SourcePath `
        -VendorRoot $VendorRoot `
        -RepositoryUrl $RepositoryUrl `
        -UpdateSource:$UpdateSource `
        -InstallMode $ClaudeCodeInstallMode `
        -NamePrefix $NamePrefix `
        -BackupSessionRoot $BackupSessionRoot `
        -Force:$Force `
        -AssumeYes:$AssumeYes
}

if ($resolvedTargets -contains "Codex") {
    & (Join-Path $PSScriptRoot "install-codex.ps1") `
        -Scope $Scope `
        -ProjectRoot $ProjectRoot `
        -SourcePath $SourcePath `
        -VendorRoot $VendorRoot `
        -RepositoryUrl $RepositoryUrl `
        -UpdateSource:$UpdateSource `
        -InstallMode $CodexInstallMode `
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

Show-StarReminder

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
