[CmdletBinding()]
param(
    [ValidateSet("User", "Project")]
    [string]$Scope = "User",
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet("All", "Cline", "Droid", "OpenCode", "CodeBuddy")]
    [string[]]$Targets = @("All"),
    [string]$SourcePath,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [string]$Ref = "",
    [string]$NamePrefix = "superpowers-",
    [ValidateSet("Copy", "Junction")]
    [string]$OpenCodeInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$DroidInstallMode = "Copy",
    [ValidateSet("Copy", "Junction")]
    [string]$CodeBuddyInstallMode = "Copy",
    [switch]$AssumeYes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking
Assert-WindowsOnly

$vendorRoot = Join-Path $repoRoot "vendor/superpowers"
$refreshScript = Join-Path $PSScriptRoot "Refresh-VendoredSuperpowers.ps1"
$installScript = Join-Path $PSScriptRoot "install-all.ps1"
$triggerDataPath = Join-Path $repoRoot "data/zh-cn-skill-triggers.json"

Write-Host "正在刷新 vendored superpowers..."

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
Write-Host "上游刷新结果"
Write-Host "发现 skill 数量：      $($installedSkillNames.Count)"
Write-Host "缺少中文触发：        $($missingTriggerNames.Count)"
Write-Host "多余中文触发：        $($extraTriggerNames.Count)"

if ($missingTriggerNames.Count -gt 0) {
    Write-Warning ("缺少中文触发配置： " + ($missingTriggerNames -join ", "))
}

if ($extraTriggerNames.Count -gt 0) {
    Write-Warning ("发现多余的中文触发配置： " + ($extraTriggerNames -join ", "))
}

$plannedVersionInfo = Get-SuperpowersSourceVersionInfo -SourceRoot $vendorRoot -RepositoryUrl $RepositoryUrl
Write-Host ("准备安装的 upstream 版本：{0}" -f $plannedVersionInfo["Display"])
Write-Host ""
Confirm-UserMergeAction `
    -Title "即将按刷新上游并重装方式覆盖已安装的 superpowers 内容" `
    -Guidance @"
这个命令会先刷新仓库里的 upstream，再重新覆盖安装到目标宿主。

继续后会发生这些事：
1. 刷新 vendor/superpowers
2. 检查中文触发配置有没有缺漏
3. 覆盖已安装的 superpowers skill

如果第一次安装，或者你不想覆盖已有安装，
请改用：
pwsh .\scripts\powershell\install-all.ps1
"@ `
    -AssumeYes:$AssumeYes
Write-Host "开始重新安装到目标宿主..."

& $installScript `
    -Scope $Scope `
    -ProjectRoot $ProjectRoot `
    -Targets $Targets `
    -VendorRoot $vendorRoot `
    -NamePrefix $NamePrefix `
    -OpenCodeInstallMode $OpenCodeInstallMode `
    -DroidInstallMode $DroidInstallMode `
    -CodeBuddyInstallMode $CodeBuddyInstallMode `
    -Force `
    -AssumeYes:$AssumeYes

Write-Host ""
Write-Host "刷新并重装完成。"
