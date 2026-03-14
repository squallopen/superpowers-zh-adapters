Set-StrictMode -Version Latest

function Assert-WindowsOnly {
    [CmdletBinding()]
    param()

    if ($env:OS -ne "Windows_NT") {
        throw "当前仓库只提供 Windows PowerShell 安装脚本。以后如果要支持其他系统，请在 scripts/ 下新增新的运行时目录。"
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

    $message = "缺少必需命令 '$CommandName'。"
    if (-not [string]::IsNullOrWhiteSpace($InstallHint)) {
        $message += " $InstallHint"
    }

    throw $message
}

function Backup-ExistingFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Reason = ""
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $parent = Split-Path -Parent $Path
    $leaf = Split-Path -Leaf $Path
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $parent ("{0}.superpowers.bak-{1}" -f $leaf, $timestamp)

    Copy-Item -LiteralPath $Path -Destination $backupPath -Force

    if ([string]::IsNullOrWhiteSpace($Reason)) {
        Write-Host ("已创建备份：{0}" -f $backupPath)
    }
    else {
        Write-Host ("已创建备份：{0}（{1}）" -f $backupPath, $Reason)
    }

    return $backupPath
}

function Confirm-UserMergeAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string]$Guidance,
        [switch]$AssumeYes
    )

    if ($AssumeYes) {
        Write-Warning "$Title 已由 -AssumeYes 自动确认。"
        return
    }

    Write-Warning $Title
    Write-Host ""
    Write-Host $Guidance
    Write-Host ""

    $answer = Read-Host "如果你已经看完并确认继续，请输入 YES；其他任意输入将取消"
    if ($answer -cne "YES") {
        throw "用户取消了本次操作。"
    }
}

function Backup-ExistingTargets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HostName,
        [AllowEmptyCollection()]
        [string[]]$Paths
    )

    $existingPaths = @($Paths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) })
    if ($existingPaths.Count -eq 0) {
        return $null
    }

    $backupParent = Split-Path -Parent $existingPaths[0]
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $safeHostName = ($HostName.ToLowerInvariant() -replace "[^a-z0-9-]", "-")
    $backupRoot = Join-Path $backupParent ("superpowers-{0}-backup-{1}" -f $safeHostName, $timestamp)

    Ensure-Directory -Path $backupRoot

    foreach ($path in $existingPaths) {
        $leaf = Split-Path -Leaf $path
        Copy-Item -LiteralPath $path -Destination (Join-Path $backupRoot $leaf) -Recurse -Force
    }

    Write-Host ("已为 {0} 创建备份：{1}" -f $HostName, $backupRoot)
    return $backupRoot
}

function Resolve-ExistingSkillAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HostName,
        [AllowEmptyCollection()]
        [string[]]$ExistingPaths,
        [switch]$Force,
        [switch]$AssumeYes
    )

    $existingPaths = @($ExistingPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) })
    if ($existingPaths.Count -eq 0) {
        return $false
    }

    if ($Force) {
        Write-Host ("{0}：发现 {1} 个已安装的 superpowers skill，将直接更新。" -f $HostName, $existingPaths.Count)
        return $true
    }

    if ($AssumeYes) {
        Write-Host ("{0}：发现 {1} 个已安装的 superpowers skill。由于使用了 -AssumeYes，已自动确认覆盖。" -f $HostName, $existingPaths.Count)
        return $true
    }

    Write-Warning ("{0}：发现 {1} 个已安装的 superpowers skill。" -f $HostName, $existingPaths.Count)
    Write-Host ""
    Write-Host "这通常说明你不是第一次安装，而是在重装或更新 superpowers。"
    Write-Host "建议直接覆盖旧的 superpowers 安装。脚本会先备份这些已有的 superpowers skill。"
    Write-Host ""
    Write-Host "输入 YES：覆盖旧的 superpowers skill"
    Write-Host "输入 SKIP：保留现状，只安装缺少的 skill"
    Write-Host "其他任意输入：取消整个脚本"
    Write-Host ""

    $answer = Read-Host "请选择"
    if ($answer -ceq "YES") {
        return $true
    }

    if ($answer -ceq "SKIP") {
        Write-Host ("{0}：将保留现有 superpowers skill，只安装缺少的部分。" -f $HostName)
        return $false
    }

    throw ("用户取消了 {0} 的安装或更新。" -f $HostName)
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
            throw "指定的源路径不存在：$resolvedSource"
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

        Assert-RequiredCommand -CommandName "git" -InstallHint "请先安装 Git for Windows：https://git-scm.com/download/win ，然后重新打开 PowerShell。"
        Write-Host "正在从仓库拉取 superpowers 到：$resolvedVendorRoot"
        & git clone --depth 1 $RepositoryUrl $resolvedVendorRoot
        if ($LASTEXITCODE -ne 0) {
            throw "git clone 执行失败，退出码：$LASTEXITCODE"
        }
    }
    elseif ($UpdateSource) {
        Assert-RequiredCommand -CommandName "git" -InstallHint "请先安装 Git for Windows：https://git-scm.com/download/win ，然后重新打开 PowerShell。"
        Write-Host "正在更新已有的 superpowers 源目录：$resolvedVendorRoot"
        & git -C $resolvedVendorRoot pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            throw "git pull 执行失败，退出码：$LASTEXITCODE"
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
        throw "这个 superpowers 源目录里没有 skills 目录：$skillsRoot"
    }

    return Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name
}

function Remove-ExistingTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$AssumeYes
    )

    if (Test-Path -LiteralPath $Path) {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            Write-Warning ("自动删除失败：{0}" -f $Path)
            Write-Host "这通常是 Windows 当前占用、权限异常，或者安全软件暂时拦住了删除。"

            if ($AssumeYes) {
                throw ("自动确认模式下无法继续。请先手动删除这个路径，再重新执行脚本：{0}" -f $Path)
            }

            Write-Host ""
            Write-Host "请你先手动删除上面的路径。"
            Write-Host "删完后回到这里输入 YES，脚本才会继续。"
            Write-Host ""

            $answer = Read-Host "删除完成后请输入 YES 继续；其他任意输入将取消"
            if ($answer -cne "YES") {
                throw "用户取消了本次操作。"
            }

            if (Test-Path -LiteralPath $Path) {
                throw ("目标仍然存在，请先手动删除后再重试：{0}" -f $Path)
            }
        }
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

function Convert-SuperpowersCommitDateText {
    [CmdletBinding()]
    param(
        [string]$Timestamp
    )

    if ([string]::IsNullOrWhiteSpace($Timestamp)) {
        return ""
    }

    try {
        return ([DateTimeOffset]::Parse($Timestamp).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss zzz"))
    }
    catch {
        return $Timestamp
    }
}

function Get-PreferredUpstreamTag {
    [CmdletBinding()]
    param(
        [string[]]$Tags
    )

    $normalizedTags = @($Tags | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [string]$_.Trim() })
    if ($normalizedTags.Count -eq 0) {
        return ""
    }

    $semanticTags = foreach ($tag in $normalizedTags) {
        $candidate = $tag.TrimStart('v', 'V')
        $parsedVersion = $null
        if ([version]::TryParse($candidate, [ref]$parsedVersion)) {
            [pscustomobject]@{
                Tag = $tag
                Version = $parsedVersion
            }
        }
    }

    if (@($semanticTags).Count -gt 0) {
        return ($semanticTags | Sort-Object Version -Descending | Select-Object -First 1).Tag
    }

    return ($normalizedTags | Sort-Object -Descending | Select-Object -First 1)
}

function Get-LatestSemanticVersionTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryUrl
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return ""
    }

    $lines = @(& git ls-remote --tags --refs $RepositoryUrl 2>$null)
    if ($LASTEXITCODE -ne 0 -or $lines.Count -eq 0) {
        return ""
    }

    $tags = foreach ($line in $lines) {
        if ($line -match "refs/tags/(.+)$") {
            $matches[1]
        }
    }

    return Get-PreferredUpstreamTag -Tags $tags
}

function Resolve-UpstreamRef {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryUrl,
        [string]$RequestedRef = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedRef)) {
        return $RequestedRef
    }

    $latestTag = Get-LatestSemanticVersionTag -RepositoryUrl $RepositoryUrl
    if (-not [string]::IsNullOrWhiteSpace($latestTag)) {
        return $latestTag
    }

    return "main"
}

function Format-SuperpowersVersionText {
    [CmdletBinding()]
    param(
        [string]$Tag,
        [string]$CommitShort,
        [string]$Ref,
        [string]$CommitDateText,
        [string]$FallbackText = "未知（当前没有可识别的上游版本信息）"
    )

    $baseText = ""
    if (-not [string]::IsNullOrWhiteSpace($Tag)) {
        $baseText = $Tag
    }
    elseif (-not [string]::IsNullOrWhiteSpace($CommitShort)) {
        if (-not [string]::IsNullOrWhiteSpace($Ref) -and $Ref -ne "HEAD") {
            $baseText = "$Ref@$CommitShort"
        }
        else {
            $baseText = $CommitShort
        }
    }

    if ([string]::IsNullOrWhiteSpace($baseText)) {
        return $FallbackText
    }

    $details = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($CommitDateText)) {
        $details.Add("提交时间 $CommitDateText")
    }
    if ((-not [string]::IsNullOrWhiteSpace($Tag)) -and (-not [string]::IsNullOrWhiteSpace($CommitShort))) {
        $details.Add("commit $CommitShort")
    }

    if ($details.Count -eq 0) {
        return $baseText
    }

    return ("{0}（{1}）" -f $baseText, ($details -join "，"))
}

function Get-SuperpowersSourceManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceRoot
    )

    return Join-Path $SourceRoot ".superpowers-source.json"
}

function Get-SuperpowersInstallMetadataPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MetadataRoot
    )

    return Join-Path $MetadataRoot ".superpowers-install.json"
}

function Get-SuperpowersSourceVersionInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceRoot,
        [string]$RepositoryUrl = ""
    )

    $manifestPath = Get-SuperpowersSourceManifestPath -SourceRoot $SourceRoot
    if (Test-Path -LiteralPath $manifestPath) {
        $manifest = Get-JsonObject -Path $manifestPath
        $tag = [string]$manifest["upstream_tag"]
        $commitShort = [string]$manifest["upstream_commit_short"]
        $ref = [string]$manifest["upstream_ref"]
        $commitDate = [string]$manifest["upstream_commit_date"]
        $commitDateText = [string]$manifest["upstream_commit_date_text"]
        if ([string]::IsNullOrWhiteSpace($commitDateText)) {
            $commitDateText = Convert-SuperpowersCommitDateText -Timestamp $commitDate
        }
        $display = [string]$manifest["upstream_version_text"]
        if ((-not [string]::IsNullOrWhiteSpace($tag)) -or (-not [string]::IsNullOrWhiteSpace($commitDateText)) -or [string]::IsNullOrWhiteSpace($display)) {
            $display = Format-SuperpowersVersionText -Tag $tag -CommitShort $commitShort -Ref $ref -CommitDateText $commitDateText
        }

        return @{
            Display = $display
            Tag = $tag
            Commit = [string]$manifest["upstream_commit"]
            CommitShort = $commitShort
            Ref = $ref
            CommitDate = $commitDate
            CommitDateText = $commitDateText
            RepositoryUrl = if ([string]::IsNullOrWhiteSpace([string]$manifest["repository_url"])) { $RepositoryUrl } else { [string]$manifest["repository_url"] }
            SourceRoot = $SourceRoot
            IsKnown = $true
        }
    }

    $gitDirectory = Join-Path $SourceRoot ".git"
    if ((Test-Path -LiteralPath $gitDirectory) -and (Get-Command git -ErrorAction SilentlyContinue)) {
        $commitShort = (& git -C $SourceRoot rev-parse --short HEAD 2>$null)
        $commit = (& git -C $SourceRoot rev-parse HEAD 2>$null)
        $ref = (& git -C $SourceRoot symbolic-ref --quiet --short HEAD 2>$null)
        $tagLines = @(& git -C $SourceRoot tag --points-at HEAD 2>$null)
        $commitDate = (& git -C $SourceRoot show -s --format=%cI HEAD 2>$null)

        if (-not [string]::IsNullOrWhiteSpace(($commitShort | Select-Object -First 1))) {
            $tag = Get-PreferredUpstreamTag -Tags $tagLines
            $commitShort = [string]($commitShort | Select-Object -First 1)
            $commit = [string]($commit | Select-Object -First 1)
            $ref = [string]($ref | Select-Object -First 1)
            $commitDate = [string]($commitDate | Select-Object -First 1)
            $commitDateText = Convert-SuperpowersCommitDateText -Timestamp $commitDate

            return @{
                Display = (Format-SuperpowersVersionText -Tag $tag -CommitShort $commitShort -Ref $ref -CommitDateText $commitDateText)
                Tag = $tag
                Commit = $commit
                CommitShort = $commitShort
                Ref = $ref
                CommitDate = $commitDate
                CommitDateText = $commitDateText
                RepositoryUrl = $RepositoryUrl
                SourceRoot = $SourceRoot
                IsKnown = $true
            }
        }
    }

    return @{
        Display = "未知（当前没有可识别的上游版本信息）"
        Tag = ""
        Commit = ""
        CommitShort = ""
        Ref = ""
        CommitDate = ""
        CommitDateText = ""
        RepositoryUrl = $RepositoryUrl
        SourceRoot = $SourceRoot
        IsKnown = $false
    }
}

function Get-InstalledSuperpowersVersionText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MetadataRoot,
        [switch]$HasExistingInstall
    )

    $metadataPath = Get-SuperpowersInstallMetadataPath -MetadataRoot $MetadataRoot
    if (Test-Path -LiteralPath $metadataPath) {
        $metadata = Get-JsonObject -Path $metadataPath
        $display = [string]$metadata["upstream_version_text"]
        if ([string]::IsNullOrWhiteSpace($display)) {
            $display = Format-SuperpowersVersionText `
                -Tag ([string]$metadata["upstream_tag"]) `
                -CommitShort ([string]$metadata["upstream_commit_short"]) `
                -Ref ([string]$metadata["upstream_ref"]) `
                -CommitDateText ([string]$metadata["upstream_commit_date_text"])
        }
        if (-not [string]::IsNullOrWhiteSpace($display)) {
            return $display
        }
    }

    if ($HasExistingInstall) {
        return "未知（发现已安装内容，但旧安装没有记录版本）"
    }

    return "未安装"
}

function Save-SuperpowersSourceManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceRoot,
        [Parameter(Mandatory)]
        [hashtable]$VersionInfo
    )

    if (-not $VersionInfo["IsKnown"]) {
        return
    }

    $manifestPath = Get-SuperpowersSourceManifestPath -SourceRoot $SourceRoot
    Save-JsonObject -Path $manifestPath -Data @{
        repository_url = [string]$VersionInfo["RepositoryUrl"]
        upstream_tag = [string]$VersionInfo["Tag"]
        upstream_ref = [string]$VersionInfo["Ref"]
        upstream_commit = [string]$VersionInfo["Commit"]
        upstream_commit_short = [string]$VersionInfo["CommitShort"]
        upstream_commit_date = [string]$VersionInfo["CommitDate"]
        upstream_commit_date_text = [string]$VersionInfo["CommitDateText"]
        upstream_version_text = [string]$VersionInfo["Display"]
        detected_at = (Get-Date).ToString("o")
    }
}

function Save-SuperpowersInstallMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MetadataRoot,
        [Parameter(Mandatory)]
        [string]$HostName,
        [Parameter(Mandatory)]
        [hashtable]$VersionInfo,
        [Parameter(Mandatory)]
        [string]$SourceRoot,
        [Parameter(Mandatory)]
        [int]$SkillCount,
        [string]$NamePrefix = ""
    )

    $metadataPath = Get-SuperpowersInstallMetadataPath -MetadataRoot $MetadataRoot
    $displayText = [string]$VersionInfo["Display"]
    if ((-not $VersionInfo["IsKnown"]) -and ($displayText -eq "未知（当前没有可识别的上游版本信息）")) {
        $displayText = "未知（上次安装时没有拿到上游版本信息）"
    }

    Save-JsonObject -Path $metadataPath -Data @{
        host = $HostName
        source_root = $SourceRoot
        repository_url = [string]$VersionInfo["RepositoryUrl"]
        upstream_tag = [string]$VersionInfo["Tag"]
        upstream_ref = [string]$VersionInfo["Ref"]
        upstream_commit = [string]$VersionInfo["Commit"]
        upstream_commit_short = [string]$VersionInfo["CommitShort"]
        upstream_commit_date = [string]$VersionInfo["CommitDate"]
        upstream_commit_date_text = [string]$VersionInfo["CommitDateText"]
        upstream_version_text = $displayText
        installed_at = (Get-Date).ToString("o")
        installed_skill_count = $SkillCount
        name_prefix = $NamePrefix
    }
}

function Show-SuperpowersVersionBanner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HostName,
        [Parameter(Mandatory)]
        [string]$CurrentInstalledVersion,
        [Parameter(Mandatory)]
        [string]$PlannedVersion
    )

    Write-Host ""
    Write-Host ("{0} 上游版本信息" -f $HostName)
    Write-Host ("当前已装版本：  {0}" -f $CurrentInstalledVersion)
    Write-Host ("准备安装版本：  {0}" -f $PlannedVersion)
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
    $beginCount = [regex]::Matches($existing, [regex]::Escape($begin)).Count
    $endCount = [regex]::Matches($existing, [regex]::Escape($end)).Count

    if ($beginCount -ne $endCount -or $beginCount -gt 1) {
        throw ("检测到说明文件里的 superpowers 标记不完整或重复。为避免误覆盖，脚本已停止：{0}" -f $Path)
    }

    if (($beginCount -eq 1) -and ($endCount -eq 1) -and (-not [regex]::IsMatch($existing, $pattern))) {
        throw ("检测到说明文件里的 superpowers 标记顺序异常。为避免误覆盖，脚本已停止：{0}" -f $Path)
    }

    if (($beginCount -eq 1) -and ($endCount -eq 1)) {
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
    $lines.Add("已安装 superpowers skill 的中文触发参考：")
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
    "Backup-ExistingFile",
    "Backup-ExistingTargets",
    "Confirm-UserMergeAction",
    "Resolve-ExistingSkillAction",
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
    "Get-SuperpowersSourceVersionInfo",
    "Get-InstalledSuperpowersVersionText",
    "Resolve-UpstreamRef",
    "Save-SuperpowersSourceManifest",
    "Save-SuperpowersInstallMetadata",
    "Show-SuperpowersVersionBanner",
    "New-ClineChineseTriggerRule",
    "New-DroidChineseTriggerGuide",
    "Upsert-ManagedBlock"
)
