task Compile -depends Init, Restore-Packages, NpmInstall {
    Exec {
        dotnet build $solutionFile -c $buildConfiguration --version-suffix $version -v $verbosity
    }
}
