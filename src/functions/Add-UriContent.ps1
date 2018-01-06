function Add-UriContent {
    [CmdletBinding()]
    param (
        $Message,
        $Uri,
        $BuildScriptPath,
        [switch]$Enable,
        [hashtable]$Decode
    )
    if ($enable) {

        Show-Message $Message
        $progressPreference = 'silentlyContinue'
        $content = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} ).content
        $progressPreference = 'Continue'
        if ($Decode) {
            $Decode.GetEnumerator() | ForEach-Object {
                $key = $_.Key; $value = $_.Value;
                $content = ($content -replace $key, $value)
            }
        }
        Add-Content -Path $BuildScriptPath -Value $content -Encoding Ascii  | Out-Null
    }
}
