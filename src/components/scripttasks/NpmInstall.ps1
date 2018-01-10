task NpmInstall {
    Get-ChildItem -Path $sourceDirectory | `
        Where-Object { $_.PSIsContainer } | `
        Where-Object { Test-Path -Path "$($_.FullName)\package.json" } | `
        ForEach-Object { 
        Push-Location
        Set-Location -Path $_.FullName
        Exec {
            npm install
        }
        Pop-Location
    }
}
