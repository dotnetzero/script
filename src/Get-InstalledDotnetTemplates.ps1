function Get-InstalledDotnetTemplates {
    [CmdletBinding()]
    param ()

    process {

        $installedTemplates = @()

        if (($env:Path.Split(";") | Select-String dotnet)) {
            # Filter out the blank lines
            $dotnetnewlist = (dotnet new -l) | Where-Object { $_ -notcontains "" }

            #grab the text following the table header + the console horizontial rule
            $templates = $dotnetnewlist | `
                Select-Object -Skip (($dotnetnewlist | `
                        Select-String "^Templates" -CaseSensitive).LineNumber + 1)

            For ($i = 0; $i -lt $templates.Length; $i++) {
                $templateName = $templates[$i].SubString(0, 50).Trim()
                $templateShortName = $templates[$i].SubString(50, 17).Trim()
                $templateLanguage = $templates[$i].SubString(67, 18).Trim()
                $templateTags = $templates[$i].SubString(85).Trim()

                Write-Verbose "Creating $templateName ($templateShortName) using $templateLanguage with tags $templateTags"

                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType NoteProperty -Name Index -Value ($i + 1)
                $object | Add-Member -MemberType NoteProperty -Name Name -Value $templateName
                $object | Add-Member -MemberType NoteProperty -Name ShortName -Value $templateShortName
                $object | Add-Member -MemberType NoteProperty -Name Language -Value $templateLanguage.Split(",")
                $object | Add-Member -MemberType NoteProperty -Name Tags -Value $templateTags.Split("/")

                $installedTemplates += $object
            }
        }

        return $installedTemplates
    }
}

function New-DotnetSolution {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][HashTable]$DotNetProjects,
        [string]$SourceDirectory = "src",
        [string]$SolutionName
    )

    process {
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
        
        # Not that everything has been established call the build command
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
}

function Get-TestProjectTemplates {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][Array]$DotNetProjects
    )

    process {
        return $DotNetProjects | Where-Object { $_.Tags -contains "test" }
    }
}

function Get-DotNetProjects {
    [CmdletBinding()]
    param ()

    process {
        $projects = @{}

        $templates = Get-InstalledDotnetTemplates

        do {

            Write-Host -ForegroundColor Cyan ("-" * 64)
            Write-Host -ForegroundColor Cyan "  Installed dotnet templates"
            Write-Host -ForegroundColor Cyan ("-" * 64)
            ($templates | Format-Table -HideTableHeaders -Property Index, Name | Out-String).Trim("`r`n") | Write-Host -ForegroundColor Cyan
            Write-Host -ForegroundColor Cyan ("-" * 64)

            if ($projects.Count -gt 0) {
                Write-Host -ForegroundColor Green ("-" * 64)
                Write-Host -ForegroundColor Green $projects.Count "Selected Project(s)"
                Write-Host -ForegroundColor Green ("-" * 64)
                $projects.GetEnumerator() | ForEach-Object { Write-Host -ForegroundColor Green " -" $_.Name "`r`n  "  $_.Value.Name }
                Write-Host -ForegroundColor Green ("-" * 64)
            }

            #capture user input
            $key = "(blank to quit/finish)"
            $r = $host.ui.Prompt("Adding projects to your solution", "Select dotnet item to add to your solution", $key)

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
