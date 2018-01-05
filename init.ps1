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
                        if ($_.Value.Tags -contains "test") {
                            return $_
                        }
                    }

                    # Check for existing test projects added to the collection
                    if ($existingTestProject -eq $null) {
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
                        $optionArray += New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Add $testProjectName"
                        $result = $host.ui.PromptForChoice($null, $message, $optionArray, 0)
                        if (($optionArray[$result]).Label -eq "&Yes") {
                            $projects.Add("$projectName.Tests", $existingTestProject.Value ) 
                        }
                    }

                }

            }

        } while ($true)
    }
}

function Get-BooleanValue {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string]$Message,
        [boolean]$Default
    )

    $index = if ($Default) { 0 } else { 1 }
    $enabled = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Enable $Title"
    $disabled = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Disable $Title"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($enabled, $disabled)
    $result = $Host.UI.PromptForChoice($Title, $Message, $options, $index)
    $flag = if ($result) { $false } else { $true }
    return $flag
}

function Get-StringValue {
    [CmdletBinding()]
    param (
        [string]$Title,
        [string]$Message,
        [string]$Default
    )

    $key = if ([string]::IsNullOrWhiteSpace($default)) { "(default blank)" } else { "(default $default)" }
    $result = ""

    do {
        $r = $host.ui.Prompt($title, $message, $key)
        $hasValue = $r[$key].Length -gt 0

        $result = if ($hasValue) {
            $r[$key]
        }
        else {
            $default
        }

        if ($result.Length -eq 0) {
            Write-Host "Please supply a value" -ForegroundColor Yellow
        }
    } while ($result.Length -eq 0)

    return $result
}

function Show-Message {
    [CmdletBinding()]
    param (
        [string]$Message
    )
    Write-Host -ForegroundColor Green $Message 
}

function Add-UriContent {
    [CmdletBinding()]
    param (
        $Message,
        $Uri,
        $BuildScriptPath,
        [switch]$Enable,
        [hashtable]$Decode
    )
    if ($enable) {

        Show-Message $Message
        $progressPreference = 'silentlyContinue'
        $content = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} ).content
        $progressPreference = 'Continue'
        if ($Decode) {
            $Decode.GetEnumerator() | ForEach-Object {
                $key = $_.Key; $value = $_.Value;
                $content = ($content -replace $key, $value)
            }
        }
        Add-Content -Path $BuildScriptPath -Value $content -Encoding Ascii  | Out-Null
    }
}

function Show-UriContent {
    [CmdletBinding()]
    param (
        $Uri
    )
    $progressPreference = 'silentlyContinue'
    $content = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} ).content
    $progressPreference = 'Continue'
    Write-Host $content
}

function New-Directory {
    [CmdletBinding()]
    param (
        $message,
        $path
    )
    Show-Message $message
    New-Item -Force -ItemType Directory -Path $path | Out-Null
}

function Compress-String {
    [CmdletBinding()]
    param (
        [string]$StringContent
    )

    process {

        $ms = New-Object System.IO.MemoryStream
        $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
        
        $sw = New-Object System.IO.StreamWriter($cs)
        $sw.Write($StringContent)
        $sw.Close();
        
        $bytes = $ms.ToArray()
        return [System.Convert]::ToBase64String($bytes)

    }
}

function Expand-String {
    [CmdletBinding()]
    param (
        [string]$Base64Content
    )

    process {

        $data = [System.Convert]::FromBase64String($StringContent)

        $ms = New-Object System.IO.MemoryStream
        $ms.Write($data, 0, $data.Length)
        $ms.Seek(0,0) | Out-Null
        
        $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
        $sr = New-Object System.IO.StreamReader($cs)
        return $sr.readtoend()
        
    }
}


function New-SourceTree {
    [CmdletBinding()]
    param (
        [string]$srcPath = "src",
        [string]$artifactsPath = "artifacts",
        [string]$toolsPath = "tools",
        [string]$bootstrapscript = "run.ps1",
        [string]$buildScript = "default.ps1",
        [boolean]$addNugetPackageRestore = $true,
        [boolean]$addUnitTests = $true,
        [boolean]$addRebuildDatabase = $false
    )

    # File Uris
    $gitignoreUri = "https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore"

    $rootUri = "https://raw.githubusercontent.com/dotnetzero/script/master"
    $headerUri = "$rootUri/components/header"
    $licenseUri = "$rootUri/LICENSE"
    $usageUri = "$rootUri/components/usage"
    $gitattributesUri = "$rootUri/components/gitattributes.txt"
    $bootstrapUri = "$rootUri/components/run.ps1"
    $scriptPropertiesUri = "$rootUri/components/script-properties/properties.ps1"
    $scriptDefaultUri = "$rootUri/components/script-tasks/Default.ps1"
    $scriptCleanUri = "$rootUri/components/script-tasks/Clean.ps1"
    $scriptInitUri = "$rootUri/components/script-tasks/Init.ps1"
    $scriptRestorePackagesUri = "$rootUri/components/script-tasks/Restore-Packages.ps1"
    $scriptCleanPackagesUri = "$rootUri/components/script-tasks/Clean-Packages.ps1"
    $scriptUnitTestsUri = "$rootUri/components/script-tasks/Unit-Test.ps1"
    $scriptRebuildDatabaseUri = "$rootUri/components/script-tasks/Rebuild-Database.ps1"
    $scriptPlainCompileUri = "$rootUri/components/script-tasks/Plain-Compile.ps1"
    $scriptAssemblyInfoUri = "$rootUri/components/script-tasks/Create-CommonAssemblyInfo.ps1"
    $scriptCreateCommonAssemblyInfoUri = "$rootUri/components/script-functions/CreateCommonAssemblyInfo.ps1"
    $scriptCreateDirectoryUri = "$rootUri/components/script-functions/CreateDirectory.ps1"
    $scriptDeleteDirectoryUri = "$rootUri/components/script-functions/DeleteDirectory.ps1"

    Show-UriContent -Uri $headerUri
    Show-UriContent -Uri $licenseUri

    $companyName = Get-StringValue -Title "Company Info" -Message "Select Name" -Default $companyName
    $productName = Get-StringValue -Title "Product Info" -Message "Select Name" -Default $productName
    $srcPath = Get-StringValue -Title "Source Code" -Message "Select Directory" -Default $srcPath
    $artifactsPath = Get-StringValue -Title "Build Output" -Message "Select Directory" -Default $artifactsPath
    $toolsPath = Get-StringValue -Title "Tools" -Message "Select Directory" -Default $toolsPath
    $buildScript = Get-StringValue -Title "Build Script" -Message "Select Name" -Default $buildScript
    $addNugetPackageRestore = Get-BooleanValue -Title "Package Restore" -Message "Add nuget package restore task" -Default $addNugetPackageRestore
    $addUnitTests = Get-BooleanValue -Title "Build Script" -Message "Add unit tests task" -Default $addUnitTests
    $addRebuildDatabase = Get-BooleanValue -Title "Build Script" -Message "Add rebuild database task" -Default $addRebuildDatabase

    $regex = "[^\x30-\x39\x41-\x5A\x61-\x7A]+"
    $companyNameClean = $companyName -replace $regex, ""
    $productNameClean = $productName -replace $regex, ""

    $headerLine = ("#" * 64);
    Show-Message $headerLine
    Show-Message "Company Name: $companyName"
    Show-Message "Product Name: $productName"

    New-Directory "Source Code Directory: $srcPath" $srcPath
    New-Directory "Build output Directory: $artifactsPath" $artifactsPath
    New-Directory "Tools Directory: $toolsPath" $toolsPath

    #Create gitattributes
    Add-UriContent -Message "Creating .gitattributes files" -uri $gitattributesUri -buildScriptPath ".\.gitattributes" -Enable

    #Create gitignore
    Add-UriContent -Message "Creating .gitignore files" -uri $gitignoreUri -buildScriptPath ".\.gitignore" -Enable
    Add-Content -Path ".\.gitignore" -Value "tools/" -Encoding Ascii  | Out-Null
    Add-Content -Path ".\.gitignore" -Value "$srcPath/.nuget/nuget.exe" -Encoding Ascii | Out-Null

    #Create readme
    Set-Content -Encoding Ascii -Path "readme.md" -Value "`# $companyName"
    Add-Content -Encoding Ascii -Path "readme.md" -Value "`## $productName"

    Add-UriContent -Message "Creating bootstrap file $bootstrapscript" -uri $bootstrapUri -buildScriptPath $bootstrapscript -Enable
    Add-UriContent -Message "Creating properties section in $buildScript" -uri $scriptPropertiesUri -buildScriptPath $buildScript -Enable -Decode @{
        "\`$srcPath"          = $srcPath;
        "\`$companyName"      = $companyName;
        "\`$productName"      = $productName;
        "\`$companyNameClean" = $companyNameClean;
        "\`$productNameClean" = $productNameClean;
        "\`$artifactsPath"    = $artifactsPath;
    }

    Add-Content -Path $buildScript -Value "# Script Tasks" -Encoding Ascii | Out-Null

    Add-UriContent -Message "Adding default task $bootstrapscript to $buildScript" -uri $scriptDefaultUri -buildScriptPath $buildScript -Enable
    Add-UriContent -Message "Adding clean task $bootstrapscript to $buildScript" -uri $scriptCleanUri -buildScriptPath $buildScript -Enable
    Add-UriContent -Message "Adding init $bootstrapscript to $buildScript" -uri $scriptInitUri -buildScriptPath $buildScript -Enable

    # Package Restore
    Add-UriContent -Message "Adding package restore task to $buildScript" -uri $scriptRestorePackagesUri -buildScriptPath $buildScript -Enable:$addNugetPackageRestore
    Add-UriContent -Message "Adding package clean task to $buildScript" -uri $scriptCleanPackagesUri -buildScriptPath $buildScript -Enable:$addNugetPackageRestore

    # Unit Tests
    Add-UriContent -Message "Adding unit test task to $buildScript" -uri $scriptUnitTestsUri -buildScriptPath $buildScript -Enable:$addUnitTests

    # Rebuild Database
    Add-UriContent -Message "Adding database rebuild task to $buildScript" -uri $scriptRebuildDatabaseUri -buildScriptPath $buildScript -Enable:$addRebuildDatabase

    $packageRestoreToken = if ($addNugetPackageRestore) { @{ "\#Restore-Packages\,\#" = "Restore-Packages,"; } 
    }
    else { @{ "\#Restore-Packages\,\#" = ""; } 
    }

    Add-UriContent -Message "Adding compile task to $buildScript" -uri $scriptPlainCompileUri -buildScriptPath $buildScript -Enable -Decode $packageRestoreToken
    Add-UriContent -Message "Adding assmebly info task to $buildScript" -uri $scriptAssemblyInfoUri -buildScriptPath $buildScript -Enable

    Add-Content -Path $buildScript -Value "# Script Functions" -Encoding Ascii | Out-Null
    Add-UriContent -Message "Adding create directory function to $buildScript"  -uri $scriptCreateDirectoryUri -buildScriptPath $buildScript -Enable
    Add-UriContent -Message "Adding delete function to $buildScript"  -uri $scriptDeleteDirectoryUri -buildScriptPath $buildScript -Enable

    Show-Message $headerLine
    Show-UriContent -Uri $usageUri
    Show-Message $headerLine
}
