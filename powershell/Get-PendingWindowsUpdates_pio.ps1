$Computername = $env:COMPUTERNAME
  $updatesession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$Computername))
  $UpdateSearcher = $updatesession.CreateUpdateSearcher()
  $searchresult = $updatesearcher.Search("IsInstalled=0")  # 0 = NotInstalled | 1 = Installed
  $searchresult.Updates.Count 
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
  $Updates  |  Export-Csv -NoTypeInformation  -Path FullResult.csv 