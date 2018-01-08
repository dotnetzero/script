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
    $launchDotNetTemplate = Get-BooleanValue -Title "Dotnet CLI Templating" -Message "Add .NET projects to the $srcPath directory via the dotnet cli" -Default $true

    if ($launchDotNetTemplate) {
        $dotNetProjects = Get-DotNetProjects
        $solutionFileName = "$($companyName | New-SafeName).$($productName | New-SafeName)"
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

    New-PsakeSetup -CompanyName $companyName -ProductName $productName `
        -SrcPath $srcPath `
        -ArtifactsPath $artifactsPath `
        -Bootstrapscript $bootstrapscript `
        -BuildScript $buildScript `
        -AddNugetPackageRestore $addNugetPackageRestore

    Show-Message $headerLine
    Expand-String $components_usage | Show-Message
    Show-Message $headerLine
}
