function New-VstsYamlBuild {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][HashTable]$DotNetProjects,
        [parameter(ValueFromPipeline)][string]$SourceDirectory = "src",
        [parameter(ValueFromPipeline)][string]$SolutionName
    )
    process {

        Write-Verbose "Processing $($DotNetProjects.Count) projects"

        $testProjects = (
            $DotNetProjects.GetEnumerator() | Where-Object {
                $tagSearch = "test"
                Write-Verbose "Tags: $($_.Value.Tags) -contains '$tagSearch'"
                if ($_.Value.Tags -contains $tagSearch) {
                    Write-Verbose "Tag $($_.Value.Name) found in the selected projects"
                    return $_
                }
            })

        $webProjects = (
            $DotNetProjects.GetEnumerator() | Where-Object {
                $tagSearch = "web"
                Write-Verbose "Tags: $($_.Value.Tags) -contains '$tagSearch'"
                if ($_.Value.Tags -contains $tagSearch) {
                    Write-Verbose "Tag $($_.Value.Name) found in the selected projects"
                    return $_
                }
            })
        
        $buildDefinition += "steps:" | Set-BlankLine
        $buildDefinition += $dotnetzero.vstsyaml_dotnet_restore | Expand-String | Set-BlankLine
        Write-Verbose "Added Restore"
        $buildDefinition += ($dotnetzero.vstsyaml_dotnet_build | Expand-String | Set-BlankLine) -replace "__SOLUTION_PATH__", $("$SourceDirectory/$SolutionName.sln")
        Write-Verbose "Added Build"

        $testProjects | ForEach-Object {
            $projectName = $($_.Key)
            $content = ($dotnetzero.vstsyaml_dotnet_test | Expand-String | Set-BlankLine)
            $content = $content -replace "__PROJECT_PATH__", $("$SourceDirectory/$projectName/$projectName.csproj")
            $content = $content -replace "__PROJECT_NAME__", $projectName
            $buildDefinition += $content
            Write-Verbose "Added Test $projectName"
        }

        $webProjects | ForEach-Object {
            $projectName = $($_.Key)
            $content = $dotnetzero.vstsyaml_dotnet_publish | Expand-String | Set-BlankLine
            $content = $content -replace "__PROJECT_PATH__", $("$SourceDirectory/$projectName/$projectName.csproj")
            $content = $content -replace "__PROJECT_NAME__", $projectName
            $buildDefinition += $content
            Write-Verbose "Added dotnet publish $projectName"
        }
        
        if ($testProjects.Count -gt 0) {
            $buildDefinition += $dotnetzero.vstsyaml_publish_test_results | Expand-String | Set-BlankLine
            Write-Verbose "Added Publish Test Results"
        }

        $buildDefinition += $dotnetzero.vstsyaml_publish_build_artifacts | Expand-String | Set-BlankLine
        Write-Verbose "Added publish build artifacts"

        return $buildDefinition
 
    }
}