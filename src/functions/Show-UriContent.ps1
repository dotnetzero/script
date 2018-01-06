function Show-UriContent {
    [CmdletBinding()]
    param (
        $Uri
    )
    $progressPreference = 'silentlyContinue'
    $content = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} ).content
    $progressPreference = 'Continue'
    Write-Host $content
}
