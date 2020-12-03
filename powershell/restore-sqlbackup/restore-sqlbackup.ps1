function Write-Log
{
    [CmdletBinding()]
    #[Alias('wl')]
    [OutputType([int])]
    Param
    (
        # The string to be written to the log.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias('LogContent')]
        [string]$Message,

        # The path to the log file.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [Alias('LogPath')]
        [string]$Path,
        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=3)]
        [ValidateSet('Error','Warn','Info')]
        [string]$Level='Info',
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )
    Begin
    {
    }
    Process
    {
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Warning "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }
        # If attempting to write to a log file in a folder/path that doesn't exist
        # to create the file include path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }
        # Now do the logging and additional output based on $Level
        switch ($Level) {
            'Error' {
                Write-Error $Message
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ERROR: $Message" | Out-File -FilePath $Path -Append
                    }
            'Warn' {
                Write-Warning $Message
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') WARNING: $Message" | Out-File -FilePath $Path -Append
                }
            'Info' {
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') INFO: $Message" | Out-File -FilePath $Path -Append
                }
            }
    }
    End
    {
    }
    }
#requires -version 2

<#

.SYNOPSIS

 Restore-SQLBackup is a powershell script written for Clickpoint. This powershell script automates the restore of a SQL Backup to a Destination server. 
 The script accepts a specific backup file to be restored and/or a source SQL Server and Database to check the Backup history and restore based on a 
 specified restore time according to the msdb backup history of the source database.



.DESCRIPTION

 Restore-SQLBackup is a powershell script written for Clickpoint. This powershell script automates the restore of a SQL Backup to a Destination server. 
 The script accepts a specific backup file to be restored and/or a source SQL Server and Database to check the Backup history and restore based on a 
 specified restore time according to the msdb backup history of the source database.

 NOTE: The script requires two sql files to be saved on the same directory as where you are going to execute it:
 get-ClosestFullBackup.sql
 get-TlogsToRestore.sql




.PARAMETER SourceServer
The source SQL Server where the original database to be restored is located. Specify this if you want to restore base on backup history. This is ignored if you specify a backup file to be restored.

.PARAMETER  sourcedb
The database name of the original database on the source SQL Server. Specify this if you want to restore base on the database's backup history. This required if you specify a Soure SQL Server and ignored if you specify a backup file to be restored.
.PARAMETER  destination
The destination sql server where the backups will be restore on. This is required.

.PARAMETER destinationdb
The database name that the backups will be restored as on the destination sql server. If this is not specified, the original/source database name will be used. It is required if you specify a backup file.

.PARAMETER Backuppath
If you want to restore a specific backup file, you can use this parameter. If this is given, source server is ignored.

.PARAMETER AzureCredential
This is he credential to be used if the backups type is URL. If not specified, url backups cannot be restored. Please note that you need to create the Credential before running the restore.

.PARAMETER RestoreTime
This is the point in time to restore if restoring based on backup history. The script will restore the closest full backups and Transaction log backups to the date specified. 

.PARAMETER WithReplace
Switch parameter. Specify this if you want to replace the destination db if it exists on the destination server.

.PARAMETER NOrecovery
Switch paramter. Specify this if you want to leave the database in recovery.

.PARAMETER DataDirectory
Destination path for Database files. IF this is not specified the script will restore the db on the destination sql server's default Data path. If that configuration is not set, it will restore the the database files on the same location as the system databases.

.PARAMETER LogDirectory
Destination path for Database log files. IF this is not specified the script will restore the db on the destination sql server's default Log path. If that configuration is not set, it will restore the the database log files on the same location as the system databases.

.PARAMETER IgnoreLogBackup
Switch Parameter. Specify this if you only want to restore the full backup and ignore any transaciton log backups.

.PARAMETER outputlog
output log path. If not specified, it will save the logs on the execution directory.




.OUTPUTS

Log file stored in the specified $outputlog path or execution directory if not specified with the file name restore-backup_yyyyMMddHHmmss.log



.NOTES

  Version:        1.0

  Author:         Pio Balistoy

  Creation Date:  June 8, 2018

  Purpose/Change: Initial script development

  

.EXAMPLE

  Restore specific Backup file. The command below will restore the specified backup file to the destination server using the speficied destinationdb name and Credential replacing the db if existing.

  restore-sqlbackup -destination "us-cpdev-sql2" -destinationdb avail -backuppath "https://uwsesqlbackups.blob.core.windows.net/backup-uw-se-sql-new/avail/FULL/UW-SE-SQL-01_avail_FULL_COPY_ONLY_20180517_210002.bak" -azurecredential "uwsesqlbackups" -WithReplace

.EXAMPLE

  Restore based on Source database Backup history. The command below will restore the closest full backup and the transaction log up to the specified RestoreTime of the Sourcedb from SourceServer to destination server as destinationdb. The database files will be moved to the specified Data and Log Directory on the destination server.

  restore-sqlbackup -sourceserver "uw-se-sql-01" -sourcedb "SalesExec_3" -destination "us-cpdev-sql2" -destinationdb testRestoredb -DataDirectory "F:\Data" -LogDirectory "F:\Data" -AzureCredential "uwsesqlbackups" -RestoreTime "June 3, 2018"

.EXAMPLE

  Restore based on Source database Backup history, ignoring transaction log backups. The command below will restore the closest full backup to the specified RestoreTime of the Sourcedb from SourceServer to destination server as destinationdb. The database files will be moved to the specified Data and Log Directory on the destination server.

  restore-sqlbackup -sourceserver "uw-se-sql-01" -sourcedb "SalesExec_3" -destination "us-cpdev-sql2" -destinationdb testRestoredb -DataDirectory "F:\Data" -LogDirectory "F:\Data" -AzureCredential "uwsesqlbackups" -RestoreTime "June 3, 2018" -IgnoreLogBackup


#>
function restore-sqlbackup {
param([string]$SourceServer,
[string]$sourcedb,
[Parameter(Mandatory=$true)][string]$destination,
[string]$destinationdb,
[string]$Backuppath,
[string]$AzureCredential,
[datetime]$RestoreTime,
[switch]$WithReplace,
[switch]$NOrecovery,
[string]$DataDirectory,
[string]$LogDirectory,
[switch]$IgnoreLogBackup,
[string]$outputlog
)
$sqlServerSnapinVersion = (Get-Command Restore-SqlDatabase).ImplementingType.Assembly.GetName().Version.ToString()
$assemblySqlServerSmoExtendedFullName = "Microsoft.SqlServer.SmoExtended, Version=$sqlServerSnapinVersion, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
#[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo  $assemblySqlServerSmoExtendedFullName")
$Directory=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\")
##Check input parameters first.
if (!$restoretime)
{ $restoretime=get-date}
if(!$OutputLog)
{
$outputlog=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\") 
$outputlog=$outputlog+ "\restore-backup_$(Get-Date -Format 'yyyyMMddHHmmss').log"
write-output "Output log not specified. Writing the logs here $outputlog"}
Write-log -path $outputlog -message "Restore-Backup Started." -level Info
Write-Log -path $outputlog -message "Noting down the parameters supplied: 
SourceServer=$SourceServer
Sourcedb=$sourcedb
Destination=$destination
DestinationDB=$destinationdb
BackupPath=$Backuppath
AzureCredential=$AzureCredential
StopAt=$RestoreTime
Replace=$WithReplace
DataDirectory=$DataDirectory
LogDirectory=$LogDirectory
IgnoreTlogs=$IgnoreLogBackup
Outputlog=$outputlog" -level info

if($sourceServer -and $BackupPath)
{write-output "Specific Backup File provided, Source Server will be ignored."
 Write-log -path $outputlog -message "Specific Backup File provided, Source Server will be ignored." -level Info
}
if($SourceServer -and !$sourcedb)
{
write-output "Kindly provide the database name to check the backup history on $SourceServer."
Write-log -path $outputlog -message "Kindly provide the database name to check the backup history on $SourceServer." -level Error
break
}
if($IgnoreLogBackup -and !$RestoreTime)
{
write-output "IgnoreTLogs switch was specified. The restore will only attempt to restore th full backup closest to $RestoreTime."
Write-log -path $outputlog -message "IgnoreTLogs switch was specified. The restore will only attempt to restore the full backup closest to $RestoreTime." -level Info
}
if(!$destinationdb -and $Sourcedb)
{
$destinationdb=$sourcedb
write-output "Destinataion Database name was not provided, db will be restored using the source database name $Sourcedb"
Write-log -path $outputlog -message "Destinataion Database name was not provided, db will be restored using the source database name $Sourcedb" -level Info
}
if(!$destinationdb -and !$sourcedb)
{
write-output "Please provide a destination database Name."
Write-log -path $outputlog -message "Please provide a destination database Name." -level Error
break
}

##check connectivity
#1. C SQL Server connectivity.
Write-log -path $outputlog -message "Testing Connectivity...." -level Info

$connStringBackup =  "Server=$Destination;Database=msdb;Integrated Security=TRUE;"

#$objDestination =  new-object ('Microsoft.SqlServer.Management.Smo.Server $assemblySqlServerSmoExtendedFullName') $Destination
#$ObjServer=$objDestination
try 
{
 $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connStringBackup
        $sqlConnection.Open();
        $sqlConnection.Close();
        Write-log -path $outputlog -message "Connected to $destination successfully." -level Info
        
}
catch
{
write-output "Could not connect to the $Destination, make sure it is correct and that your login has permissions to the server." 
Write-log -path $outputlog -message "Failed to Connect to $Destination. $_" -level Error
break
}
if($SourceServer -and ($sourceServer -ne $Destination))
{
$connStringSource = "Server=$SourceServer;Database=msdb;Integrated Security=TRUE;"
#$objServer =  new-object ('Microsoft.SqlServer.Management.Smo.Server $assemblySqlServerSmoExtendedFullName') $SourceServer
try 
{
 $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connStringSource;
        $sqlConnection.Open();
        $sqlConnection.Close();
        Write-log -path $outputlog -message "Connected to $SourceServer succesfully." -level Info
        
}
catch
{
write-output "Could not connect to the $SourceServer, make sure it is correct and that your login has permissions to the server." 
Write-log -path $outputlog -message "Failed to Connect to $SourceServer. $_" -level Error
break
}
}
#$Check_dbatools = get-module -listavailable dbatools -ErrorAction SilentlyContinue
#if(!$check_Dbatools)
#{try 
#{ install-module dbatools
#}
#catch
#{
#write-output "dbatools is not installed on this server and installation attempt failed. Kindly download and install dbatools first." 
#Write-log -path $outputlog -message "Dbatools is not installed and installation attempt failed. $_" -level Error
#break
#}
#}

$query="SELECT InstanceDefaultDataPath=case SERVERPROPERTY('InstanceDefaultDataPath') when NULL then LEFT(filename,LEN(filename)-CHARINDEX('\',REVERSE(filename))+1) else SERVERPROPERTY('InstanceDefaultDataPath') end
 from sys.sysaltfiles where dbid = 1 and fileid =1"

 $results=Invoke-Sqlcmd -ServerInstance $destination -Database master -Query $query
 [string]$DefaultFileLocation = $Results.InstanceDefaultDataPath

$query="SELECT InstanceDefaultLogPath=case SERVERPROPERTY('InstanceDefaultLogPath') when NULL then LEFT(filename,LEN(filename)-CHARINDEX('\',REVERSE(filename))+1) else SERVERPROPERTY('InstanceDefaultLogPath') end
 from sys.sysaltfiles where dbid = 1 and fileid =2"
 $results=Invoke-Sqlcmd -ServerInstance $destination -Database tempdb -Query $query

$DefaultLogLocation = $Results.InstanceDefaultLogPath


#Check restore path if exists
if ($datadirectory)
    {
    if (!(Test-SqlPath -SqlServer $destination -Path $datadirectory))
        {
         Write-output "Can't access $datadirectory Please check if The service account has permissions and that it exists."  
         $datadirectory = $DefaultFileLocation
         Write-output "Restoring on $datadirectory instead."
         Write-log -path $outputlog -message "Can't access $datadirectory restoring on $datadirectory instead. " -level Warn
         }
    }
else
    {
    $datadirectory = $DefaultFileLocation
    Write-output "restoring database files on $Datadirectory ."
    Write-log -path $outputlog -message "Restoring on $datadirectory. " -level Info
    }
if ($logdirectory)
    {
     if (!(Test-SqlPath -SqlServer $destination -Path $logdirectory))
        {
         Write-output "$Destination can't access $logdirectory. Please check if the service account has permissions and the path exists. "
         $logdirectory = $DefaultLogLocation
         Write-output "Restoring on $logdirectory instead. "
         Write-log -path $outputlog -message "Can't access $logdirectory restoring on $logdirectory instead. " -level Warn
        }
    }
else
    {
     $logdirectory = $DefaultLogLocation
     Write-output "restoring database files on $Logdirectory . "
      Write-log -path $outputlog -message "Restoring on $logdirectory. " -level Info
    }

if($AzureCredential)
{
 $BlobCredential=Get-DBACredential -SQLInstance $destination | Where-Object {$_.Identity -eq $AzureCredential} | select name
    if(!$BlobCredential)
        {
        write-output "$AzureCredential Does not Exists in $destination. Kindly Create the Credential First! URL Backups, if any, will not be restored!"
        write-log -path $outputlog -message "$AzureCredential Does not Exists in $destination. Kindly Create the Credential First! URL Backups, if any, will not be restored!" -level Warn
        }

}
if($SourceServer -and $Sourcedb -and !$Backuppath)
{
$DBparams =@("Restoretime=$RestoreTime","DBName=$sourcedb")
$FullBackup=invoke-sqlcmd -ServerInstance $sourceserver -InputFile "$Directory\get-ClosestFullBackup.sql" -Variable $DBparams
[String]$backupname=$FullBackup.physical_device_name
}
if($Backuppath)
{[string]$backupname=$backuppath}
write-log -path $outputlog -message "Full Backup File name: $backupname" -level Info
if($backupname.indexof(":") -eq 1 -and $destination -ne $SourceServer)
{
    if($SourceServer.indexOf("\") -lt 0)
                                {
                                    $backupname = "\\"+$SourceServer+ "\"+ $Backupname.Replace(":","$")
                                }
                            else
                                {
                                    $backupname = "\\"+$SourceServer.Substring(0,$SQLServer.INdexof("\")+1) + $Backupname.Replace(":","$")
                                }

}
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
                    Write-log -path $outputlog -message "Restore Filelistonly Failed. Query=$query $_.Exception.Message" -level Error
                    
                    } 
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
                    $relocate += New-Object 'Microsoft.SqlServer.Management.Smo.RelocateFile' ($dbfile.LogicalName,$newfile)
                }
 if($WithReplace)
 {
 $query="if exists (select name from sys.databases where name ='''+ $destinationdb + ''') begin alter database ['+$destinationdb+'] set offline with rollback immediate; end"
 try
 {write-log -path $outputlog -message "Executed with Replace, setting $destinationdb offline if exists on $destination." -level info
  invoke-sqlcmd -ServerInstance $destination -Database Master -query $query
 }
 catch
 { Write-log -path $outputlog -message "Could not bring existing $destinationdb offline. $_.Exception.Message" -level Error
 }
 }

 if ($backupname.Startswith('http') -eq $true)
                    {
                        try
                            {  
                            Restore-SqlDatabase -ServerInstance $destination -Database $destinationdb -BackupFile $backupname -SqlCredential $AzureCredential -RelocateFile $Relocate -ReplaceDatabase:$WithReplace -NoRecovery
                            
                           
                            }
                        catch
                           {
                             Write-log -path $outputlog -message "Restore Failed. $_.Exception.Message" -level Error
                            
                           
                           }
                     }
                else
                    {
                        try
                            {
                            Restore-SqlDatabase -ServerInstance $destination -Database $destinationdb  -BackupFile $backupname -RelocateFile $Relocate -ReplaceDatabase:$WithReplace -NoRecovery

                            }
                           catch
                           {
                            Write-log -path $outputlog -message "Restore  Failed. $_.Exception.Message" -level Error
                           }
                    }  
                    
   if(!$IgnoreLogBackup -and !$Backuppath)
   {
   $LogBackups=invoke-sqlcmd -ServerInstance $SourceServer -InputFile "$Directory\get-TLogsToRestore.sql" -Variable $DBparams
   If($LogBackups)
   {
   foreach($LogBackup in $LogBackups)
   {
   [String]$logbackupname=$LogBackup.physical_device_name
   write-log -path $outputlog "Processing $logbackupname" -level info
   if($logbackupname.indexof(":") -eq 1 -and $destination -ne $SourceServer)
                    {
                        if($SourceServer.indexOf("\") -lt 0)
                                {
                                    $logbackupname = "\\"+$SourceServer+ "\"+ $Backupname.Replace(":","$")
                                }
                            else
                                {
                                    $logbackupname = "\\"+$SourceServer.Substring(0,$SQLServer.INdexof("\")+1) + $Backupname.Replace(":","$")
                                }

                    }

   
   if ($logbackupname.Startswith('http') -eq $true)
                    {
                        try
                            {  
                            Restore-SqlDatabase -ServerInstance $destination -Database $destinationdb -BackupFile $logbackupname -SqlCredential $AzureCredential -RestoreAction Log -NoRecovery 
                            
                           
                            }
                        catch
                           {
                             Write-log -path $outputlog -message "Restore  Failed. $_.Exception.Message" -level Error
                            
                           
                           }
                     }
                else
                    {
                        try
                            {
                            Restore-SqlDatabase -ServerInstance $destination -Database $destinationdb -BackupFile $logbackupname  -RestoreAction Log  -NoRecovery

                            }
                           catch
                           {
                            Write-log -path $outputlog -message "Restore Failed. $_.Exception.Message" -level Error
                           }
                    }  
   
   }
   }
   }                              




if(!$NOrecovery)
{
$query="Restore database [$destinationdb] with Recovery;"
try
{ Invoke-Sqlcmd -ServerInstance $destination -Database tempdb -Query $query}
catch
{
Write-log -path $outputlog -message "Restore Failed. $_.Exception.Message" -level Error
}
}

}