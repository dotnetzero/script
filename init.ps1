param(
    [switch]$UseDefaults,
    $bootstrapscript = "run.ps1" ,
    $companyName = "" ,
    $productName = "" ,
    $srcPath = "src" ,
    $toolsPath = "tools" ,
    $artifactsPath = "artifacts" ,
    $buildScript = "default.ps1" ,
    [switch]$addDefaultTask ,
    [switch]$addCITask ,
    [switch]$addNugetPackageRestore ,
    [switch]$addTeamCityTaskNameLogging ,
    [switch]$addOctopack ,
    [switch]$addUnitTests,
    [switch]$addRebuildDatabase
)

function Get-StringValue([string]$title, [string]$message, [string]$default) {
    $prompt = if([string]::IsNullOrWhiteSpace($default)){ "(default blank)" } else { "(default $default)" }
    $r = $host.ui.Prompt($title,$message,$prompt)
    $result =  if($r.Values[0].Equals("")){$r.Values[0]}else{$default}
    return $result
}

function Get-BooleanValue([string]$title, [string]$message, [boolean]$default) {
    $index = if($default) { 0 } else { 1 }
    $enabled = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Enable $title"
    $disabled = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Disable $title"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($enabled, $disabled)
    $result = $Host.UI.PromptForChoice($title, $message, $options, $index)
    $flag = if($result) { $false } else { $true }
    return $flag
}

if($UseDefaults -eq $false){
    $companyName = Get-StringValue -title "Company Info" -message "Select Name" -default $companyName
    $productName = Get-StringValue -title "Product Info" -message "Select Name" -default $productName
    $srcPath = Get-StringValue -title "Source Code" -message "Select Directory" -default $srcPath
    $artifactsPath = Get-StringValue -title "Build Output" -message "Select Directory" -default $artifactsPath
    $toolsPath = Get-StringValue -title "Tools" -message "Select Directory" -default $toolsPath
    $buildScript = Get-StringValue -title "Build Script" -message "Select Name" -default $buildScript
    $addCITask = Get-BooleanValue -title "Continous Integration" -message "Add continous integration task" -default $addCITask
    $addNugetPackageRestore = Get-BooleanValue -title "Package Restore" -message "Add nuget package restore task" -default $addNugetPackageRestore
    $addTeamCityTaskNameLogging = Get-BooleanValue -title "Continous Integration" -message "Add TeamCity task messages" -default $addTeamCityTaskNameLogging
    $addOctopack = Get-BooleanValue -title "Continous Integration" -message "Add Octopack msbuild parameters" -default $addOctopack
    $addDefaultTask = Get-BooleanValue -title "Build Script" -message "Add default psake task" -default $addDefaultTask
    $addUnitTests = Get-BooleanValue -title "Build Script" -message "Add unit tests task" -default $addUnitTests
    $addRebuildDatabase = Get-BooleanValue -title "Build Script" -message "Add rebuild database task" -default $addRebuildDatabase
}

Write-Host -ForegroundColor Green "###################################################"
Write-Host -ForegroundColor Green "Source Code Directory: $srcPath"
Write-Host -ForegroundColor Green "Build output Directory: $artifactsPath"
Write-Host -ForegroundColor Green "Tools Directory: $toolsPath"
Write-Host -ForegroundColor Green "Build Script Default: $buildScript"
Write-Host -ForegroundColor Green "Add Nuget Package Restore Task: $addNugetPackageRestore"
Write-Host -ForegroundColor Green "Add CI task: $addCITask"
Write-Host -ForegroundColor Green "Add TC message functions: $addTeamCityTaskNameLogging"
Write-Host -ForegroundColor Green "Add Octopack compile switches: $addOctopack"
Write-Host -ForegroundColor Green "Add default psake task: $addDefaultTask"
Write-Host -ForegroundColor Green "Add unit test task: $addUnitTests"
Write-Host -ForegroundColor Green "Add rebuild database task: $addUnitTests"

@($srcPath, $artifactsPath), $toolsPath | % {
    New-Item -Force -ItemType Directory -Path $_ | Out-Null
}

$bootstrapscriptContent = @"
param(
    `$taskList=@('Default'),
    `$version="1.0.0",
    [switch]`$runOctoPack
)

`$nugetPath = ".\src\.nuget\"
if((Test-Path -Path "`$nugetPath\nuget.exe") -eq `$false){
    Write-Host "Downloading nuget to `$nugetPath"
    New-Item -ItemType Directory -Path `$nugetPath -Force | Out-Null
    Invoke-WebRequest -Uri "https://www.nuget.org/nuget.exe" -OutFile "`$nugetPath\nuget.exe" | Out-Null
}

`$psakePath = ".\tools\psake\4.6.0\psake.psm1"
if((Test-Path -Path `$psakePath) -eq `$false){
    Write-Host "Psake module missing"
    Write-Host "Updating package provider"
    Install-PackageProvider NuGet -Force
    Write-Host "Seaching for psake package and saving local copy"
    `$module = Find-Module -Name psake
    Write-Host "Psake module found. Saving local copy"
    `$module | Save-Module -Path .\tools\ -Force
}

`# '[p]sake' is the same as 'psake' but  is not polluted
Remove-Module [p]sake
Import-Module `$psakePath

# call default.ps1 with properties
Invoke-Psake -buildFile ".\default.ps1" -taskList `$taskList -properties @{ "version" = `$version; "runOctoPack" = `$runOctoPack; }

if(`$psake.build_success) { exit 0 } else { exit 1 }
"@

New-Item -ItemType File -Path $bootstrapscript -Value $bootstrapscriptContent -Force | Out-Null

$scriptProperties = @"
# Script Properties
Framework "4.5.2"
properties {
    `$baseDirectory = Resolve-Path .\
    `$sourceDirectory = "`$baseDirectory\$srcPath"

    `$company = "$companyName"
    `$product = "$productName"

    `$outputDirectory = "`$baseDirectory\$artifactsPath"
    `$packagesDirectory = "`$sourceDirectory\packages"
    `$packagesOutputDirectory = "`$outputDirectory\packages"
    `$environment = "Local"

    # msbuild settings
    `$solution = "Default.sln"
    `$solutionFile = "`$sourceDirectory\`$solution"
    `$verbosity = "normal"
    `$buildConfiguration = "Release"
    `$buildPlatform = "Any CPU"
    `$version = "1.0.0"
    `$runOctoPack = "false"

    # tools
    `$nugetExe = "`$sourceDirectory\.nuget\nuget.exe"
    `$migrator = "`$sourceDirectory\packages\roundhouse.0.8.6\bin\rh.exe"
    `$sqlPackageExe = "`$baseDirectory\$toolsPath\SqlPackage.13.0.3450\sqlPackage.exe"

    # database
    `$databaseServer = "localhost\sqlexpress2014"
    `$integratedSecurity = "Integrated Security=True"
}
"@

$tasksDefaults = @"
task Default -depends Clean, Init, Compile, Test
"@

$tasksUnitTest = @"
task UnitTests -depends Compile {

}
"@

$tasksRebuildDatabase = @"
task Rebuild-Database -depends Compile {

}
"@

$tasksSetup = @"
task Clean {
    NukeDirectory `$outputDirectory\**

    @("bin","obj") | ForEach-Object {
        NukeDirectory "`$sourceDirectory\**\`$_\"
    }
}
task Init {
    Assert(Test-Path `$nugetExe) -failureMessage "Nuget command line tool is missing at `$nugetExe"

    Write-Host "Creating build output directory at `$outputDirectory"
    CreateDirectory `$outputDirectory
}
"@

$taskPlainCompile = @"
task Compile -depends Init, Restore-Packages, Create-AssemblyInfo {
    Exec {
        msbuild `$solutionFile ``
            /verbosity:`$verbosity ``
            /p:Configuration=`$buildConfiguration ``
            /p:Platform=`$buildPlatform
    }
}
"@

$taskOctoCompile = @"
task Compile -depends Init, Restore-Packages, Create-AssemblyInfo {
    Exec {
        msbuild `$solutionFile ``
            /verbosity:`$verbosity ``
            /p:Configuration=`$buildConfiguration ``
            /p:Platform=`$buildPlatform ``
            /p:OctoPackPackageVersion=`$version ``
            /p:RunOctoPack=`$runOctoPack ``
            /p:OctoPackEnforceAddingFiles=true ``
            /p:OctoPackPublishPackageToFileShare="`$packagesOutputDirectory"
    }
}
"@

$taskRestorePackages = @"
task Restore-Packages {
    Exec { & `$nugetExe "restore" `$solutionFile }
}
task Clean-Packages {
    Remove-Item -Force -Recurse `$packagesDirectory;
    CreateDirectory `$packagesDirectory;
}
"@

$taskSetupAndTearDownFunctions = @"
TaskSetup{
    if(`$env:TEAMCITY_VERSION){
        Write-Output "##teamcity[blockOpened name='$taskName']"
    }
}
TaskTearDown{
    if(`$env:TEAMCITY_VERSION){
        Write-Output "##teamcity[blockClosed name='$taskName']"
    }
}
"@

$scriptFunctions = @"
function CreateDirectory(`$directory) {
    Write-Host "Creating `$directory"
    New-Item `$directory -ItemType Directory -Force | Out-Null
}
function NukeDirectory(`$directory) {
    if(Test-Path `$directory){
        Write-Host "Removing `$directory"
        Remove-Item `$directory -Force -Recurse | Out-Null
    } else {
        Write-Host "`$directory does not exist"
    }
}
"@

$functionAssemblyInfo = @"
function CreateCommonAssemblyInfo(`$version,`$buildConfiguration,`$filename) {
`$year = (Get-Date).Year
"using System;
using System.Reflection;
using System.Runtime.InteropServices;
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:2.0.50727.4927
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------
[assembly: ComVisibleAttribute(false)]
[assembly: AssemblyVersionAttribute(""`$version"")]
[assembly: AssemblyFileVersionAttribute(""`$version"")]
[assembly: AssemblyCopyrightAttribute(""Copyright `$year"")]
[assembly: AssemblyProductAttribute(""`$product"")]
[assembly: AssemblyCompanyAttribute(""`$company"")]
[assembly: AssemblyConfigurationAttribute(""`$buildConfiguration"")]
[assembly: AssemblyInformationalVersionAttribute(""`$version"")]" | out-file $filename -encoding "ASCII"
}
"@

function AppendBuildScript($content, $enable){
    if($enable){
        Add-Content -Path $buildScript -Value $content -Encoding Ascii | Out-Null
    }
}

New-Item -ItemType File -Path $buildScript -Value $scriptProperties -Force | Out-Null

AppendBuildScript "`r`n# Script Tasks" $true
AppendBuildScript $tasksDefaults $true
AppendBuildScript $tasksSetup $true
AppendBuildScript $taskRestorePackages $addNugetPackageRestore
AppendBuildScript $tasksUnitTest $addUnitTests
AppendBuildScript $tasksRebuildDatabase $addRebuildDatabase

if($addOctopack){
    Add-Content -Path $buildScript -Value $taskOctoCompile -Encoding Ascii | Out-Null
} else {
    Add-Content -Path $buildScript -Value $taskPlainCompile -Encoding Ascii | Out-Null
}

AppendBuildScript $taskSetupAndTearDownFunctions $addTeamCityTaskNameLogging

AppendBuildScript "`r`n# Script Functions" $true
AppendBuildScript $scriptFunctions $true
AppendBuildScript $functionAssemblyInfo $true

Write-Host -ForegroundColor Green "Fetching .gitignore file from GitHub"
(Invoke-WebRequest https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore -UseBasicParsing).Content | Out-File -Encoding ascii -FilePath .\.gitignore -Force

Write-Host -ForegroundColor Green "Creating simple .gitattributes file"
@"
# Auto detect text files and perform LF normalization
# http://davidlaing.com/2012/09/19/customise-your-gitattributes-to-become-a-git-ninja/
* text=auto

# Custom for Visual Studio
*.sln text eol=crlf
*.csproj text eol=crlf
*.vbproj text eol=crlf
*.fsproj text eol=crlf
*.dbproj text eol=crlf

*.vcxproj text eol=crlf
*.vcxitems text eol=crlf
*.props text eol=crlf
*.filters text eol=crlf
"@ | Out-File -Encoding ascii -FilePath ".gitattributes"

@"
# $companyName
## $productName
"@ | Out-File -Encoding ascii -FilePath "readme.md"

Write-Host -ForegroundColor Green "###################################################"