
function New-SafeName {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string]$Name
    )

    $regex = "[^\x30-\x39\x41-\x5A\x61-\x7A]+"
    return $Name -replace $regex, ""
}
