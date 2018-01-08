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

    Add-Base64Content -Message "Creating bootstrap file $bootstrapscript" -base64Content $components_run -buildScriptPath $bootstrapscript -Enable
    Add-Base64Content -Message "Creating properties section in $buildScript" -base64Content $scriptproperties_properties -buildScriptPath $buildScript -Enable -Decode @{
        "\`$srcPath"          = $srcPath;
        "\`$companyName"      = $companyName;
        "\`$productName"      = $productName;
        "\`$companyNameClean" = $($companyName | New-SafeName);
        "\`$productNameClean" = $($productName | New-SafeName);
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
}
