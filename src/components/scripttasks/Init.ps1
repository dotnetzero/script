task Init {
    Assert(Test-Path $nugetExe) -failureMessage "Nuget command line tool is missing at $nugetExe"

    Write-Host "Creating build output directory at $outputDirectory"
    CreateDirectory $outputDirectory
}
