param(
    $taskList=@('Default'),
    $version="1.0.0",
    [switch]$runOctoPack
)

$nugetDirectory = ".\src\.nuget"
$nugetPath = Join-Path $nugetDirectory "nuget.exe"
if((Test-Path -Path $nugetPath) -eq $false){
    Write-Host "Downloading nuget to $nugetDirectory"
    New-Item -ItemType Directory -Path $nugetDirectory -Force | Out-Null
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath | Out-Null
} else {
    if(((Get-ChildItem $nugetPath).LastWriteTime - [DateTime]::Today).Days -lt 0){
        Write-Host "Nuget daily check" -foreground Yellow
        & $nugetPath update -self
    }
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

# call default.ps1 with properties
Invoke-Psake -buildFile ".\default.ps1" -taskList $taskList -properties @{ "version" = $version; "runOctoPack" = $runOctoPack; }

if($psake.build_success) { exit 0 } else { exit 1 }