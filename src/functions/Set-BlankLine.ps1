function Set-BlankLine {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][string]$TargetString,
        [int]$Count = 1
    )

    return $TargetString.Trim() + "`r`n" * ($Count + 1)
}