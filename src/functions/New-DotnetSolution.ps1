function New-DotnetSolution {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][HashTable]$DotNetProjects,
        [string]$SourceDirectory = "src",
        [string]$SolutionName
    )

    process {

        $buildPreventionIssues = @()    

        # Use incoming solution name of determine based on current directory name
        if ($SolutionName) {
            Write-Host -ForegroundColor Yellow "Using solution name $SolutionName"
        }
        else {
            $SolutionName = (Split-Path -Path (Get-Location) -Leaf)
            Write-Host -ForegroundColor Yellow "Setting solution name to $SolutionName"
        }

        # Create solution file
        if ((Test-Path -Path "$SourceDirectory\$SolutionName.sln") -eq $false) {
            Write-Verbose -Message "Creating solution file $SolutionName at from $SourceDirectory"
            dotnet new sln --name $SolutionName --output $SourceDirectory
        }

        # Create projects
        $DotNetProjects.GetEnumerator() | Foreach-Object {
            $projectName = $_.Key
            $projectShortName = $_.Value.ShortName
            $outputDirectory = "$SourceDirectory\$projectName"
            Write-Verbose -Message "Creating $projectName ($projectShortName) at $outputDirectory"
            dotnet new $projectShortName -o $outputDirectory
        }

        # Check for SPA projects and 'npm install' those
        $packageJsonFiles = Get-ChildItem -Recurse -Path $SourceDirectory -Filter package.json
        if($packageJsonFiles.Count -gt 0){
            Write-Verbose -Message "SPA projects found"
            if (Test-EnvironmentPath "npm") {
                $DotNetProjects.GetEnumerator() | Foreach-Object {
                    $projectName = $_.Key
                    $outputDirectory = "$SourceDirectory\$projectName"
                    if (Test-Path -Path "$outputDirectory\package.json") {
                        Show-Message "Calling npm install from $outputDirectory"
                        Write-Verbose -Message "Changing directories to $outputDirectory"
                        Push-Location
                        Set-Location -Path $outputDirectory
                        Write-Verbose -Message "Calling npm install"
                        npm install
                        Pop-Location
                        Write-Verbose -Message "Changing directories back to to $(Get-Location))"
                    }
                }
            }
            else {
                $errorMissingNpm = "npm not installed"
                $buildPreventionIssues += $errorMissingNpm
                Write-Verbose -Message $errorMissingNpm
                Show-Warning -Header -Message "This solution appears to have at least one SPA application`r`n  However npm is not installed please visit https://nodejs.org"
            }
        }

        # Use naming concention to add project references for test projects
        $DotNetProjects.GetEnumerator() | Foreach-Object {
            $tags = $_.Value.Tags
            if ($tags -contains "test") {
                $projectName = $_.Key
                $testProject = "$SourceDirectory\$projectName"
                $targetProject = "$SourceDirectory\$projectName\$projectName.csproj" -replace ".Tests", ""
                Write-Verbose -Message "Adding reference to $testProject from $targetProject"
                dotnet add $testProject reference $targetProject
            }
        }

        # Add projects to solution file
        $DotNetProjects.GetEnumerator() | Foreach-Object {
            $projectName = $_.Key
            $SolutionPath = "$SourceDirectory\$SolutionName.sln"
            $projectPath = "$SourceDirectory\$projectName\$projectName.csproj"
            Write-Verbose -Message "Adding project $projectPath to solution file $SolutionPath"
            dotnet sln $SolutionPath add $projectPath
        }

        if($buildPreventionIssues.Count -eq 0){
            # Now that everything has been established call the build command
            dotnet build "$SourceDirectory\$SolutionName.sln"

            # and the test comamnd for our test project(s)
            $DotNetProjects.GetEnumerator() | Foreach-Object {
                $tags = $_.Value.Tags
                if ($tags -contains "test") {
                    $projectName = $_.Key
                    $testProject = "$SourceDirectory\$projectName"
                    dotnet test $testProject --no-build
                }
            }
        }
        else {
            Show-Warning "Could not build / test for the following reasons" -Header
            $buildPreventionIssues | Foreach-Object { Show-Warning -Message "  - $($_)" }
        }
    }
}
