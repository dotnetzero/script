param(
    $bootstrapscript = "run.ps1" ,
    $companyName = "" ,
    $productName = "" ,
    $srcPath = "src" ,
    $toolsPath = "tools" ,
    $artifactsPath = "artifacts" ,
    $buildScript = "default.ps1" ,
    [boolean]$addDefaultTask = $true,
    [boolean]$addCITask = $true,
    [boolean]$addNugetPackageRestore = $true,
    [boolean]$addTeamCityTaskNameLogging = $true,
    [boolean]$addOctopack = $true,
    [boolean]$addUnitTests = $true,
    [boolean]$addRebuildDatabase = $true,
    [string]$branch = "master",
	[boolean]$importTemplateRepo = $true,
	[string]$repoName = "ClearMeasureBootcamp",
	[string]$repoAccoutName = "ClearMeasureLabs",
	[string]$repoBranch = "master"
)

function Get-StringValue([string]$title, [string]$message, [string]$default) {
    $key = if([string]::IsNullOrWhiteSpace($default)){ "(default blank)" } else { "(default $default)" }
    $result = ""

    do {
        $r = $host.ui.Prompt($title,$message,$key)
        $hasValue = $r[$key].Length -gt 0
        Write-Host "HasValue $hasValue"

        $result = if($hasValue){
            $r[$key]
        }else{
            $default
        }

        if($result.Length -eq 0) {
            Write-Host "Please supply a value" -ForegroundColor Yellow
        }
    } while ($result.Length -eq 0)

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

function AppendContent($Message, $Uri, $BuildScriptPath, [switch]$Enable, [hashtable]$Decode){
    if($enable){
        Write $Message
        $progressPreference = 'silentlyContinue'
		$requestResult = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{"Cache-Control"="no-cache"} )
		
		if($requestResult.content.GetType().Name -eq "String")
        {
			$content = $requestResult.content
		}
		else
		{
			$content = $requestResult
		}
		
        $progressPreference = 'Continue'
        if($Decode){
            $Decode.GetEnumerator() |% {
                $key = $_.Key;$value = $_.Value;
                $content = ($content -replace $key, $value)
            }
        }
        Add-Content -Path $BuildScriptPath -Value $content -Encoding Ascii  | Out-Null
    }
}

function WriteUriContent($Uri){
    $progressPreference = 'silentlyContinue'
    $content = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Headers @{"Cache-Control"="no-cache"} ).content
    $progressPreference = 'Continue'
    Write-Host $content
}

function CreateDirectory($message, $path){
    Write $message
    New-Item -Force -ItemType Directory -Path $path | Out-Null
}

function Copy-GithubRepository
{
	param(
	[Parameter(Mandatory=$True)]
	[string] $Name,
	
	[Parameter(Mandatory=$True)]
	[string] $Author,
	
	[Parameter(Mandatory=$False)]
	[string] $Branch = "master",
	
	[Parameter(Mandatory=$False)]
	[string] $GithubTokenVariableAssetName = "GithubToken",
	
	[Parameter(Mandatory=$True)]
	[string] $sourceDirectory = "src"
	
	)
	
	$importRepoDirectory =  "$PWD\importedRepo"
	CreateDirectory "Import Code Template Directory: $importRepoDirectory"  "$importRepoDirectory"
	
	$ZipFile = "$importRepoDirectory\$Name.zip"
	$OutputFolder = "$importRepoDirectory\$Name"
	$projectSourceDirectory = "$PWD\$sourceDirectory"
   
	$RepositoryZipUrl = "https://api.github.com/repos/$Author/$Name/zipball/$Branch"

	# download the zip
	Invoke-RestMethod -Uri $RepositoryZipUrl -OutFile $ZipFile
	
	# extract the zip
	New-Item -Path $OutputFolder -ItemType Directory | Out-Null
		
	[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
	[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutputFolder)

	# remove zip
	Remove-Item -Path $ZipFile -Force
	
	#output the path to the downloaded repository
	(ls $OutputFolder)[0].FullName
	
	#Only copy the src from the GitHub Template, This is a convention for now, expect the Run.ps1 to handle the rest
	$src = Get-ChildItem $OutputFolder -recurse | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -match $sourceDirectory}
	
	if($src -eq $null)
	{
		Write "$OutputFolder does not have a $sourceDirectory directory.  You will have to manually moved files into $projectSourceDirectory"
	}
	else
	{
		Copy-Item "$($src.FullName)\*" $projectSourceDirectory -recurse
		
		$solutionFile = Get-ChildItem $projectSourceDirectory | Where-Object {$_.Name -like "*.sln"}
		if($solutionFile -eq $null)
		{
			Write "$projectSourceDirectory does not have a Visual Studio Solution File.  You will need to create a Default.sln for the Run to build."
		}
		else{
			if($solutionFile.Name -ne "default.sln")
			{
				$fileOriginalName =$solutionFile.FullName;
				Write "Renaming $fileOriginalName to default.sln to match Run execution convention"
				Rename-Item -Path $solutionFile.FullName -NewName "default.sln"
			}
		}
		Remove-Item -Path $importRepoDirectory -Force -recurse
	}
}

# File Uris
$rootUri = "https://raw.githubusercontent.com/psakezero/script/$branch"
$headerUri = "$rootUri/components/header"
$licenseUri = "$rootUri/LICENSE"
$usageUri = "$rootUri/components/usage"
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

$scriptUnitTestsUri = "$rootUri/components/script-tasks/Unit-Test.ps1"
$scriptRebuildDatabaseUri = "$rootUri/components/script-tasks/Rebuild-Database.ps1"

$scriptPlainCompileUri = "$rootUri/components/script-tasks/Plain-Compile.ps1"
$scriptOctopusCompileUri = "$rootUri/components/script-tasks/Octopus-Compile.ps1"
$scriptAssemblyInfoUri = "$rootUri/components/script-tasks/Create-CommonAssemblyInfo.ps1"

$scriptCreateCommonAssemblyInfoUri = "$rootUri/components/script-functions/CreateCommonAssemblyInfo.ps1"
$scriptCreateDirectoryUri = "$rootUri/components/script-functions/CreateDirectory.ps1"
$scriptDeleteDirectoryUri = "$rootUri/components/script-functions/DeleteDirectory.ps1"

WriteUriContent -Uri $headerUri
WriteUriContent -Uri $licenseUri

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
$addUnitTests = Get-BooleanValue -title "Build Script" -message "Add unit tests task" -default $addUnitTests
$addRebuildDatabase = Get-BooleanValue -title "Build Script" -message "Add rebuild database task" -default $addRebuildDatabase

#Check for Import GitHub Repo
$importTemplateRepo = Get-BooleanValue -title "Import GitHub" -message "Import GitHub Repo As Template" -default $importTemplateRepo
if($importTemplateRepo)
{
	$repoAccoutName = Get-StringValue -title "GibHub Organization" -message "Enter GitHub Organization" -default $repoAccoutName
	$repoName = Get-StringValue -title "GibHub Repo" -message "Enter Repo Name" -default $repoName
	$repoBranch = Get-StringValue -title "GibHub Branch" -message "Enter Repo Branch" -default $repoBranch
}


$headerLine = "#######################################################";
Write $headerLine
Write "Company Name: $companyName"
Write "Product Name: $productName"

CreateDirectory "Source Code Directory: $srcPath" $srcPath
CreateDirectory "Build output Directory: $artifactsPath" $artifactsPath
CreateDirectory "Tools Directory: $toolsPath" $toolsPath

#Create gitattributes
AppendContent -message "Creating .gitattributes files" -uri $gitattributesUri -buildScriptPath ".\.gitattributes" -Enable

#Create gitignore
AppendContent -message "Creating .gitignore files" -uri $gitignoreUri -buildScriptPath ".\.gitignore" -Enable
Add-Content -Path ".\.gitignore" -Value "tools/" -Encoding Ascii  | Out-Null
Add-Content -Path ".\.gitignore" -Value "$srcPath/.nuget/nuget.exe" -Encoding Ascii | Out-Null

#Create readme
@"
# $companyName
## $productName
"@ | Out-File -Encoding ascii -FilePath "readme.md"

AppendContent -Message "Creating bootstrap file $bootstrapscript" -uri $bootstrapUri -buildScriptPath $bootstrapscript -Enable
AppendContent -Message "Creating properties section to $buildScript" -uri $scriptPropertiesUri -buildScriptPath $buildScript -Enable -Decode @{ "\`$srcPath"= $srcPath;"\`$companyName"= $companyName;"\`$productName"= $productName; "\`$artifactsPath" = $artifactsPath}

Add-Content -Path $buildScript -Value "# Script Tasks" -Encoding Ascii | Out-Null

AppendContent -Message "Adding default task $bootstrapscript to $buildScript" -uri $scriptDefaultUri -buildScriptPath $buildScript -Enable
AppendContent -Message "Adding clean task $bootstrapscript to $buildScript" -uri $scriptCleanUri -buildScriptPath $buildScript -Enable
AppendContent -Message "Adding init $bootstrapscript to $buildScript" -uri $scriptInitUri -buildScriptPath $buildScript -Enable

# Package Restore
AppendContent -Message "Adding package restore task to $buildScript" -uri $scriptRestorePackagesUri -buildScriptPath $buildScript -Enable:$addNugetPackageRestore
AppendContent -Message "Adding package clean task to $buildScript" -uri $scriptCleanPackagesUri -buildScriptPath $buildScript -Enable:$addNugetPackageRestore

# TeamCity
AppendContent -Message "Adding setup task to $buildScript" -uri $scriptTaskSetupUri -buildScriptPath $buildScript -Enable:$addTeamCityTaskNameLogging
AppendContent -Message "Adding tear down task to $buildScript" -uri $scriptTaskTearDownUri -buildScriptPath $buildScript -Enable:$addTeamCityTaskNameLogging

# Unit Tests
AppendContent -Message "Adding unit test task to $buildScript" -uri $scriptUnitTestsUri -buildScriptPath $buildScript -Enable:$addUnitTests

# Rebuild Database
AppendContent -Message "Adding database rebuild task to $buildScript" -uri $scriptRebuildDatabaseUri -buildScriptPath $buildScript -Enable:$addRebuildDatabase

$packageRestoreToken = if($addNugetPackageRestore) { @{ "\#Restore-Packages\,\#"= "Restore-Packages,"; } } else { @{ "\#Restore-Packages\,\#"= ""; } }

if($addOctopack){
    AppendContent -Message "Adding compile with octopus flags task to $buildScript" -uri $scriptOctopusCompileUri -buildScriptPath $buildScript -Enable -Decode $packageRestoreToken
} else {
    AppendContent -Message "Adding compile task to $buildScript" -uri $scriptPlainCompileUri -buildScriptPath $buildScript -Enable -Decode $packageRestoreToken
}

AppendContent -Message "Adding assmebly info task to $buildScript" -uri $scriptAssemblyInfoUri -buildScriptPath $buildScript -Enable

Add-Content -Path $buildScript -Value "# Script Functions" -Encoding Ascii | Out-Null

AppendContent -Message "Adding assembly info function to $buildScript"  -uri $scriptCreateCommonAssemblyInfoUri -buildScriptPath $buildScript -Enable
AppendContent -Message "Adding create directory function to $buildScript"  -uri $scriptCreateDirectoryUri -buildScriptPath $buildScript -Enable
AppendContent -Message "Adding delete function to $buildScript"  -uri $scriptDeleteDirectoryUri -buildScriptPath $buildScript -Enable

#Pull GitHub starting point template
if($importTemplateRepo)
{
	Copy-GithubRepository -Name $repoName -Author $repoAccoutName -Branch $repoBranch -SourceDirectory $srcPath
}


Write $headerLine
WriteUriContent -Uri $usageUri
Write $headerLine
