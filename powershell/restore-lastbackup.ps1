Param (
[parameter(Mandatory = $true)]
    [Alias("ServerInstance", "SqlInstance", "Source")]

        [string]$SqlServer,
        [string] $Database,
        [String] $Exclude="tempdb",
        [string]$Destination = $SqlServer,
        [string]$DataDirectory,
        [string]$LogDirectory,
        [string]$Prefix = "tstres",
        [switch]$VerifyOnly,
        [switch]$NoCheck,
        [switch]$NoDrop,
        [string]$AzureCredential
    )
#import-module SQLPS | out-null
#import-module DBATools | out-null
#[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null note: removed to avoid asembly conflict, will dynaically pick the version loaded using the next line.
$sqlServerSnapinVersion = (Get-Command Restore-SqlDatabase).ImplementingType.Assembly.GetName().Version.ToString()
$assemblySqlServerSmoExtendedFullName = "Microsoft.SqlServer.SmoExtended, Version=$sqlServerSnapinVersion, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

$RuntimeStart=get-Date -Format o
$AllStopWatch = New-Object system.Diagnostics.Stopwatch
$AllstopWatch.Start()                          

$AllResult=@()
#Check server if exists
$connStringSource = "Server=$SqlServer;Database=msdb;Integrated Security=TRUE;"
$connStringBackup =  "Server=$Destination;Database=msdb;Integrated Security=TRUE;"
$objServer =  new-object ('Microsoft.SqlServer.Management.Smo.Server $assemblySqlServerSmoExtendedFullName') $SqlServer
$objDestination =  new-object ('Microsoft.SqlServer.Management.Smo.Server $assemblySqlServerSmoExtendedFullName') $Destination
###1. Parameter/Variable checks######

try 
{
 $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connStringSource;
        $sqlConnection.Open();
        $sqlConnection.Close();
        Write-output "Connection Test to source server $SQLServer successful!<br>"
}
catch
{
write-output "Could not connect to the Source Server, make sure it is correct and that your login has permissions to the server.<br>" 
exit
}
if($SQLServer -ne $Destination)
{
try 
{
 $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connStringBackup;
        $sqlConnection.Open();
        $sqlConnection.Close();
        Write-output "Connection Test to destination server $destination successful!<br>"
}
catch
{
write-output "Could not connect to the Destination Server, make sure it is correct and that your login has permissions to the server. <br>"
exit
}
}
#Get database file locations
$DefaultFileLocation = $objDestination.Settings.DefaultFile 
$DefaultLogLocation = $objDestination.Settings.DefaultLog 
if ($DefaultFileLocation.Length -eq 0)  
    {  
        $DefaultFileLocation = $objDestination.Information.MasterDBPath  
       
    } 
if ($DefaultLogLocation.Length -eq 0)  
    {  
        $DefaultLogLocation = $objDestination.Information.MasterDBLogPath  

    } 
#Check restore path if exists
if ($datadirectory)
    {
    if (!(Test-SqlPath -SqlServer $destination -Path $datadirectory))
        {
         Write-output "Can't access $datadirectory Please check if The service account has permissions and that it exists.<br>"  
         $datadirectory = $DefaultFileLocation
         Write-output "Restoring on $datadirectory instead.<br>"
         }
    }
else
    {
    $datadirectory = $DefaultFileLocation
    Write-output "restoring database files on $Datadirectory .<br>"
    }
if ($logdirectory)
    {
     if (!(Test-SqlPath -SqlServer $destination -Path $logdirectory))
        {
         Write-output "$Destination can't access $logdirectory. Please check if the service account has permissions and the path exists. <br>"
         $logdirectory = $DefaultLogLocation
         Write-output "Restoring on $logdirectory instead. <br>"
        }
    }
else
    {
     $logdirectory = $DefaultLogLocation
     Write-output "restoring database files on $Logdirectory . <br>"
    }

#check if azureCrdential exists/valid
if($AzureCredential)
{
 $BlobCredential=Get-DBACredential -SQLInstance $destination | Where-Object {$_.Identity -eq $AzureCredential} | select name
    if(!$BlobCredential)
        {
        write-output "$AzureCredential Does not Exists in $destination. Kindly Create the Credential First! URL Backups, if any, will not be restored!<br>"
        }

}
####1. Parameter/Variable checks##########
If (!$Database)
{
$Dblist = $objServer.Databases.Name
}
Else
{
$DBlist = $database -split ","
}
$dbexclude=$Exclude -split ","
$DBlist= $dblist |where-object {$dbexclude -notcontains $_}
$DBCount=$DBList.count
$FileCount=0
$RestoreCount=0
$DBCCCount=0

foreach($dbname in $DBlist)
{

#############Restore Section#############
    $ogdbname=$dbname
    $fileexists = $NULL
    $RestoreResult = $NULL
    $dbccresult = $NULL
    $RestoreStart = $NULL
    $RestoreEnd = $NULL
    $dbccElapsed = $NULL
    $dbccStart = $NULL
    $DbccEnd = $NULL
    $dbccElpased = $NULL
    $DB = $objServer.databases[$dbname]
    ####Test if DB exists in the source
    if(!$DB)
    {
    Write-output "$dbname does not exist on $SQLServer. <br>"
    $fileexists = $False
    $restoreresult = "Skipped - Database Does Not Exists on $SQLServer"
    $dbccresult = "Skipped"
    }
    else
    {
    ###Get the last backup
    $Lastbackup=Get-DbaBackupHistory -SqlServer $SQLServer -Databases $dbname -LastFull -IncludeCopyOnly
    If(!$Lastbackup)
        {
        $FileExists=$False
        $RestoreResult="Skipped, No Backup History"
        $DBCCResult="Skipped"
        }
        else
        {
         [string]$backupname = $lastbackup[0].Path
         if ($Backupname.StartsWith('http') -eq $true)
            {
                if (!$BlobCredential)
                    {
                    $fileexists = $False
                    $restoreresult = "Skipped - Azure Credentials was not provided or does not exists."
                    $dbccresult = "Skipped"
                    }
                else
                    {#check if file exists and restorable.
                        try
                            {
                                $query = "RESTORE FILELISTONLY FROM URL='$backupname' with credential='$AzureCredential';"
                                $dbfiles = Invoke-Sqlcmd -ServerInstance $destination -Database tempdb -Query $query
                                $Fileexists = $True
                                $FileCount=$Filecount+1
                            }
                        catch
                            {
                                $FileExists =  $False
                                $restoreresult = "No.The file either does not exists, corrupted backup or the Credential provided does not have access."
                                $dbccresult = "Skipped"
                            }
                     }

              }
           elseif ($Backupname.StartsWith('\\') -eq $true)
              {
                    if((Test-SqlPath -SqlServer $destination -Path $backupname) -eq $false)
                        {
                            $fileexists = $false
                            $restoreresult = "Skipped"
                            $dbccresult = "Skipped"
                        }
                    else
                        {
                            $FileExists = $true
                            $FileCount=$Filecount+1
                        }

                }
            elseif ($backupname.indexof(":") -eq 1)
                {
                    if ($SQLServer -ne $destination)
                        {
                            if($SQLServer.indexOf("\") -lt 0)
                                {
                                    $backupname = "\\"+$SQLServer+ "\"+ $Backupname.Replace(":","$")
                                }
                            else
                                {
                                    $backupname = "\\"+$SQLServer.Substring(0,$SQLServer.INdexof("\")+1) + $Backupname.Replace(":","$")
                                }
    
                        }

                    if((Test-SqlPath -SqlServer $destination -Path $backupname) -eq $false)
                        {
                            $fileexists = $false
					        $restoreresult = "Skipped"
					        $dbccresult = "Skipped"
                        }
                    else
                        {
                            $FileExists = $true
                            $FileCount=$Filecount+1
                        }

                }
            else
            {
            write-output "This script can only process sql native backups.<br>"
            $FileExists =  $False
            }
        }
    if($backupname -and $FileExists)
    {
     if($VerifyOnly)
                 {
   
                 if ($backupname.Startswith('http') -eq $true)
                 
                        {
                        $query = "RESTORE VERIFYONLY FROM URL='$backupname' with credential='$AzureCredential';"
                        }
                 else
                        {
                        $query = "RESTORE VERIFYONLY FROM disk='$backupname';"
                         }
                 try
                     {
                        $restoreresult = Invoke-Sqlcmd -ServerInstance $destination -Database tempdb -Query $query
                        $restoreresult = "Success!"
                        $RestoreCount=$RestoreCount+1
                     }
                 catch
                     {
                        $restoreresult = "Failed! $_.Exception.Message"
                     }
                 
                 $dbccresult =  "Skipped"
                }
     else
     {#start of restore
        $ogdbname = $dbname
        $dbname = "$prefix-$dbname"
        $destdb = $objDestination.databases[$dbname]
            if ($destdb)
                {
                    Write-output "$dbname already exists on $destination - skipping. <br>"
                    $restoreresult = "Skipped - Destination Database exists!"
                }
            else
            {
                if($backupname.Startswith('http') -eq $true)
                    {
                    $query = "RESTORE FILELISTONLY FROM URL='$backupname'with credential='$AzureCredential';"
                    }
                else 
                    {
                    $query = "RESTORE FILELISTONLY FROM Disk='$backupname';"
                    }
                try
                    {
                    $dbfiles = Invoke-Sqlcmd -ServerInstance $destination -Database tempdb -Query $query
                    }
                catch
                    {
                    $restoreresult = "Restore Failed. $_.Exception.Message"
                    $dbccresult = "Skipped"
                    } 
            #Process the relocate file information
            $relocate = @()
            foreach($dbfile in $dbfiles)
                {
                    $DbFileName = $dbfile.PhysicalName | Split-Path -Leaf
                    $DBFileName = $Prefix+"_"+$DBFilename
                    if($dbfile.Type -eq 'L')
                            {
                            $newfile = Join-Path -Path $LogDirectory -ChildPath $DbFileName
                            } 
                    else 
                            {
                            $newfile = Join-Path -Path $DataDirectory -ChildPath $DbFileName
                            }
                    $relocate += New-Object 'Microsoft.SqlServer.Management.Smo.RelocateFile $assemblySqlServerSmoExtendedFullName' ($dbfile.LogicalName,$newfile)
                }
                #Start of the actual restore
                $RestoreStart=get-Date -Format o
                $StopWatch = New-Object system.Diagnostics.Stopwatch
                $stopWatch.Start()                          
                if ($backupname.Startswith('http') -eq $true)
                    {
                        try
                            {  
                            $restoreresult = Restore-SqlDatabase -ServerInstance $destination -Database $dbname -BackupFile $backupname -SqlCredential $AzureCredential -RelocateFile $Relocate -ReplaceDatabase
                            $restoreresult = "Success"
                            $RestoreCount=$RestoreCount+1
                           
                            }
                        catch
                           {
                           $restoreresult = "Failed. $_.Exception.Message"
                           }
                     }
                else
                    {
                        try
                            {
                            $restoreresult = Restore-SqlDatabase -ServerInstance $destination -Database $dbname -BackupFile $backupname -RelocateFile $Relocate -ReplaceDatabase
                            $restoreresult = "Success"
                            $RestoreCount=$RestoreCount+1
                            }
                           catch
                           {
                           $restoreresult = "Failed. $_.Exception.Message"
                           }
                    }
                $RestoreEnd=get-Date -Format o
                $stopWatch.Stop()
                $ts = $StopWatch.Elapsed
                $RestoreElapsed=[system.String]::Format("{0:00}:{1:00}:{2:00}.{3:00}",$ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10);
                if(!$NoCheck -and !$VerifyOnly -and $restoreresult -eq "Success")
                    {
                     if ($ogdbname -eq "master")

                            {

                                $dbccresult = "DBCC CHECKTABLE skipped for restored master ($dbname) database"
                                

                            }

                            else

                            {
                                $DbccStart=get-Date -Format o
                                $StopWatch = New-Object system.Diagnostics.Stopwatch
                                $stopWatch.Start()                
                                $query = "dbcc checkdb ([$dbname]) with NO_INFOMSGS;"
                                  try
                                  {
                                   $dbccresult = Invoke-Sqlcmd -ServerInstance $destination -Database tempdb -Query $query
                                   $dbccresult = "Success"
                                   $DBCCCount=$DBCCCount+1
                                   }
                                   catch
                                   {
                                   $dbccresult = "CheckDB Failed!"
                                   }
                                $DbccEnd=get-Date -Format o
                                $stopWatch.Stop()
                                $ts = $StopWatch.Elapsed
                                $DbccElapsed=[system.String]::Format("{0:00}:{1:00}:{2:00}.{3:00}",$ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10);

                            }
                    
                    }

                    #drop restored db if specified
                    if(!$NoDrop -and $restoreresult -eq "Success")
                    {
                    
                       try

                                {
                                    $objDestination.Databases[$dbname].drop()
                                    $removeresult = "Success"
                                    Write-output "Dropped $dbname Database on $destination . <br>"

                                }

                                catch

                                {

                                    Write-output "Failed to Drop database $dbname on $destination .<br>"
                                    

                                }
                    
                    }
            }


     #end of restore
     }
    #end of $backupname and $fileexists
    }

    #end of else for !$DB
    }
    
    $ThisResult = [pscustomobject]@{

                        SourceServer=$SQLServer
                        TestServer=$destination
                        Database=$ogdbname
                        RestoredAs=$dbname
                        FileExists=$FileExists
                        Size=$lastbackup.TotalSize
                        RestoreResult=$RestoreResult
                        RestoreStart=$RestoreStart
                        RestoreEnd=$RestoreEnd
                        RestoreElapsed=$RestoreElapsed
                        DbccResult=$dbccresult
                        DbccStart=$dbccStart
                        DbccEnd=$DbccEnd
                        DbccElapsed=$dbccElapsed
                        BackupDate=$lastbackup.Start
                        BackupFiles =$backupname -join ";"
                    }  

#####end restore section#################
$AllResult+=$ThisResult
}
$RuntimeEnd=get-Date -Format o
$AllstopWatch.Stop()
$ts = $AllStopWatch.Elapsed
$RuntimeTotal=[system.String]::Format("{0:00}:{1:00}:{2:00}.{3:00}",$ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10);
write-output "<h2><span style="text-decoration: underline;">Summary:</span></h2>"
Write-output "Number of Databases Processed: $DBcount <br>"
Write-output "Number of Database Backup Files that Exists: $FileCount <br>"
Write-output "NUmber of Successful Database Restores: $RestoreCount <br>"
Write-output "Number of Successful DBCC:$DBCCCount <br>"
Write-output "Test Started on: $RunTimeStart <br>"
Write-output "Test Ended at $RuntimeEnd <br>"
write-output "Test Runtime: $RuntimeTotal <br>"
write-output "<h2><span style="text-decoration: underline;">Detailed Results:</span></h2>"
Write-output "<br>"

$AllResult | convertto-html -Fragment 
