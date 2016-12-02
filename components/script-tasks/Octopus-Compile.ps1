task Compile -depends Init,Restore-Packages,Create-AssemblyInfo {
    Exec {
        msbuild $solutionFile `
            /verbosity:$verbosity `
            /m `
            /p:Configuration=$buildConfiguration `
            /p:Platform=$buildPlatform `
            /p:OctoPackPackageVersion=$version `
            /p:RunOctoPack=$runOctoPack `
            /p:OctoPackEnforceAddingFiles=true `
            /p:OctoPackPublishPackageToFileShare="$packagesOutputDirectory"
    }
}
