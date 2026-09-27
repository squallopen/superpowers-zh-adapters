Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $repoRoot "scripts/powershell/Install-Superpowers.Common.psm1") -Force -DisableNameChecking

function Assert-Equal {
    param(
        [Parameter(Mandatory)]
        [string]$Actual,
        [Parameter(Mandatory)]
        [string]$Expected,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if ($Actual -cne $Expected) {
        throw "$Message`nExpected: $Expected`nActual:   $Actual"
    }
}

function Assert-ContainsText {
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [Parameter(Mandatory)]
        [string]$ExpectedText,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Content.Contains($ExpectedText)) {
        throw "$Message`nExpected text: $ExpectedText"
    }
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Message`nMissing path: $Path"
    }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("skill-changer-tests-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    $skillFilePath = Join-Path $tempRoot "SKILL.md"
    $content = @'
---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs
'@
    Set-Content -LiteralPath $skillFilePath -Value $content -NoNewline

    $triggerEntry = [pscustomobject]@{
        phrases = @("头脑风暴", "想方案")
    }

    Add-SkillDescriptionTriggerHints -SkillFilePath $skillFilePath -TriggerEntry $triggerEntry

    $descriptionLine = Select-String -Path $skillFilePath -Pattern '^description:' | Select-Object -ExpandProperty Line
    Assert-Equal `
        -Actual $descriptionLine `
        -Expected 'description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation. 中文触发：头脑风暴、想方案。"' `
        -Message "Quoted YAML description should remain a valid single scalar after trigger hints are appended."

    $zcodeSourceRoot = Join-Path $tempRoot "zcode-source"
    $zcodeSkillRoot = Join-Path $zcodeSourceRoot "skills/using-superpowers"
    New-Item -ItemType Directory -Path $zcodeSkillRoot -Force | Out-Null
    $fakeZcodeSkill = @(
        "---",
        "name: using-superpowers",
        "description: `"Use when starting any conversation.`"",
        "---",
        "",
        "# Using Superpowers"
    ) -join "`n"
    Set-Content -LiteralPath (Join-Path $zcodeSkillRoot "SKILL.md") -NoNewline -Value $fakeZcodeSkill

    $zcodeProjectRoot = Join-Path $tempRoot "zcode-project"
    New-Item -ItemType Directory -Path $zcodeProjectRoot | Out-Null

    & (Join-Path $repoRoot "scripts/powershell/install-zcode.ps1") `
        -Scope Project `
        -ProjectRoot $zcodeProjectRoot `
        -SourcePath $zcodeSourceRoot `
        -NamePrefix "superpowers-" `
        -AssumeYes

    $installedSkillPath = Join-Path $zcodeProjectRoot ".zcode/skills/superpowers-using-superpowers/SKILL.md"
    Assert-PathExists `
        -Path $installedSkillPath `
        -Message "ZCode project install should write prefixed skills into .zcode/skills."

    $installedSkillContent = Get-Content -LiteralPath $installedSkillPath -Raw
    Assert-ContainsText `
        -Content $installedSkillContent `
        -ExpectedText "name: superpowers-using-superpowers" `
        -Message "ZCode install should rename the skill frontmatter to match the installed directory."
    Assert-ContainsText `
        -Content $installedSkillContent `
        -ExpectedText "中文触发：" `
        -Message "ZCode install should append Chinese trigger hints to skill descriptions."
    Assert-ContainsText `
        -Content $installedSkillContent `
        -ExpectedText "## ZCode Adaptation" `
        -Message "ZCode install should append host-specific adaptation guidance."

    $metadataPath = Join-Path $zcodeProjectRoot ".zcode/.superpowers-install.json"
    Assert-PathExists `
        -Path $metadataPath `
        -Message "ZCode install should record install metadata under the ZCode root."
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    Assert-Equal `
        -Actual ([string]$metadata.host) `
        -Expected "ZCode" `
        -Message "ZCode install metadata should identify the host."

    $qoderSourceRoot = Join-Path $tempRoot "qodercn-source"
    $qoderSkillRoot = Join-Path $qoderSourceRoot "skills/using-superpowers"
    New-Item -ItemType Directory -Path $qoderSkillRoot -Force | Out-Null
    $fakeQoderSkill = @(
        "---",
        "name: using-superpowers",
        "description: `"Use when starting any conversation.`"",
        "---",
        "",
        "# Using Superpowers"
    ) -join "`n"
    Set-Content -LiteralPath (Join-Path $qoderSkillRoot "SKILL.md") -NoNewline -Value $fakeQoderSkill

    $qoderProjectRoot = Join-Path $tempRoot "qodercn-project"
    New-Item -ItemType Directory -Path $qoderProjectRoot | Out-Null

    & (Join-Path $repoRoot "scripts/powershell/install-qodercn.ps1") `
        -Scope Project `
        -ProjectRoot $qoderProjectRoot `
        -SourcePath $qoderSourceRoot `
        -NamePrefix "superpowers-" `
        -AssumeYes

    $installedQoderSkillPath = Join-Path $qoderProjectRoot ".qoder/skills/superpowers-using-superpowers/SKILL.md"
    Assert-PathExists `
        -Path $installedQoderSkillPath `
        -Message "Qoder CN project install should write prefixed skills into .qoder/skills."

    $installedQoderSkillContent = Get-Content -LiteralPath $installedQoderSkillPath -Raw
    Assert-ContainsText `
        -Content $installedQoderSkillContent `
        -ExpectedText "name: superpowers-using-superpowers" `
        -Message "Qoder CN install should rename the skill frontmatter to match the installed directory."
    Assert-ContainsText `
        -Content $installedQoderSkillContent `
        -ExpectedText "中文触发：" `
        -Message "Qoder CN install should append Chinese trigger hints to skill descriptions."
    Assert-ContainsText `
        -Content $installedQoderSkillContent `
        -ExpectedText "## Qoder CN Adaptation" `
        -Message "Qoder CN install should append host-specific adaptation guidance."

    $qoderAgentsPath = Join-Path $qoderProjectRoot "AGENTS.md"
    Assert-PathExists `
        -Path $qoderAgentsPath `
        -Message "Qoder CN project install should update project AGENTS.md."
    $qoderAgentsContent = Get-Content -LiteralPath $qoderAgentsPath -Raw
    Assert-ContainsText `
        -Content $qoderAgentsContent `
        -ExpectedText "BEGIN superpowers-qodercn" `
        -Message "Qoder CN install should manage its own AGENTS.md block."

    $qoderMetadataPath = Join-Path $qoderProjectRoot ".qoder/.superpowers-install.json"
    Assert-PathExists `
        -Path $qoderMetadataPath `
        -Message "Qoder CN install should record install metadata under the Qoder project root."
    $qoderMetadata = Get-Content -LiteralPath $qoderMetadataPath -Raw | ConvertFrom-Json
    Assert-Equal `
        -Actual ([string]$qoderMetadata.host) `
        -Expected "Qoder CN" `
        -Message "Qoder CN install metadata should identify the host."

    $qoderUserHome = Join-Path $tempRoot "qodercn-user-home"
    New-Item -ItemType Directory -Path $qoderUserHome | Out-Null
    $oldHomeEnvironment = $env:HOME
    $oldUserProfileEnvironment = $env:USERPROFILE
    try {
        $env:HOME = $qoderUserHome
        $env:USERPROFILE = $qoderUserHome

        & pwsh -NoProfile -File (Join-Path $repoRoot "scripts/powershell/install-qodercn.ps1") `
            -Scope User `
            -SourcePath $qoderSourceRoot `
            -NamePrefix "superpowers-" `
            -AssumeYes
        if ($LASTEXITCODE -ne 0) {
            throw "Qoder CN user install test process failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        $env:HOME = $oldHomeEnvironment
        $env:USERPROFILE = $oldUserProfileEnvironment
    }

    $installedQoderUserSkillPath = Join-Path $qoderUserHome ".qoder-cn/skills/superpowers-using-superpowers/SKILL.md"
    Assert-PathExists `
        -Path $installedQoderUserSkillPath `
        -Message "Qoder CN user install should write prefixed skills into ~/.qoder-cn/skills."

    $qoderUserAgentsPath = Join-Path $qoderUserHome ".qoder-cn/AGENTS.md"
    Assert-PathExists `
        -Path $qoderUserAgentsPath `
        -Message "Qoder CN user install should update ~/.qoder-cn/AGENTS.md."
    $qoderUserAgentsContent = Get-Content -LiteralPath $qoderUserAgentsPath -Raw
    Assert-ContainsText `
        -Content $qoderUserAgentsContent `
        -ExpectedText "BEGIN superpowers-qodercn" `
        -Message "Qoder CN user install should manage its own AGENTS.md block."

    $qoderUserMetadataPath = Join-Path $qoderUserHome ".qoder-cn/.superpowers-install.json"
    Assert-PathExists `
        -Path $qoderUserMetadataPath `
        -Message "Qoder CN user install should record install metadata under ~/.qoder-cn."
    $qoderUserMetadata = Get-Content -LiteralPath $qoderUserMetadataPath -Raw | ConvertFrom-Json
    Assert-Equal `
        -Actual ([string]$qoderUserMetadata.host) `
        -Expected "Qoder CN" `
        -Message "Qoder CN user install metadata should identify the host."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
