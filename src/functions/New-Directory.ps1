function New-Directory {
    [CmdletBinding()]
    param (
        $message,
        $path
    )
    Show-Message $message
    New-Item -Force -ItemType Directory -Path $path | Out-Null
}
