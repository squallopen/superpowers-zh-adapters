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
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
