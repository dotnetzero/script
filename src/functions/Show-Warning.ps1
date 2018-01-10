function Show-Warning {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][string]$Message,
        [switch]$Header
    )

    if([string]::IsNullOrWhiteSpace($message)){
        return
    }

    $headerLine = ("-" * 67);

    if ($Header) {
        Write-Host -ForegroundColor Yellow $headerLine
        Write-Host "  " -NoNewline
    }
    Write-Host -ForegroundColor Yellow $Message 
    
    if ($Header) {
        Write-Host -ForegroundColor Yellow $headerLine 
    }
}
