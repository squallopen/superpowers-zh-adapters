function ConvertTo-PwshCommandArgument {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return '""'
    }

    if (($Value -is [System.Array]) -and (-not ($Value -is [string]))) {
        return ((@($Value | ForEach-Object { ConvertTo-PwshCommandArgument -Value $_ })) -join ",")
    }

    if ($Value -is [bool]) {
        return ('$' + $Value.ToString().ToLowerInvariant())
    }

    $text = [string]$Value
    $escaped = $text.Replace('`', '``').Replace('"', '`"')
    return ('"{0}"' -f $escaped)
}

function Get-PwshRerunCommand {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$BoundParameters
    )

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add("pwsh")
    $parts.Add((ConvertTo-PwshCommandArgument -Value $ScriptPath))

    foreach ($entry in $BoundParameters.GetEnumerator()) {
        $name = [string]$entry.Key
        $value = $entry.Value

        if ($value -is [System.Management.Automation.SwitchParameter]) {
            if ($value.IsPresent) {
                $parts.Add(("-{0}" -f $name))
            }

            continue
        }

        $parts.Add(("-{0}" -f $name))
        $parts.Add((ConvertTo-PwshCommandArgument -Value $value))
    }

    return ($parts -join " ")
}

function Exit-IfUnsupportedPowerShell {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$BoundParameters
    )

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        return
    }

    $command = Get-PwshRerunCommand -ScriptPath $ScriptPath -BoundParameters $BoundParameters

    Write-Host ""
    Write-Host "请改用 PowerShell 7（pwsh）执行这个脚本。"
    Write-Host ("当前环境：PowerShell {0}" -f $PSVersionTable.PSVersion)
    Write-Host ("请执行：{0}" -f $command)
    Write-Host ""
    exit 1
}
