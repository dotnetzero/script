function New-PsakeSetup {
    [CmdletBinding()]
    param (
        [string]$CompanyName,
        [string]$ProductName,
        [string]$SrcPath = "src",
        [string]$ArtifactsPath = "artifacts",
        [string]$ToolsPath = "tools",
        [string]$Bootstrapscript = "run.ps1",
        [string]$BuildScript = "default.ps1",
        [boolean]$AddNugetPackageRestore = $true
    )

    Add-Base64Content -Message "Creating bootstrap file $bootstrapscript" -base64Content $dotnetzero.components_run -buildScriptPath $Bootstrapscript -Enable
    Add-Base64Content -Message "Creating properties section in $BuildScript" -base64Content $dotnetzero.scriptproperties_properties -buildScriptPath $BuildScript -Enable -Decode @{
        "\`$srcPath"          = $srcPath;
        "\`$companyName"      = $companyName;
        "\`$productName"      = $productName;
        "\`$companyNameClean" = $($companyName | New-SafeName);
        "\`$productNameClean" = $($productName | New-SafeName);
        "\`$artifactsPath"    = $artifactsPath;
    }

    Add-Content -Path $buildScript -Value "# Script Tasks" -Encoding Ascii | Out-Null

    Add-Base64Content -Message "Adding default task to $buildScript" -base64Content $dotnetzero.scripttasks_Default -buildScriptPath $BuildScript -Enable
    Add-Base64Content -Message "Adding clean task to $buildScript" -base64Content $dotnetzero.scripttasks_Clean -buildScriptPath $BuildScript -Enable
    Add-Base64Content -Message "Adding init task to $buildScript" -base64Content $dotnetzero.scripttasks_Init -buildScriptPath $BuildScript -Enable

    # Package Restore
    Add-Base64Content -Message "Adding package restore task to $buildScript" -base64Content $dotnetzero.scripttasks_RestorePackages -buildScriptPath $BuildScript -Enable:$addNugetPackageRestore
    Add-Base64Content -Message "Adding package clean task to $buildScript" -base64Content $dotnetzero.scripttasks_CleanPackages -buildScriptPath $BuildScript -Enable:$addNugetPackageRestore

    # Unit Tests
    Add-Base64Content -Message "Adding unit test task to $buildScript" -base64Content $dotnetzero.scripttasks_UnitTest -buildScriptPath $BuildScript -Enable

    $packageRestoreToken = if ($addNugetPackageRestore) { @{ "\#Restore-Packages\,\#" = "Restore-Packages,"; }
    }
    else { @{ "\#Restore-Packages\,\#" = ""; }
    }

    Add-Base64Content -Message "Adding compile task to $buildScript" -base64Content $dotnetzero.scripttasks_PlainCompile -buildScriptPath $BuildScript -Enable -Decode $packageRestoreToken
    Add-Base64Content -Message "Adding assmebly info task to $buildScript" -base64Content $dotnetzero.scriptAssemblyInfoUri -buildScriptPath $BuildScript -Enable

    Add-Content -Path $buildScript -Value "# Script Functions" -Encoding Ascii | Out-Null
    Add-Base64Content -Message "Adding create directory function to $buildScript" -base64Content $dotnetzero.scriptfunctions_CreateDirectory -buildScriptPath $BuildScript -Enable
    Add-Base64Content -Message "Adding delete function to $buildScript" -base64Content $dotnetzero.scriptfunctions_DeleteDirectory -buildScriptPath $BuildScript -Enable
}
