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
    [switch]$addRebuildDatabase,
    [string]$branch = "feature/download-tasks"
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

function Write([string]$message){
    Write-Host -ForegroundColor Green $message
}

function AppendContent($Uri, $BuildScriptPath, [switch]$Enable, [hashtable]$Decode){
    if($enable){
        Write-Host " - Downloading $Uri as $BuildScriptPath" -ForegroundColor Blue
        $content = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{"Cache-Control"="no-cache"} ).content
        if($Decode){
            $Decode.GetEnumerator() |% {
                $key = $_.Key;$value = $_.Value;
                Write-Host "  - Replacing $key with $value" -ForegroundColor Blue
                $content = ($content -replace $key, $value)
            }
        }
        Add-Content -Path $BuildScriptPath -Value $content -Encoding Ascii  | Out-Null
    }
}

# Allow user to select their settings
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

Write "###################################################"
Write "Source Code Directory: $srcPath"
Write "Build output Directory: $artifactsPath"
Write "Tools Directory: $toolsPath"
Write "Build Script Default: $buildScript"
Write "Add Nuget Package Restore Task: $addNugetPackageRestore"
Write "Add CI task: $addCITask"
Write "Add TC message functions: $addTeamCityTaskNameLogging"
Write "Add Octopack compile switches: $addOctopack"
Write "Add default psake task: $addDefaultTask"
Write "Add unit test task: $addUnitTests"
Write "Add rebuild database task: $addUnitTests"

@($srcPath, $artifactsPath), $toolsPath | % {
    New-Item -Force -ItemType Directory -Path $_ | Out-Null
}

# File Uris
$rootUri = "https://raw.githubusercontent.com/motowilliams/psake-surgeon/$branch"
$gitattributesUri = "$rootUri/components/gitattributes.txt"
$gitignoreUri = "https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore"
$bootstrapUri = "$rootUri/components/run.ps1"
$scriptPropertiesUri = "$rootUri/components/script-properties/properties.ps1"
$scriptDefaultUri = "$rootUri/components/script-tasks/Default.ps1"
$scriptCleanUri = "$rootUri/components/script-tasks/Clean.ps1"
$scriptInitUri = "$rootUri/components/script-tasks/Init.ps1"
$scriptRestorePackagesUri = "$rootUri/components/script-tasks/Restore-Packages.ps1"
$scriptCleanPackagesUri = "$rootUri/components/script-tasks/Clean-Packages.ps1"
$scriptTaskSetupUri = "$rootUri/components/script-tasks/TaskSetup.ps1"
$scriptTaskTearDownUri = "$rootUri/components/script-tasks/TaskTearDown.ps1"

$scriptUnitTestsUri = "$rootUri/components/script-tasks/UnitTests.ps1"
$scriptRebuildDatabaseUri = "$rootUri/components/script-tasks/Rebuild-Database.ps1"

$scriptPlainCompileUri = "$rootUri/components/script-tasks/Plain-Compile.ps1"
$scriptOctopusCompileUri = "$rootUri/components/script-tasks/Octopus-Compile.ps1"

$scriptCreateCommonAssemblyInfoUri = "$rootUri/components/script-functions/CreateCommonAssemblyInfo.ps1"
$scriptCreateDirectoryUri = "$rootUri/components/script-functions/CreateDirectory.ps1"
$scriptDeleteDirectoryUri = "$rootUri/components/script-functions/DeleteDirectory.ps1"

#Create gitattributes
AppendContent -uri $gitattributesUri -buildScriptPath ".\.gitattributes" -Enable

#Create gitignore
AppendContent -uri $gitignoreUri -buildScriptPath ".\.gitignore" -Enable

#Create readme
@"
# $companyName
## $productName
"@ | Out-File -Encoding ascii -FilePath "readme.md"

AppendContent -uri $bootstrapUri -buildScriptPath $bootstrapscript -Enable
AppendContent -uri $scriptPropertiesUri -buildScriptPath $buildScript -Enable -Decode @{ "\`$srcPath"= $srcPath;"\`$companyName"= $companyName;"\`$productName"= $productName; "\`$artifactsPath" = $artifactsPath}

Add-Content -Path $buildScript -Value "# Script Tasks" -Encoding Ascii | Out-Null

AppendContent -uri $scriptDefaultUri -buildScriptPath $buildScript -Enable
AppendContent -uri $scriptCleanUri -buildScriptPath $buildScript -Enable
AppendContent -uri $scriptInitUri -buildScriptPath $buildScript -Enable

# Package Restore
AppendContent -uri $scriptRestorePackagesUri -buildScriptPath $buildScript -Enable:$addNugetPackageRestore
AppendContent -uri $scriptCleanPackagesUri -buildScriptPath $buildScript -Enable:$addNugetPackageRestore

# TeamCity
AppendContent -uri $scriptTaskSetupUri -buildScriptPath $buildScript -Enable:$addTeamCityTaskNameLogging
AppendContent -uri $scriptTaskTearDownUri -buildScriptPath $buildScript -Enable:$addTeamCityTaskNameLogging

# Unit Tests
AppendContent -uri $scriptUnitTestsUri -buildScriptPath $buildScript -Enable:$addUnitTests

# Rebuild Database
AppendContent -uri $scriptRebuildDatabaseUri -buildScriptPath $buildScript -Enable:$addRebuildDatabase

$packageRestoreToken = if($addNugetPackageRestore) { @{ "\#Restore-Packages\,\#"= "Restore-Packages,"; } } else { @{ "\#Restore-Packages\,\#"= ""; } }

if($addOctopack){
    AppendContent -uri $scriptOctopusCompileUri -buildScriptPath $buildScript -Enable -Decode $packageRestoreToken
} else {
    AppendContent -uri $scriptPlainCompileUri -buildScriptPath $buildScript -Enable -Decode $packageRestoreToken
}

Add-Content -Path $buildScript -Value "# Script Functions" -Encoding Ascii | Out-Null

AppendContent -uri $scriptCreateCommonAssemblyInfoUri -buildScriptPath $buildScript -Enable
AppendContent -uri $scriptCreateDirectoryUri -buildScriptPath $buildScript -Enable
AppendContent -uri $scriptDeleteDirectoryUri -buildScriptPath $buildScript -Enable

Write "###################################################"