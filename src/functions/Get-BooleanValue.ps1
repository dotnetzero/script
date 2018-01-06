function Get-BooleanValue {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string]$Message,
        [boolean]$Default
    )

    $index = if ($Default) { 0 } else { 1 }
    $enabled = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Enable $Title"
    $disabled = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Disable $Title"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($enabled, $disabled)
    $result = $Host.UI.PromptForChoice($Title, $Message, $options, $index)
    $flag = if ($result) { $false } else { $true }
    return $flag
}
