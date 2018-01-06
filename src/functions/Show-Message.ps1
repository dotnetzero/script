function Show-Message {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][string]$Message
    )
    Write-Host -ForegroundColor Green $Message 
}
