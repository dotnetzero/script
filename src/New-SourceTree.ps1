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

    $companyName = Get-StringValue -Title "Company Info" -Message "Select Name" -Default $companyName
    $productName = Get-StringValue -Title "Product Info" -Message "Select Name" -Default $productName
    $srcPath = Get-StringValue -Title "Source Code" -Message "Select Directory" -Default $srcPath
    $artifactsPath = Get-StringValue -Title "Build Output" -Message "Select Directory" -Default $artifactsPath
    $toolsPath = Get-StringValue -Title "Tools" -Message "Select Directory" -Default $toolsPath
    $buildScript = Get-StringValue -Title "Build Script" -Message "Select Name" -Default $buildScript
    $addNugetPackageRestore = Get-BooleanValue -Title "Package Restore" -Message "Add nuget package restore task" -Default $addNugetPackageRestore
    $addUnitTests = Get-BooleanValue -Title "Build Script" -Message "Add unit tests task" -Default $addUnitTests

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
    Add-Base64Content -Message "Adding unit test task to $buildScript" -base64Content $scripttasks_UnitTest -buildScriptPath $buildScript -Enable:$addUnitTests

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

    if ( Get-BooleanValue -Title "dotnet Template" -Message "Add projects to $srcPath" -Default $true) {
        $dotNetProjects = Get-DotNetProjects
        $solutionFileName = "$companyNameClean.$productNameClean"
        New-DotnetSolution -DotNetProjects $dotNetProjects -SolutionName $solutionFileName -SourceDirectory $srcPath
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
        [parameter(ValueFromPipeline)][string]$Message
    )
    Write-Host -ForegroundColor Green $Message 
}

function Add-Base64Content {
    [CmdletBinding()]
    param (
        $Message,
        $Base64Content,
        $BuildScriptPath,
        [switch]$Enable,
        [hashtable]$Decode
    )
    if ($enable) {

        Show-Message $Message
        $content = Expand-String -Base64Content $Base64Content
        if ($Decode) {
            $Decode.GetEnumerator() | ForEach-Object {
                $key = $_.Key; $value = $_.Value;
                $content = ($content -replace $key, $value)
            }
        }
        Add-Content -Path $BuildScriptPath -Value $content -Encoding Ascii  | Out-Null
    }
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

        $data = [System.Convert]::FromBase64String($Base64Content)
        
        $ms = New-Object System.IO.MemoryStream
        $ms.Write($data, 0, $data.Length)
        $ms.Seek(0, 0) | Out-Null
        
        $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
        $sr = New-Object System.IO.StreamReader($cs)
        $str = $sr.readtoend()
        return $str
        
    }
}
