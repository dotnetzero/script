task Compile -depends Init, Restore-Packages {
    Exec {
        msbuild $solutionFile `
            /verbosity:$verbosity `
            /m `
            /nr:false `
            /p:Configuration=$buildConfiguration `
            /p:Platform=$buildPlatform
    }
}
