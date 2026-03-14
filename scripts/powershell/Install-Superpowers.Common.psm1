Set-StrictMode -Version Latest

function Assert-WindowsOnly {
    [CmdletBinding()]
    param()

    if ($env:OS -ne "Windows_NT") {
        throw "This repository currently only ships Windows PowerShell installers. If you want support for another OS, add a new runtime under scripts/."
    }
}

function Assert-RequiredCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,
        [string]$InstallHint = ""
    )

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        return
    }

    $message = "Missing required command '$CommandName'."
    if (-not [string]::IsNullOrWhiteSpace($InstallHint)) {
        $message += " $InstallHint"
    }

    throw $message
}

function Ensure-Directory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Resolve-AbsolutePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if (Test-Path -LiteralPath $expanded) {
        return (Resolve-Path -LiteralPath $expanded).Path
    }

    return [System.IO.Path]::GetFullPath($expanded)
}

function Resolve-SuperpowersSource {
    [CmdletBinding()]
    param(
        [string]$SourcePath,
        [Parameter(Mandatory)]
        [string]$VendorRoot,
        [Parameter(Mandatory)]
        [string]$RepositoryUrl,
        [switch]$UpdateSource
    )

    if ($SourcePath) {
        $resolvedSource = Resolve-AbsolutePath -Path $SourcePath
        if (-not (Test-Path -LiteralPath $resolvedSource)) {
            throw "Source path does not exist: $resolvedSource"
        }

        return $resolvedSource
    }

    $resolvedVendorRoot = Resolve-AbsolutePath -Path $VendorRoot
    $skillsRoot = Join-Path $resolvedVendorRoot "skills"

    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        $parent = Split-Path -Parent $resolvedVendorRoot
        if ($parent) {
            Ensure-Directory -Path $parent
        }

        Assert-RequiredCommand -CommandName "git" -InstallHint "Install Git for Windows from https://git-scm.com/download/win and reopen PowerShell."
        Write-Host "Cloning superpowers from $RepositoryUrl into $resolvedVendorRoot"
        & git clone --depth 1 $RepositoryUrl $resolvedVendorRoot
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed with exit code $LASTEXITCODE"
        }
    }
    elseif ($UpdateSource) {
        Assert-RequiredCommand -CommandName "git" -InstallHint "Install Git for Windows from https://git-scm.com/download/win and reopen PowerShell."
        Write-Host "Updating existing superpowers checkout in $resolvedVendorRoot"
        & git -C $resolvedVendorRoot pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            throw "git pull failed with exit code $LASTEXITCODE"
        }
    }

    return $resolvedVendorRoot
}

function Get-UpstreamSkillDirectories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceRoot
    )

    $skillsRoot = Join-Path $SourceRoot "skills"
    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        throw "The superpowers checkout does not contain a skills directory: $skillsRoot"
    }

    return Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name
}

function Remove-ExistingTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Copy-DirectoryContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        [Parameter(Mandatory)]
        [string]$TargetPath
    )

    Ensure-Directory -Path $TargetPath

    foreach ($child in Get-ChildItem -LiteralPath $SourcePath -Force) {
        Copy-Item -LiteralPath $child.FullName -Destination $TargetPath -Recurse -Force
    }
}

function Split-MarkdownFrontMatter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $normalized = $Content -replace "`r`n", "`n"
    $match = [regex]::Match($normalized, "(?s)\A---\n(.*?)\n---\n?(.*)\z")

    if ($match.Success) {
        return @{
            FrontMatter = $match.Groups[1].Value
            Body = $match.Groups[2].Value.Trim()
        }
    }

    return @{
        FrontMatter = ""
        Body = $normalized.Trim()
    }
}

function Get-FrontMatterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FrontMatter,
        [Parameter(Mandatory)]
        [string]$Key
    )

    $escapedKey = [regex]::Escape($Key)
    $match = [regex]::Match($FrontMatter, "(?m)^${escapedKey}:\s*(.+?)\s*$")
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return $null
}

function Convert-SuperpowersSkillToClinePrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SkillFilePath,
        [Parameter(Mandatory)]
        [string]$InstalledName,
        [Parameter(Mandatory)]
        [string]$OriginalName,
        [string]$OverlayContent = ""
    )

    $content = Get-Content -LiteralPath $SkillFilePath -Raw
    $parts = Split-MarkdownFrontMatter -Content $content
    $description = Get-FrontMatterValue -FrontMatter $parts.FrontMatter -Key "description"

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# $InstalledName")
    $lines.Add("")
    $lines.Add('Adapted from `obra/superpowers` for Cline.')
    $lines.Add("Use the active Cline superpowers rules to translate any Claude Code specific tool references.")
    $lines.Add("")
    $lines.Add(('Original skill name: `{0}`' -f $OriginalName))

    if ($description) {
        $lines.Add(("Original trigger description: {0}" -f $description))
    }

    $lines.Add("")
    $lines.Add("## Instructions")
    $lines.Add("")
    $lines.Add($parts.Body)

    if (-not [string]::IsNullOrWhiteSpace($OverlayContent)) {
        $lines.Add("")
        $lines.Add("## Host Adaptation")
        $lines.Add("")
        $lines.Add($OverlayContent.Trim())
    }

    return (($lines -join "`n").TrimEnd() + "`n")
}

function Convert-SkillBodyResourcePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body,
        [Parameter(Mandatory)]
        [string]$SkillDirectoryPath,
        [Parameter(Mandatory)]
        [string]$OriginalName,
        [Parameter(Mandatory)]
        [string]$ResourceRoot
    )

    if ([string]::IsNullOrWhiteSpace($ResourceRoot)) {
        return $Body
    }

    $rewritten = $Body
    $rewritten = $rewritten.Replace("skills/$OriginalName/", "$ResourceRoot/")

    foreach ($child in Get-ChildItem -LiteralPath $SkillDirectoryPath -Force) {
        if ($child.Name -eq "SKILL.md") {
            continue
        }

        if ($child.PSIsContainer) {
            $rewritten = $rewritten.Replace(($child.Name + "/"), ("$ResourceRoot/" + $child.Name + "/"))
            continue
        }

        $backtickWrappedSource = ([string][char]96) + $child.Name + ([char]96)
        $backtickWrappedTarget = ([string][char]96) + "$ResourceRoot/$($child.Name)" + ([char]96)

        $rewritten = $rewritten.Replace(("./" + $child.Name), ("./$ResourceRoot/" + $child.Name))
        $rewritten = $rewritten.Replace(("@" + $child.Name), ("@$ResourceRoot/" + $child.Name))
        $rewritten = $rewritten.Replace($backtickWrappedSource, $backtickWrappedTarget)
        $rewritten = $rewritten.Replace(("(" + $child.Name + ")"), ("($ResourceRoot/" + $child.Name + ")"))

        $filePattern = "(?<![A-Za-z0-9_/-])" + [regex]::Escape($child.Name) + "(?![A-Za-z0-9_/-])"
        $rewritten = [regex]::Replace($rewritten, $filePattern, ("$ResourceRoot/" + $child.Name))
    }

    return $rewritten
}

function Convert-SuperpowersSkillToSingleFileMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SkillFilePath,
        [Parameter(Mandatory)]
        [string]$InstalledName,
        [Parameter(Mandatory)]
        [string]$OriginalName,
        [Parameter(Mandatory)]
        [string]$ResourceRoot,
        [string]$OverlayContent = "",
        [string]$OverlayHeading = "Host Adaptation"
    )

    $content = Get-Content -LiteralPath $SkillFilePath -Raw
    $parts = Split-MarkdownFrontMatter -Content $content
    $skillDirectoryPath = Split-Path -Parent $SkillFilePath
    $body = Convert-SkillBodyResourcePaths `
        -Body $parts.Body `
        -SkillDirectoryPath $skillDirectoryPath `
        -OriginalName $OriginalName `
        -ResourceRoot $ResourceRoot

    $lines = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($parts.FrontMatter)) {
        $lines.Add("---")
        foreach ($line in ($parts.FrontMatter -split "`n")) {
            $lines.Add($line)
        }
        $lines.Add("---")
        $lines.Add("")
    }

    foreach ($line in ($body.Trim() -split "`n")) {
        $lines.Add($line)
    }

    if (-not [string]::IsNullOrWhiteSpace($OverlayContent)) {
        $lines.Add("")
        $lines.Add("## $OverlayHeading")
        $lines.Add("")
        foreach ($line in ($OverlayContent.Trim() -split "`n")) {
            $lines.Add($line)
        }
    }

    return (($lines -join "`n").TrimEnd() + "`n")
}

function Set-MarkdownFrontMatterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SkillFilePath,
        [Parameter(Mandatory)]
        [string]$Key,
        [Parameter(Mandatory)]
        [string]$Value
    )

    $content = Get-Content -LiteralPath $SkillFilePath -Raw
    $normalized = $content -replace "`r`n", "`n"
    $match = [regex]::Match($normalized, "(?s)\A---\n(.*?)\n---\n?(.*)\z")

    if (-not $match.Success) {
        return
    }

    $frontMatter = $match.Groups[1].Value
    $body = $match.Groups[2].Value

    $escapedKey = [regex]::Escape($Key)
    if ([regex]::IsMatch($frontMatter, "(?m)^${escapedKey}:\s*.+$")) {
        $frontMatter = [regex]::Replace($frontMatter, "(?m)^${escapedKey}:\s*.+$", ("{0}: {1}" -f $Key, $Value), 1)
    }
    else {
        $frontMatter = ("{0}: {1}" -f $Key, $Value) + "`n" + $frontMatter
    }

    $updated = "---`n$frontMatter`n---`n$body"
    Set-Content -LiteralPath $SkillFilePath -Value $updated -Encoding utf8
}

function Rename-SkillFrontMatter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SkillFilePath,
        [Parameter(Mandatory)]
        [string]$NewName
    )

    Set-MarkdownFrontMatterValue -SkillFilePath $SkillFilePath -Key "name" -Value $NewName
}

function Get-InstalledSkillName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OriginalName,
        [string]$NamePrefix = ""
    )

    if ([string]::IsNullOrWhiteSpace($NamePrefix)) {
        return $OriginalName
    }

    return "$NamePrefix$OriginalName"
}

function Get-SkillTriggerData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataPath
    )

    if (-not (Test-Path -LiteralPath $DataPath)) {
        return @()
    }

    $raw = Get-Content -LiteralPath $DataPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $parsed = $raw | ConvertFrom-Json
    if ($parsed -is [System.Array]) {
        return $parsed
    }

    return @($parsed)
}

function Get-SkillTriggerEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$TriggerData,
        [Parameter(Mandatory)]
        [string]$OriginalSkillName
    )

    foreach ($entry in $TriggerData) {
        if ($entry.name -eq $OriginalSkillName) {
            return $entry
        }
    }

    return $null
}

function Get-SkillTriggerPhraseText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$TriggerEntry
    )

    if (-not $TriggerEntry) {
        return ""
    }

    $phrases = @($TriggerEntry.phrases | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return ($phrases -join "、")
}

function Add-SkillDescriptionTriggerHints {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SkillFilePath,
        [Parameter(Mandatory)]
        [object]$TriggerEntry
    )

    if (-not $TriggerEntry) {
        return
    }

    $content = Get-Content -LiteralPath $SkillFilePath -Raw
    $parts = Split-MarkdownFrontMatter -Content $content
    $description = Get-FrontMatterValue -FrontMatter $parts.FrontMatter -Key "description"
    $phraseText = Get-SkillTriggerPhraseText -TriggerEntry $TriggerEntry
    if ([string]::IsNullOrWhiteSpace($description) -or [string]::IsNullOrWhiteSpace($phraseText)) {
        return
    }

    $suffix = " 中文触发：$phraseText。"
    if ($description.Contains("中文触发：")) {
        $description = [regex]::Replace($description, "\s*中文触发：.*$", $suffix)
    }
    else {
        $description = $description.TrimEnd() + $suffix
    }

    Set-MarkdownFrontMatterValue -SkillFilePath $SkillFilePath -Key "description" -Value $description
}

function Expand-TemplateFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplatePath,
        [hashtable]$Tokens = @{}
    )

    $content = Get-Content -LiteralPath $TemplatePath -Raw
    foreach ($entry in $Tokens.GetEnumerator()) {
        $needle = "{{" + $entry.Key + "}}"
        $content = $content.Replace($needle, [string]$entry.Value)
    }

    return $content
}

function Get-OverlayContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateRoot,
        [Parameter(Mandatory)]
        [string]$OriginalSkillName,
        [hashtable]$Tokens = @{}
    )

    $templatePath = Join-Path $TemplateRoot ("{0}.md" -f $OriginalSkillName)
    if (-not (Test-Path -LiteralPath $templatePath)) {
        return ""
    }

    return Expand-TemplateFile -TemplatePath $templatePath -Tokens $Tokens
}

function Append-SkillOverlay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SkillFilePath,
        [Parameter(Mandatory)]
        [string]$OverlayContent,
        [string]$Heading = "Host Adaptation"
    )

    if ([string]::IsNullOrWhiteSpace($OverlayContent)) {
        return
    }

    $existing = Get-Content -LiteralPath $SkillFilePath -Raw
    $normalized = $existing.TrimEnd()
    $overlaySection = @(
        "## $Heading"
        ""
        $OverlayContent.Trim()
    ) -join "`n"

    Set-Content -LiteralPath $SkillFilePath -Value ($normalized + "`n`n" + $overlaySection + "`n") -Encoding utf8
}

function Get-JsonObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{}
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @{}
    }

    return ($raw | ConvertFrom-Json -AsHashtable)
}

function Save-JsonObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory -Path $parent
    }

    $json = $Data | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value ($json + "`n") -Encoding utf8
}

function Upsert-ManagedBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$BlockId,
        [Parameter(Mandatory)]
        [string]$Content
    )

    $begin = "<!-- BEGIN $BlockId -->"
    $end = "<!-- END $BlockId -->"
    $block = @(
        $begin
        $Content.Trim()
        $end
    ) -join "`n"

    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory -Path $parent
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Set-Content -LiteralPath $Path -Value ($block + "`n") -Encoding utf8
        return
    }

    $existing = Get-Content -LiteralPath $Path -Raw
    $pattern = "(?s)" + [regex]::Escape($begin) + ".*?" + [regex]::Escape($end)

    if ([regex]::IsMatch($existing, $pattern)) {
        $updated = [regex]::Replace($existing, $pattern, $block, 1)
        Set-Content -LiteralPath $Path -Value ($updated.TrimEnd() + "`n") -Encoding utf8
        return
    }

    $separator = if ([string]::IsNullOrWhiteSpace($existing)) { "" } else { "`n`n" }
    $merged = $existing.TrimEnd() + $separator + $block + "`n"
    Set-Content -LiteralPath $Path -Value $merged -Encoding utf8
}

function New-ClineChineseTriggerRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$TriggerData,
        [string]$NamePrefix = ""
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Chinese Trigger Hints")
    $lines.Add("")
    $lines.Add("When the user speaks Chinese, map the following phrases to the installed superpowers skills before defaulting to generic planning.")
    $lines.Add("")

    foreach ($entry in $TriggerData) {
        $installedName = Get-InstalledSkillName -OriginalName $entry.name -NamePrefix $NamePrefix
        $summary = [string]$entry.summary_zh
        $phrases = Get-SkillTriggerPhraseText -TriggerEntry $entry
        $example = [string]$entry.example_cn

        $lines.Add(('## `{0}`' -f $installedName))
        if (-not [string]::IsNullOrWhiteSpace($summary)) {
            $lines.Add("")
            $lines.Add(("用途：{0}" -f $summary))
        }
        if (-not [string]::IsNullOrWhiteSpace($phrases)) {
            $lines.Add(("常见说法：{0}" -f $phrases))
        }
        if (-not [string]::IsNullOrWhiteSpace($example)) {
            $lines.Add(("示例：{0}" -f $example))
        }
        $lines.Add("")
    }

    return (($lines -join "`n").TrimEnd() + "`n")
}

function New-DroidChineseTriggerGuide {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$TriggerData,
        [string]$NamePrefix = ""
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Chinese trigger guide for installed superpowers skills:")
    $lines.Add("")

    foreach ($entry in $TriggerData) {
        $installedName = Get-InstalledSkillName -OriginalName $entry.name -NamePrefix $NamePrefix
        $phrases = Get-SkillTriggerPhraseText -TriggerEntry $entry
        $summary = [string]$entry.summary_zh

        if ([string]::IsNullOrWhiteSpace($phrases)) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($summary)) {
            $lines.Add(('- `{0}`: {1}' -f $installedName, $phrases))
        }
        else {
            $lines.Add(('- `{0}`: {1}。常见说法：{2}' -f $installedName, $summary, $phrases))
        }
    }

    return (($lines -join "`n").TrimEnd() + "`n")
}

Export-ModuleMember -Function @(
    "Assert-WindowsOnly",
    "Assert-RequiredCommand",
    "Ensure-Directory",
    "Resolve-AbsolutePath",
    "Resolve-SuperpowersSource",
    "Get-UpstreamSkillDirectories",
    "Remove-ExistingTarget",
    "Copy-DirectoryContents",
    "Convert-SuperpowersSkillToClinePrompt",
    "Convert-SuperpowersSkillToSingleFileMarkdown",
    "Set-MarkdownFrontMatterValue",
    "Rename-SkillFrontMatter",
    "Get-InstalledSkillName",
    "Get-SkillTriggerData",
    "Get-SkillTriggerEntry",
    "Get-SkillTriggerPhraseText",
    "Add-SkillDescriptionTriggerHints",
    "Expand-TemplateFile",
    "Get-OverlayContent",
    "Append-SkillOverlay",
    "Get-JsonObject",
    "Save-JsonObject",
    "New-ClineChineseTriggerRule",
    "New-DroidChineseTriggerGuide",
    "Upsert-ManagedBlock"
)
