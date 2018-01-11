function New-VstsYamlBuild {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][HashTable]$DotNetProjects,
        [string]$SourceDirectory = "src",
        [string]$SolutionName
    )

    $hasTestProjects = (
        $DotNetProjects.GetEnumerator() | Where-Object {
            Write-Verbose "Tags: $($_.Value.Tags) -contains 'test'"
            if ($_.Value.Tags -contains "test") {
                Write-Verbose "$($_.Value.Name) in the selected projects"
                return $_
            }
        } | Select-Object -First 1) -ne $null
    
    $buildDefinition = $dotnetzero.vstsyaml_queue | Expand-String | Set-BlankLine
    $buildDefinition += "steps:" | Set-BlankLine
    $buildDefinition += $dotnetzero.vstsyaml_dotnet_restore | Expand-String | Set-BlankLine
    $buildDefinition += $dotnetzero.vstsyaml_dotnet_build | Expand-String | Set-BlankLine

    if ($hasTestProjects -eq $true) {
        $buildDefinition += $dotnetzero.vstsyaml_dotnet_test | Expand-String | Set-BlankLine
        $buildDefinition += $dotnetzero.vstsyaml_publish_test_results | Expand-String | Set-BlankLine
    }

    $buildDefinition += $dotnetzero.vstsyaml_dotnet_publish | Expand-String | Set-BlankLine
    $buildDefinition += $dotnetzero.vstsyaml_publish_build_artifacts | Expand-String | Set-BlankLine

    return $buildDefinition
}