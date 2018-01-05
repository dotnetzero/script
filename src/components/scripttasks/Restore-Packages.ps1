task Restore-Packages {
    Exec { & $nugetExe "restore" $solutionFile }
}
