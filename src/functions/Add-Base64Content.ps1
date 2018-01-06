function Add-Base64Content {
    [CmdletBinding()]
    param (
        $Message,
        $Base64Content,
        $BuildScriptPath,
        [switch]$Enable,
        [hashtable]$Decode
    )
    if ($enable) {

        Show-Message $Message
        $content = Expand-String -Base64Content $Base64Content
        if ($Decode) {
            $Decode.GetEnumerator() | ForEach-Object {
                $key = $_.Key; $value = $_.Value;
                $content = ($content -replace $key, $value)
            }
        }
        Add-Content -Path $BuildScriptPath -Value $content -Encoding Ascii  | Out-Null
    }
}
