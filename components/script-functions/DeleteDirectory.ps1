function DeleteDirectory($directory) {
    if(Test-Path $directory){
        Write-Host "Removing $directory"
        Remove-Item $directory -Force -Recurse | Out-Null
    } else {
        Write-Host "$directory does not exist"
    }
}
