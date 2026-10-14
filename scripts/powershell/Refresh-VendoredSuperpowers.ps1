[CmdletBinding()]
param(
    [string]$SourcePath,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [string]$Ref = "",
    [string]$TargetPath = (Join-Path $PSScriptRoot "..\..\vendor\superpowers")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Assert-Pwsh7.ps1")
Exit-IfUnsupportedPowerShell -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking

Assert-WindowsOnly
Assert-RequiredCommand -CommandName "robocopy" -InstallHint "robocopy 是受支持 Windows 版本自带的命令。"

if (-not $SourcePath) {
    Assert-RequiredCommand -CommandName "git" -InstallHint "请先安装 Git for Windows：https://git-scm.com/download/win ，然后重新打开 PowerShell。"
}

$resolvedTargetPath = Resolve-AbsolutePath -Path $TargetPath
$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("superpowers-refresh-" + [Guid]::NewGuid().ToString("N"))
$sourceVersionInfo = $null
$resolvedRef = $Ref

try {
    if ($SourcePath) {
        $resolvedSourcePath = Resolve-AbsolutePath -Path $SourcePath
        $normalizedSourcePath = [System.IO.Path]::GetFullPath($resolvedSourcePath).TrimEnd('\', '/')
        $normalizedTargetPath = [System.IO.Path]::GetFullPath($resolvedTargetPath).TrimEnd('\', '/')
        $sourceVersionInfo = Get-SuperpowersSourceVersionInfo -SourceRoot $resolvedSourcePath -RepositoryUrl $RepositoryUrl

        if ($normalizedSourcePath -eq $normalizedTargetPath) {
            Write-Host "源路径和 vendored 目标一致，跳过刷新复制。"
            Write-Host ("上游版本：{0}" -f $sourceVersionInfo["Display"])
            Save-SuperpowersSourceManifest -SourceRoot $resolvedTargetPath -VersionInfo $sourceVersionInfo
            return
        }

        Ensure-Directory -Path $stagingRoot
        Copy-DirectoryContents -SourcePath $resolvedSourcePath -TargetPath $stagingRoot
    }
    else {
        $resolvedRef = Resolve-UpstreamRef -RepositoryUrl $RepositoryUrl -RequestedRef $Ref
        Write-Host "正在从上游仓库拉取 superpowers..."
        Write-Host ("将使用上游版本：{0}" -f $resolvedRef)
        Ensure-Directory -Path $stagingRoot
        & git init $stagingRoot | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "git init 执行失败，退出码：$LASTEXITCODE"
        }

        & git -C $stagingRoot remote add origin $RepositoryUrl
        if ($LASTEXITCODE -ne 0) {
            throw "git remote add 执行失败，退出码：$LASTEXITCODE"
        }

        $tagProbe = @(& git ls-remote --tags --refs $RepositoryUrl "refs/tags/$resolvedRef" 2>$null)
        $isTagRef = ($LASTEXITCODE -eq 0 -and $tagProbe.Count -gt 0)

        if ($isTagRef) {
            & git -C $stagingRoot fetch --depth 1 origin "refs/tags/${resolvedRef}:refs/tags/${resolvedRef}"
            if ($LASTEXITCODE -ne 0) {
                throw "git fetch tag 执行失败，退出码：$LASTEXITCODE"
            }
            $checkoutSpec = "refs/tags/$resolvedRef^{commit}"
        }
        else {
            & git -C $stagingRoot fetch --depth 1 origin $resolvedRef
            if ($LASTEXITCODE -ne 0) {
                throw "git fetch 执行失败，退出码：$LASTEXITCODE"
            }
            $checkoutSpec = "FETCH_HEAD^{commit}"
        }

        $checkoutCommit = [string](& git -C $stagingRoot rev-parse --verify $checkoutSpec 2>$null | Select-Object -First 1)
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($checkoutCommit)) {
            throw "无法把 ref 解析到 commit：$resolvedRef"
        }

        & git -C $stagingRoot -c advice.detachedHead=false checkout --detach $checkoutCommit | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "git checkout 执行失败，退出码：$LASTEXITCODE"
        }

        $sourceVersionInfo = Get-SuperpowersSourceVersionInfo -SourceRoot $stagingRoot -RepositoryUrl $RepositoryUrl
        if ($sourceVersionInfo -and [string]::IsNullOrWhiteSpace([string]$sourceVersionInfo["Ref"])) {
            $sourceVersionInfo["Ref"] = $resolvedRef
        }
    }

    $nestedGit = Join-Path $stagingRoot ".git"
    if (Test-Path -LiteralPath $nestedGit) {
        Remove-Item -LiteralPath $nestedGit -Recurse -Force
    }

    Ensure-Directory -Path $resolvedTargetPath
    & robocopy $stagingRoot $resolvedTargetPath /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -ge 8) {
        throw "robocopy 执行失败，退出码：$robocopyExitCode"
    }

    if ($sourceVersionInfo) {
        Save-SuperpowersSourceManifest -SourceRoot $resolvedTargetPath -VersionInfo $sourceVersionInfo
        Write-Host ("上游版本：          {0}" -f $sourceVersionInfo["Display"])
    }

    Write-Host "已刷新 vendored superpowers：$resolvedTargetPath"
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}
