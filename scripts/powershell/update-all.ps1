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
    [string]$NamePrefix = "superpowers-",
    [ValidateSet("Copy", "Junction")]
    [string]$OpenCodeInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$DroidInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$CodeBuddyInstallMode = "Copy",
    [switch]$Force,
    [switch]$SkipRepoPull,
    [switch]$AssumeYes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking
Assert-WindowsOnly

if (-not $SkipRepoPull) {
    Assert-RequiredCommand -CommandName "git" -InstallHint "Install Git for Windows from https://git-scm.com/download/win and reopen PowerShell."

    $gitDirectory = Join-Path $repoRoot ".git"
    if (-not (Test-Path -LiteralPath $gitDirectory)) {
        throw "scripts/powershell/update-all.ps1 must run from a git checkout, or use -SkipRepoPull."
    }

    & git -C $repoRoot pull --ff-only
    if ($LASTEXITCODE -ne 0) {
        throw "git pull failed with exit code $LASTEXITCODE"
    }
}

& (Join-Path $PSScriptRoot "install-all.ps1") `
    -Scope $Scope `
    -ProjectRoot $ProjectRoot `
    -Targets $Targets `
    -SourcePath $SourcePath `
    -VendorRoot $VendorRoot `
    -RepositoryUrl $RepositoryUrl `
    -NamePrefix $NamePrefix `
    -OpenCodeInstallMode $OpenCodeInstallMode `
    -DroidInstallMode $DroidInstallMode `
    -CodeBuddyInstallMode $CodeBuddyInstallMode `
    -Force:$Force `
    -AssumeYes:$AssumeYes
