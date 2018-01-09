function Test-EnvironmentPath {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline, Mandatory = $true)][String]$Search
    )

    return (($Env:Path.Split(";") | `
                Where-Object { -not [string]::IsNullOrEmpty($_) } | `
                Where-Object { (Test-Path $_ -PathType Container) -and ($_ -like "*$Search*") }) |`
            Select-Object -First 1) -ne $null
}
