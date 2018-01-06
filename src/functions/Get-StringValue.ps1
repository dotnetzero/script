function Get-StringValue {
    [CmdletBinding()]
    param (
        [string]$Title,
        [string]$Message,
        [string]$Default
    )

    $key = if ([string]::IsNullOrWhiteSpace($default)) { "(default blank)" } else { "(default $default)" }
    $result = ""

    do {
        $r = $host.ui.Prompt($title, $message, $key)
        $hasValue = $r[$key].Length -gt 0

        $result = if ($hasValue) {
            $r[$key]
        }
        else {
            $default
        }

        if ($result.Length -eq 0) {
            Write-Host "Please supply a value" -ForegroundColor Yellow
        }
    } while ($result.Length -eq 0)

    return $result
}
