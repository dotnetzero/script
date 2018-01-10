function Show-Message {
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
        Write-Host -ForegroundColor Green $headerLine
        Write-Host "  " -NoNewline
    }
    Write-Host -ForegroundColor Green $Message 
    
    if ($Header) {
        Write-Host -ForegroundColor Green $headerLine 
    }
}
