param(
    [switch]$UseDefaults,
    $companyName = "",
    $productName = "",
    $srcPath = "src",
    $toolsPath = "tools",
    $artifactsPath = "artifacts",
    $buildScript = "default.ps1",
    $addCITask = $true,
    $enableNugetPackageRestore = $true,
    $enableTeamCityTaskNameLogging = $true
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
    $enableNugetPackageRestore = Get-BooleanValue -title "Package Restore" -message "Add nuget package restore task" -default $enableNugetPackageRestore
    $addCITask = Get-BooleanValue -title "Continous Integration" -message "Add continous integration task" -default $addCITask
    $enableTeamCityTaskNameLogging = Get-BooleanValue -title "Continous Integration" -message "Add TeamCity task messages" -default $enableTeamCityTaskNameLogging
}

Write-Host -ForegroundColor Green "###################################################"
Write-Host -ForegroundColor Green "source code directory: $srcPath"
Write-Host -ForegroundColor Green "build output directory: $artifactsPath"
Write-Host -ForegroundColor Green "tools directory: $toolsPath"
Write-Host -ForegroundColor Green "build script default: $buildScript"
Write-Host -ForegroundColor Green "Add nuget package restore task: $enableNugetPackageRestore"
Write-Host -ForegroundColor Green "Add CI task: $addCITask"
Write-Host -ForegroundColor Green "Add TC message functions: $enableTeamCityTaskNameLogging"
Write-Host -ForegroundColor Green "###################################################"

@($srcPath, $artifactsPath), $toolsPath | % {
    New-Item -Force -ItemType Directory -Path $_ | Out-Null
}

$scriptProperties = @"
# Script properties
Framework "4.5.2"
properties {
    `$baseDirectory = Resolve-Path .\
    `$sourceDirectory = "`$baseDirectory\$srcPath"

    `$company = "\$companyName"
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

$scriptTasks = @"
# Script Tasks
task Default -depends Clean, Init, Compile, Test

task Clean-Packages {
    Remove-Item -Force -Recurse `$packagesDirectory;
    CreateDirectory `$packagesDirectory;
}

task Clean {
    NukeDirectory `$outputDirectory\**

    @("bin","obj") | ForEach-Object {
        NukeDirectory "`$sourceDirectory\**\`$_\"
    }
}

task Init {
    Assert ("Debug", "Release" -contains `$buildConfiguration) `
        "Invalid build configuration '`$buildConfiguration'. Valid values are 'Debug' or 'Release'"

    Assert(Test-Path `$nugetExe) "Nuget command line tool is missing at `$nugetExe"

    Write-Host "Creating build output directory at `$outputDirectory"
    CreateDirectory `$outputDirectory
}

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

task Restore-Packages {
    Exec { & `$nugetExe "restore" `$solutionFile }
}

"@

$scriptFunctions = @"
# Script Functions
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

New-Item -ItemType File -Path $buildScript -Value $scriptProperties -Force | Out-Null
Add-Content -Path $buildScript -Value $scriptTasks -Encoding Ascii | Out-Null
Add-Content -Path $buildScript -Value $scriptFunctions -Encoding Ascii | Out-Null

if($enableTeamCityTaskNameLogging){
    Add-Content -Path $buildScript -Value $taskSetupAndTearDownFunctions -Encoding Ascii -NoNewline | Out-Null
}
