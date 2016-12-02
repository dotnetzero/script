task Compile -depends Init, Restore-Packages, Create-AssemblyInfo {
    Exec {
        msbuild $solutionFile `
            /verbosity:$verbosity `
            /m `
            /p:Configuration=$buildConfiguration `
            /p:Platform=$buildPlatform
    }
}
