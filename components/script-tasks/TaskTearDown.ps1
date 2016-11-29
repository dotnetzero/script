TaskTearDown{
    if($env:TEAMCITY_VERSION){
        Write-Output "##teamcity[blockClosed name=$taskName']"
    }
}
