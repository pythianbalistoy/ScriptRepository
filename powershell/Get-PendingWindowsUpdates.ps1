function Get-PendingWindowsUpdates
{
<#
    .SYNOPSIS
    Gets the pending windows updates for the server, save it to a csv file and send it if required.
    .DESCRIPTION
    The Get-PendingWindowsUpdates function retreives pending windows updates for the server, save it to a csv file and send it if required.
    #>

[cmdletbinding()]
Param (
[parameter(Mandatory = $true)]
    [Alias("Server", "Computer", "Servername")]
        [string]$Computername=$env:COMPUTERNAME,
        [string]$Filename="Pending_Windows_Updates_$Computername.csv",
        [switch]$DoNotMail,
        [String]$smtpserver="",
        [String]$Sender= "$Computername@domain.com",
        [String]$Subject="Pending Windows Updates Report: $Computername",
        [String]$Body="Attached herewith is the list of Pending Windows Updates for $Computername. Kindly review and schedule the maintenance Accordingly.",
        [String]$Recipient
                )
$Directory=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')
$FullFilename=$Directory +"\$Filename"

 if((Test-Connection -Cn $Computername -BufferSize 16 -Count 1 -ea 0 -quiet))
 {
  $updatesession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$Computername))
  $UpdateSearcher = $updatesession.CreateUpdateSearcher()
  $searchresult = $updatesearcher.Search("IsInstalled=0")  # 0 = NotInstalled | 1 = Installed
#  $searchresult.Updates.Count 
  $Updates = If ($searchresult.Updates.Count  -gt 0) {
  #Updates are  waiting to be installed
    $count  = $searchresult.Updates.Count
  #$searchresult.Updates |select-object Title,KBArticleIDs,SecurityBUlletinIDs,MsrcSeverity,IsDownloaded,MoreInfoUrls,BundledUpdates |  Export-Csv -NoTypeInformation  -Path FullResult.csv 
  #$searchresult.Updates  |  Export-Csv -NoTypeInformation  -Path FullResult.csv 
  For ($i=0; $i -lt $Count; $i++) 
                    { 
                    #Create object holding update 
                    $Update = $searchresult.Updates.Item($i)
                    [pscustomobject]@{
                                        Computername = $ComputernAME
                                        Severity= $Update.MsrcSeverity
                                        Title = $Update.Title
                                        KB = $($Update.KBArticleIDs)
                                        SecurityBulletin = $($Update.SecurityBulletinIDs)
                                        IsDownloaded = $Update.IsDownloaded
                                        Url = $($Update.MoreInfoUrls)
                                        Categories = ($Update.Categories | Select-Object -ExpandProperty Name)
                                        BundledUpdates = @($Update.BundledUpdates)|ForEach{
                                        [pscustomobject]@{
                                                         Title = $_.Title
                                                         DownloadUrl = @($_.DownloadContents).DownloadUrl
                                                         }
                                                         }
                                        Description=$Update.Description
                                        IsMandatory=$Update.IsMandatory
                                        Deadline=$Update.Deadline
                                        SupportUrl= $Update.SupportUrl
                                        UninstallationNotes=$Update.UninstallationNotes
                                }
                                }
  }
  else
  {
  $Updates = "No Pending Updates"
  }
  }
  else
  {
  $Updates = "Server is not reachable, check if it was online."
  $Body= "$Computername is not reachable, check if it was online."
  }
  $Updates  |  Export-Csv -NoTypeInformation  -Path $FullFilename
  if (!$DoNotMail)
  {
  if($Recipient)
  {
  send-mailmessage -to $Recipient -subject $Subject -from $Sender -body $Body -smtpserver $smtpserver -Attachments $FullFilename
  write-output "File $FullFilename generated."
  Write-output "Email Sent to $Recipient"
  }
  else 
  {
  write-output "You did not specify a recipient for the email. No emails has been sent out. The output is at $FullFilename"
  }
  }
  else
  {
  write-output "Output generated at $FullFilename."
  }
}  