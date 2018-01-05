task Clean-Packages {
    Remove-Item -Force -Recurse $packagesDirectory;
    CreateDirectory $packagesDirectory;
}
