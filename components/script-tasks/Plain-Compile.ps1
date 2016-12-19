task Compile `
    -depends Init, Restore-Packages, Create-AssemblyInfo `
    -description "Compiles the code" `
    -requiredVariables solutionFile, verbosity, buildConfiguration, buildPlatform `
{
    Exec {
        msbuild $solutionFile `
            /verbosity:$verbosity `
            /m `
            /nr:false `
            /p:Configuration=$buildConfiguration `
            /p:Platform=$buildPlatform
    }
}
