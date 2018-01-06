function Get-TestProjectTemplates {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][Array]$DotNetProjects
    )

    process {
        return $DotNetProjects | Where-Object { $_.Tags -contains "test" }
    }
}
