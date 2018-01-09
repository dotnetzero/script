task Unit-Test -depends Compile {
    Exec {
        Get-ChildItem -Path "$sourceDirectory\*.Test*" | ForEach-Object { dotnet test $_.FullName }
    }
}
