task Compile -depends Init, Restore-Packages {
    Exec {
        dotnet build $solutionFile -c $buildConfiguration --version-suffix $version -v $verbosity
    }
}
