param(
    [string[]]$taskList=@('Default'),
    [string]$version="1.0.0",
    [switch]$runOctoPack=$false,
    [switch]$help=$false
)

$nugetPath = ".\src\.nuget\"
if((Test-Path -Path "$nugetPath\nuget.exe") -eq $false){
    Write-Host "Downloading nuget to $nugetPath"
    New-Item -ItemType Directory -Path $nugetPath -Force | Out-Null
    Invoke-WebRequest -Uri "https://www.nuget.org/nuget.exe" -OutFile "$nugetPath\nuget.exe" | Out-Null
}

$psakePath = ".\tools\psake\4.6.0\psake.psm1"
if((Test-Path -Path $psakePath) -eq $false){
    Write-Host "Psake module missing"
    Write-Host "Updating package provider"
    Install-PackageProvider NuGet -Force
    Write-Host "Seaching for psake package and saving local copy"
    $module = Find-Module -Name psake
    Write-Host "Psake module found. Saving local copy"
    $module | Save-Module -Path .\tools\ -Force
}

# '[p]sake' is the same as 'psake' but  is not polluted
Remove-Module [p]sake
Import-Module $psakePath
if ($help) {
  Invoke-Psake -buildFile ".\default.ps1" -docs
  return
}

# call default.ps1 with properties
Invoke-Psake -buildFile ".\default.ps1" -taskList $taskList -properties @{ "version" = $version; "runOctoPack" = $runOctoPack; }

if($psake.build_success) { exit 0 } else { exit 1 }
