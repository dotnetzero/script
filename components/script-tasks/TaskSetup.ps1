TaskSetup{
    if($env:TEAMCITY_VERSION){
        Write-Output "##teamcity[blockOpened name='$taskName']"
    }
}
