# Script Properties
Framework "4.5.2"
properties {
    $baseDirectory = Resolve-Path .\
    $sourceDirectory = "$baseDirectory\$srcPath"

    $company = "$companyName"
    $product = "$productName"

    $outputDirectory = "$baseDirectory\$artifactsPath"
    $packagesDirectory = "$sourceDirectory\packages"
    $packagesOutputDirectory = "$outputDirectory\packages"
    $environment = "Local"

    # msbuild settings
    $solution = "Default.sln"
    $solutionFile = "$sourceDirectory\$solution"
    $verbosity = "normal"
    $buildConfiguration = "Release"
    $buildPlatform = "Any CPU"
    $version = "1.0.0"
    $runOctoPack = "false"

    # tools
    $nugetExe = "$sourceDirectory\.nuget\nuget.exe"
    $migrator = "$sourceDirectory\packages\roundhouse.0.8.6\bin\rh.exe"
    $sqlPackageExe = "$baseDirectory\$toolsPath\SqlPackage.13.0.3450\sqlPackage.exe"

    # database
    $databaseServer = "localhost\sqlexpress2014"
    $integratedSecurity = "Integrated Security=True"
}
