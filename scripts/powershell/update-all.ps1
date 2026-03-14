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
$resolvedProjectRoot = if ($Scope -eq "Project") { Resolve-AbsolutePath -Path $ProjectRoot } else { $null }

if (-not $SkipRepoPull) {
    Assert-RequiredCommand -CommandName "git" -InstallHint "请先安装 Git for Windows：https://git-scm.com/download/win ，然后重新打开 PowerShell。"

    $gitDirectory = Join-Path $repoRoot ".git"
    if (-not (Test-Path -LiteralPath $gitDirectory)) {
        throw "scripts/powershell/update-all.ps1 必须在 git 仓库目录里运行；如果你不想先拉仓库，请改用 -SkipRepoPull。"
    }

    Write-Host "正在更新当前适配仓库..."
    & git -C $repoRoot pull --ff-only
    if ($LASTEXITCODE -ne 0) {
        throw "git pull 执行失败，退出码：$LASTEXITCODE"
    }
}

$bundledVendorRoot = Join-Path $repoRoot "vendor/superpowers"
$previewSourceRoot = if ($SourcePath) {
    Resolve-AbsolutePath -Path $SourcePath
}
elseif ($VendorRoot) {
    Resolve-AbsolutePath -Path $VendorRoot
}
elseif (Test-Path -LiteralPath (Join-Path $bundledVendorRoot "skills")) {
    $bundledVendorRoot
}
elseif ($Scope -eq "User") {
    Resolve-AbsolutePath -Path (Join-Path $HOME ".superpowers/upstream")
}
else {
    Resolve-AbsolutePath -Path (Join-Path $resolvedProjectRoot ".superpowers/upstream")
}

if (Test-Path -LiteralPath $previewSourceRoot) {
    $previewVersionInfo = Get-SuperpowersSourceVersionInfo -SourceRoot $previewSourceRoot -RepositoryUrl $RepositoryUrl
    Write-Host ("准备安装的 upstream 版本：{0}" -f $previewVersionInfo["Display"])
}
else {
    Write-Host "准备安装的 upstream 版本：未知（当前还拿不到源目录版本信息）"
}

Confirm-UserMergeAction `
    -Title "即将按更新方式覆盖已安装的 superpowers 内容" `
    -Guidance @"
这个命令不是“只补缺少的 skill”，而是按“更新 superpowers”来处理。

继续后会发生这些事：
1. 先更新当前仓库
2. 再覆盖已安装的 superpowers skill
3. 对说明文件会尽量先备份再改

如果第一次安装，或者你只想保留现状、只补缺少的 skill，
请改用：
pwsh .\scripts\powershell\install-all.ps1
"@ `
    -AssumeYes:$AssumeYes

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
    -Force `
    -AssumeYes:$AssumeYes
