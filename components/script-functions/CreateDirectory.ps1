function CreateDirectory($directory) {
    Write-Host "Creating $directory"
    New-Item $directory -ItemType Directory -Force | Out-Null
}
