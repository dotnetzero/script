function New-SourceTree {
    [CmdletBinding()]
    param (
        [string]$companyName,
        [string]$productName,
        [string]$srcPath = "src",
        [string]$artifactsPath = "artifacts",
        [string]$toolsPath = "tools",
        [string]$bootstrapscript = "run.ps1",
        [string]$buildScript = "default.ps1",
        [boolean]$addNugetPackageRestore = $true,
        [boolean]$addUnitTests = $true
    )

    $gitignoreUri = "https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore"

    Expand-String $components_header | Show-Message
    Expand-String $components_license | Show-Message
    "$(Expand-String $components_version) $(Expand-String $components_sha)" | Show-Message

    $companyName = Get-StringValue -Title "Company Info" -Message "Select Name" -Default $companyName
    $productName = Get-StringValue -Title "Product Info" -Message "Select Name" -Default $productName
    $srcPath = Get-StringValue -Title "Source Code" -Message "Select Directory" -Default $srcPath
    $artifactsPath = Get-StringValue -Title "Build Output" -Message "Select Directory" -Default $artifactsPath
    $toolsPath = Get-StringValue -Title "Tools" -Message "Select Directory" -Default $toolsPath
    $buildScript = Get-StringValue -Title "Build Script" -Message "Select Name" -Default $buildScript
    $addNugetPackageRestore = Get-BooleanValue -Title "Package Restore" -Message "Add nuget package restore task" -Default $addNugetPackageRestore
    $launchDotNetTemplate = Get-BooleanValue -Title "Dotnet CLI Templating" -Message "Add .NET projects to the $srcPath directory via the dotnet cli" -Default $true

    $regex = "[^\x30-\x39\x41-\x5A\x61-\x7A]+"
    $companyNameClean = $companyName -replace $regex, ""
    $productNameClean = $productName -replace $regex, ""

    if ($launchDotNetTemplate) {
        $dotNetProjects = Get-DotNetProjects
        $solutionFileName = "$companyNameClean.$productNameClean"
        New-DotnetSolution -DotNetProjects $dotNetProjects -SolutionName $solutionFileName -SourceDirectory $srcPath
    }

    $headerLine = ("-" * 64);
    Show-Message $headerLine
    Show-Message "  Source Tree Setup"
    Show-Message $headerLine
    Show-Message "Company Name: $companyName"
    Show-Message "Product Name: $productName"

    New-Directory "Source Code Directory: $srcPath" $srcPath
    New-Directory "Build output Directory: $artifactsPath" $artifactsPath
    New-Directory "Tools Directory: $toolsPath" $toolsPath

    #Create gitattributes
    Add-Base64Content -Message "Creating .gitattributes files" -base64Content $components_gitattributes -buildScriptPath ".\.gitattributes" -Enable

    #Create gitignore
    Add-UriContent -Message "Creating .gitignore files" -uri $gitignoreUri -buildScriptPath ".\.gitignore" -Enable
    Add-Content -Path ".\.gitignore" -Value "tools/" -Encoding Ascii  | Out-Null
    Add-Content -Path ".\.gitignore" -Value "$srcPath/.nuget/nuget.exe" -Encoding Ascii | Out-Null

    #Create readme
    Set-Content -Encoding Ascii -Path "readme.md" -Value "`# $companyName"
    Add-Content -Encoding Ascii -Path "readme.md" -Value "`## $productName"

    Add-Base64Content -Message "Creating bootstrap file $bootstrapscript" -base64Content $components_run -buildScriptPath $bootstrapscript -Enable
    Add-Base64Content -Message "Creating properties section in $buildScript" -base64Content $scriptproperties_properties -buildScriptPath $buildScript -Enable -Decode @{
        "\`$srcPath"          = $srcPath;
        "\`$companyName"      = $companyName;
        "\`$productName"      = $productName;
        "\`$companyNameClean" = $companyNameClean;
        "\`$productNameClean" = $productNameClean;
        "\`$artifactsPath"    = $artifactsPath;
    }

    Add-Content -Path $buildScript -Value "# Script Tasks" -Encoding Ascii | Out-Null

    Add-Base64Content -Message "Adding default task to $buildScript" -base64Content $scripttasks_Default -buildScriptPath $buildScript -Enable
    Add-Base64Content -Message "Adding clean task to $buildScript" -base64Content $scripttasks_Clean -buildScriptPath $buildScript -Enable
    Add-Base64Content -Message "Adding init task to $buildScript" -base64Content $scripttasks_Init -buildScriptPath $buildScript -Enable

    # Package Restore
    Add-Base64Content -Message "Adding package restore task to $buildScript" -base64Content $scripttasks_RestorePackages -buildScriptPath $buildScript -Enable:$addNugetPackageRestore
    Add-Base64Content -Message "Adding package clean task to $buildScript" -base64Content $scripttasks_CleanPackages -buildScriptPath $buildScript -Enable:$addNugetPackageRestore

    # Unit Tests
    Add-Base64Content -Message "Adding unit test task to $buildScript" -base64Content $scripttasks_UnitTest -buildScriptPath $buildScript -Enable

    # Rebuild Database
    Add-Base64Content -Message "Adding database rebuild task to $buildScript" -base64Content $scriptRebuildDatabaseUri -buildScriptPath $buildScript -Enable:$addRebuildDatabase

    $packageRestoreToken = if ($addNugetPackageRestore) { @{ "\#Restore-Packages\,\#" = "Restore-Packages,"; } 
    }
    else { @{ "\#Restore-Packages\,\#" = ""; } 
    }

    Add-Base64Content -Message "Adding compile task to $buildScript" -base64Content $scripttasks_PlainCompile -buildScriptPath $buildScript -Enable -Decode $packageRestoreToken
    Add-Base64Content -Message "Adding assmebly info task to $buildScript" -base64Content $scriptAssemblyInfoUri -buildScriptPath $buildScript -Enable

    Add-Content -Path $buildScript -Value "# Script Functions" -Encoding Ascii | Out-Null
    Add-Base64Content -Message "Adding create directory function to $buildScript" -base64Content $scriptfunctions_CreateDirectory -buildScriptPath $buildScript -Enable
    Add-Base64Content -Message "Adding delete function to $buildScript" -base64Content $scriptfunctions_DeleteDirectory -buildScriptPath $buildScript -Enable

    Show-Message $headerLine
    Expand-String $components_usage | Show-Message
    Show-Message $headerLine
}
