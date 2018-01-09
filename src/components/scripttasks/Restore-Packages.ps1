task Restore-Packages {
    Exec { & dotnet restore $solutionFile }
}
