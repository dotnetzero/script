task Compile -depends Init,#Restore-Packages,#Create-AssemblyInfo {
    Exec {
        msbuild $solutionFile `
            /verbosity:$verbosity `
            /p:Configuration=$buildConfiguration `
            /p:Platform=$buildPlatform
    }
}
