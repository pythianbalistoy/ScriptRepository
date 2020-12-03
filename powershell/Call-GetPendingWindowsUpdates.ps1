Param (
[parameter(Mandatory = $true)]
        [string]$InputFile,
        [String]$smtpserver="smtp.domain.com",
        [String]$Recipient
                )
$Servers=Get-content -path $InputFile

Foreach($Server in $Servers)
{
.\Get-PendingWindowsUpdates.ps1 -Computername $Server -smtpserver $smtpserver -Recipient $Recipient
}