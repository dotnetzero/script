task Clean {
    DeleteDirectory $outputDirectory\**

    @("bin","obj") | ForEach-Object {
        DeleteDirectory "$sourceDirectory\**\$_\"
    }
}
