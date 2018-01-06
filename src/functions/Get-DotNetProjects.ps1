function Get-DotNetProjects {
    [CmdletBinding()]
    param ()

    process {
        $projects = @{}
        $templates = Get-InstalledDotnetTemplates
        $headerLine = ("-" * 64);
        do {

            Show-Message $headerLine
            Show-Message "  Installed dotnet templates"
            Show-Message $headerLine
            ($templates | Format-Table -HideTableHeaders -Property Index, Name | Out-String).Trim("`r`n") | Show-Message
            Show-Message $headerLine

            if ($projects.Count -gt 0) {
                Show-Message $headerLine
                Show-Message "  $($projects.Count) Selected Project(s)"
                Show-Message $headerLine
                $projects.GetEnumerator() | Sort-Object { $_.Name } | ForEach-Object {
                    $message = " - $($_.Name) `r`n   $($_.Value.Name)"
                    Show-Message $message 
                }
                Show-Message $headerLine
            }

            #capture user input
            $key = "(blank to quit/finish)"
            $r = $host.ui.Prompt("Adding projects to your solution", "Select dotnet item # to add to your solution", $key)

            $hasValue = $r[$key].Length -gt 0

            if ($hasValue -eq $false) {
                return $projects
            }

            $result = ($r[$key]).Trim()

            $dotnetItem = $templates | Where-Object Index -eq $result
            if ($dotnetItem -eq $null) {
                Write-Host "Please supply a value" -ForegroundColor Yellow
            }
            else {
                $key = $dotnetItem.Name + " Name"
                $projectName = $host.ui.Prompt($null, $null, $key)
                $projectName = $projectName[$key]
                if ($projects[$projectName] -ne $null) {
                    Write-Host -ForegroundColor Yellow "`r`nProject already $projectName exists`r`n"
                    continue
                }

                $projects.Add($projectName, $dotnetItem)

                if (($dotnetItem.Name.ToLower() -like "*test*"  ) `
                        -or ($dotnetItem.Name.ToLower() -like "*config*") `
                        -or ($dotnetItem.Name.ToLower() -like "*page*"  ) `
                        -or ($dotnetItem.Name.ToLower() -like "*mvc*"   ) `
                        -or ($dotnetItem.Name.ToLower() -like "*file*"  )
                ) {}
                else {
                    $message = "Do you want to add unit test project?"
                    $optionArray = @()
                    $optionArray += New-Object System.Management.Automation.Host.ChoiceDescription "&No", "No test project"

                    $existingTestProject = $projects.GetEnumerator() | Where-Object {
                        Write-Verbose "Tags: $($_.Value.Tags) -contains 'test'"
                        if ($_.Value.Tags -contains "test") {
                            Write-Verbose "$($_.Value.Name) in the selected projects"
                            return $_
                        }
                    } | Select-Object -First 1

                    # Check for existing test projects added to the collection
                    if ($existingTestProject -eq $null) {
                        Write-Verbose "No existing test projects selected"
                        $templates | Get-TestProjectTemplates | ForEach-Object { 
                            $short = $_.ShortName
                            $description = $_.Name
                            $item = New-Object System.Management.Automation.Host.ChoiceDescription "&$short", "Add $description" 
                            $optionArray += $item
                        }
                        $result = $host.ui.PromptForChoice($null, $message, $optionArray, 0) 
                        $selectedShortName = (($optionArray[$result]).Label -replace "&", "")
                        ($templates | Where-Object ShortName -eq $selectedShortName) | ForEach-Object { $projects.Add("$projectName.Tests", $_ ) }
                    }
                    else {
                        $testProjectName = $existingTestProject.Value.Name
                        Write-Verbose "$($existingTestProject.Key) already selected for the solution"
                        $optionArray += New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Add $testProjectName"
                        $result = $host.ui.PromptForChoice($null, $message, $optionArray, 1)
                        if (($optionArray[$result]).Label -eq "&Yes") {
                            $projects.Add("$projectName.Tests", $existingTestProject.Value ) 
                        }
                    }

                }

            }

        } while ($true)
    }
}
