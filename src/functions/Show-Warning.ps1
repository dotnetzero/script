function Show-Warning {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][string]$Message,
        [switch]$Header
    )
    
    $headerLine = ("-" * 64);

    if ($Header) {
        Write-Host -ForegroundColor Yellow $headerLine
        Write-Host "  " -NoNewline
    }
    Write-Host -ForegroundColor Yellow $Message 
    
    if ($Header) {
        Write-Host -ForegroundColor Yellow $headerLine 
    }
}

