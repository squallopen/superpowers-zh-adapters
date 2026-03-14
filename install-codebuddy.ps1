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

$codebuddyRoot = if ($Scope -eq "User") {
    Join-Path $HOME ".codebuddy"
}
else {
    Join-Path $ProjectRoot ".codebuddy"
}

$targetSkillRoot = Join-Path $codebuddyRoot "skills"
$settingsPath = Join-Path $codebuddyRoot "settings.json"
$instructionsPath = if ($Scope -eq "User") {
    Join-Path $HOME ".codebuddy/CODEBUDDY.md"
}
else {
    Join-Path $ProjectRoot "CODEBUDDY.md"
}

$overlayRoot = Join-Path $PSScriptRoot "templates/codebuddy/skill-overlays"
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
            Write-Warning "Skipping existing CodeBuddy skill: $targetSkillPath"
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
                    -Heading "CodeBuddy Adaptation"
            }
        }
    }
    else {
        New-Item -ItemType Junction -Path $targetSkillPath -Target $skillDirectory.FullName | Out-Null
    }

    $installed.Add($installedName)
}

$instructionsBlock = Expand-TemplateFile `
    -TemplatePath (Join-Path $PSScriptRoot "templates/codebuddy/CODEBUDDY.block.md") `
    -Tokens @{
        NAME_PREFIX = $NamePrefix
    }

$triggerGuide = New-DroidChineseTriggerGuide -TriggerData $triggerData -NamePrefix $NamePrefix
if (-not [string]::IsNullOrWhiteSpace($triggerGuide)) {
    $instructionsBlock = $instructionsBlock.TrimEnd() + "`n`n" + $triggerGuide
}

Upsert-ManagedBlock `
    -Path $instructionsPath `
    -BlockId "superpowers-codebuddy" `
    -Content $instructionsBlock

$settings = Get-JsonObject -Path $settingsPath
$settings["language"] = "简体中文"
Save-JsonObject -Path $settingsPath -Data $settings

Write-Host ""
Write-Host "CodeBuddy installation complete."
Write-Host "Source:        $sourceRoot"
Write-Host "Skills:        $targetSkillRoot"
Write-Host "Instructions:  $instructionsPath"
Write-Host "Settings:      $settingsPath"
Write-Host "Installed:     $($installed.Count)"
Write-Host "Skipped:       $($skipped.Count)"
