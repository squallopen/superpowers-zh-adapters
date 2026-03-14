[CmdletBinding()]
param(
    [string]$SourcePath,
    [string]$RepositoryUrl = "https://github.com/obra/superpowers.git",
    [string]$Ref = "main",
    [string]$TargetPath = (Join-Path $PSScriptRoot "..\vendor\superpowers")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Install-Superpowers.Common.psm1") -Force -DisableNameChecking

$resolvedTargetPath = Resolve-AbsolutePath -Path $TargetPath
$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("superpowers-refresh-" + [Guid]::NewGuid().ToString("N"))

try {
    if ($SourcePath) {
        $resolvedSourcePath = Resolve-AbsolutePath -Path $SourcePath
        $normalizedSourcePath = [System.IO.Path]::GetFullPath($resolvedSourcePath).TrimEnd('\', '/')
        $normalizedTargetPath = [System.IO.Path]::GetFullPath($resolvedTargetPath).TrimEnd('\', '/')

        if ($normalizedSourcePath -eq $normalizedTargetPath) {
            Write-Host "Source path already matches vendored target. Skipping refresh copy."
            return
        }

        Ensure-Directory -Path $stagingRoot
        Copy-DirectoryContents -SourcePath $resolvedSourcePath -TargetPath $stagingRoot
    }
    else {
        & git clone --depth 1 --branch $Ref $RepositoryUrl $stagingRoot
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed with exit code $LASTEXITCODE"
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
        throw "robocopy failed with exit code $robocopyExitCode"
    }

    Write-Host "Vendored superpowers refreshed at $resolvedTargetPath"
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}
