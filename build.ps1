[CmdletBinding()]
param(
    [string]$sha,
    [string]$version
)

$dotnetTemplates = "$PSScriptRoot\src\Get-InstalledDotnetTemplates.ps1"
. "$PSScriptRoot\src\functions\Compress-String.ps1"
. "$PSScriptRoot\src\functions\Set-BlankLine.ps1"

$sourceBashScript = "$PSScriptRoot\src\init.sh"

$componentScriptDirectory = "$PSScriptRoot\src\components"
$functionScriptDirectory = "$PSScriptRoot\src\functions"

$artifactScriptPath = "$PSScriptRoot\artifacts\"
$artifactPSScript = "$artifactScriptPath\init.ps1"
$artifactBashScript = "$artifactScriptPath\init.sh"

$compressedHeader = "# Compressed artifacts"
function Compress-ComponentScripts {
    $scriptBlock = $compressedHeader

    Write-Verbose $scriptBlock  

    $scriptBlock += "`r`n"
    $scriptBlock += "`$dotnetzero = New-Object -TypeName PSObject"

    if ($version) {
        # Add version info
        $version = "Version: $version"
        Write-Host $version
        $scriptBlock += "`r`n"
        $scriptBlock += "`$dotnetzero | Add-Member -MemberType NoteProperty -Name components_version -Value `"$((Compress-String -StringContent $version))`""
    }

    if ($sha) {
        # Add source code sha
        $sha = "Sha: $sha"
        Write-Host $sha
        $scriptBlock += "`r`n"
        $scriptBlock += "`$dotnetzero | Add-Member -MemberType NoteProperty -Name components_sha -Value `"$((Compress-String -StringContent $sha))`""
    }

    # Add licence encoded data
    $scriptBlock += "`r`n"
    $scriptBlock += "`$dotnetzero | Add-Member -MemberType NoteProperty -Name components_license -Value `"$((Compress-String -StringContent (Get-Content -Raw -Path "$PSScriptRoot\LICENSE")))`""

    Get-ChildItem -Path $componentScriptDirectory -Recurse | `
        Where-Object { ! $_.PSIsContainer } | `
        ForEach-Object {
 
        $variableName = "$($_.Directory.BaseName)_$($_.BaseName -replace "-", $null)" 
        $stringData = Get-Content -Raw -Path $_.FullName
        $compressedData = Compress-String -StringContent $stringData

        $scriptBlock += "`r`n"
        $scriptBlock += "`$dotnetzero | Add-Member -MemberType NoteProperty -Name $($variableName) -Value `"$compressedData`""
    }

    return $scriptBlock | Set-BlankLine -Count 0
}

function Join-FunctionScripts {
    $functionContent = "# Functions"
    $functionContent += "`r`n"
    Get-ChildItem -Path $functionScriptDirectory | Sort-Object FullName | ForEach-Object {
        $functionContent += $(Get-Content -Raw -Path $_.FullName) | Set-BlankLine
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

    # Build the bash script
    Set-Content -Encoding Ascii -Path $artifactBashScript -Value (Get-Content -Raw $sourceBashScript)
}

New-CompiledScrpt