function Get-InstalledDotnetTemplates {
    [CmdletBinding()]
    param ()

    process {

        $installedTemplates = @()

        if (($env:Path.Split(";") | Select-String dotnet)) {
            # Filter out the blank lines
            $dotnetnewlist = (dotnet new -l) | Where-Object { $_ -notcontains "" }

            #grab the text following the table header + the console horizontial rule
            $templates = $dotnetnewlist | `
                Select-Object -Skip (($dotnetnewlist | `
                        Select-String "^Templates" -CaseSensitive).LineNumber + 1)

            For ($i = 0; $i -lt $templates.Length; $i++) {
                $templateName = $templates[$i].SubString(0, 50).Trim()
                $templateShortName = $templates[$i].SubString(50, 17).Trim()
                $templateLanguage = $templates[$i].SubString(67, 18).Trim()
                $templateTags = $templates[$i].SubString(85).Trim()

                Write-Verbose "Creating $templateName ($templateShortName) using $templateLanguage with tags $templateTags"

                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType NoteProperty -Name Index -Value ($i + 1)
                $object | Add-Member -MemberType NoteProperty -Name Name -Value $templateName
                $object | Add-Member -MemberType NoteProperty -Name ShortName -Value $templateShortName
                $object | Add-Member -MemberType NoteProperty -Name Language -Value $templateLanguage.Split(",")
                $object | Add-Member -MemberType NoteProperty -Name Tags -Value $templateTags.Split("/")

                $installedTemplates += $object
            }
        }

        return $installedTemplates
    }
}
