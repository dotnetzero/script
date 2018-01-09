function Get-ChoiceValue {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string]$Message,
        [array]$Options
    )

    $optionArray = [System.Management.Automation.Host.ChoiceDescription[]] @()
    $Options | ForEach-Object { 
        Write-Verbose "Adding $($_) options"
        $optionArray += "&$($_)"
    }
    $result = $host.ui.PromptForChoice($Title, $Message, $optionArray, 0)
    return $Options[$result]
}
