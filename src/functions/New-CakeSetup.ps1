function New-CakeSetup {
    Invoke-RestMethod `
        -Uri "https://raw.githubusercontent.com/cake-build/bootstrapper/master/res/scripts/build.cake" `
        -OutFile "build.cake"
    Invoke-RestMethod `
        -Uri "https://raw.githubusercontent.com/cake-build/bootstrapper/master/res/scripts/build.ps1" `
        -OutFile "run.ps1"
}
