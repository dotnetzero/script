[CmdletBinding()]
param(
    [string]$sha,
    [string]$version
)

$dotnetTemplates = "$PSScriptRoot\src\Get-InstalledDotnetTemplates.ps1"
$sourceScript = "$PSScriptRoot\src\functions\Compress-String.ps1"
$sourceBashScript = "$PSScriptRoot\src\init.sh"
. $sourceScript

$componentScriptDirectory = "$PSScriptRoot\src\components"
$functionScriptDirectory = "$PSScriptRoot\src\functions"
$compressedHeader = "# Compressed artifacts"

$artifactScriptPath = "$PSScriptRoot\artifacts\"
$artifactPSScript = "$artifactScriptPath\init.ps1"
$artifactBashScript = "$artifactScriptPath\init.sh"

function Compress-ComponentScripts {
    $scriptBlock = $compressedHeader

    Write-Verbose $scriptBlock  

    if ($version) {
        # Add version info
        $version = "Version: $version"
        $scriptBlock += "`r`n"
        $scriptBlock += "`$components_version=`"$((Compress-String -StringContent $version))`""
    }

    if ($sha) {
        # Add source code sha
        $sha = "Sha: $sha"
        $scriptBlock += "`r`n"
        $scriptBlock += "`$components_sha=`"$((Compress-String -StringContent $sha))`""
    }

    # Add licence encoded data
    $scriptBlock += "`r`n"
    $scriptBlock += "`$components_license=`"$((Compress-String -StringContent (Get-Content -Raw -Path "$PSScriptRoot\LICENSE")))`""

    Get-ChildItem -Path $componentScriptDirectory -Recurse | `
        Where-Object { ! $_.PSIsContainer } | `
        ForEach-Object {
 
        $variableName = "$($_.Directory.BaseName)_$($_.BaseName -replace "-", $null)" 
        $stringData = Get-Content -Raw -Path $_.FullName
        $compressedData = Compress-String -StringContent $stringData

        $scriptBlock += "`r`n"
        $scriptBlock += "`$$($variableName)=`"$compressedData`""
    }

    return $scriptBlock
}

function Join-FunctionScripts {
    $functionContent = "# Functions"
    $functionContent += "`r`n"
    Get-ChildItem -Path $functionScriptDirectory | Sort-Object FullName | ForEach-Object {
        $functionContent += $(Get-Content -Raw -Path $_.FullName)
    }
    return $functionContent
}

function New-CompiledScrpt {
    if (Test-Path -Path $artifactScriptPath) {
        Remove-Item -Force -Recurse -Path $artifactScriptPath
    }
    New-Item -ItemType Directory -Path $artifactScriptPath -Force | Out-Null

    # Build the powershell script
    Set-Content -Encoding Ascii -Path $artifactPSScript -Value $(Compress-ComponentScripts) -Force
    Add-Content -Encoding Ascii -Path $artifactPSScript -Value (Join-FunctionScripts)
    # Add-Content -Encoding Ascii -Path $artifactPSScript -Value (Get-Content -Raw $sourceScript)
    # Add-Content -Encoding Ascii -Path $artifactPSScript -Value (Get-Content -Raw $dotnetTemplates)

    # Build the bash script
    Set-Content -Encoding Ascii -Path $artifactBashScript -Value (Get-Content -Raw $sourceBashScript)
}

New-CompiledScrpt