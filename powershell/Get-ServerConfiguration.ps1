function Get-SQLServerConfigReport {
param([string]$SqlInstance)
$Directory=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\")
$Directory=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\")
$htmlreport = @()
$htmlbody = @()
$htmlfile = "$ClientName-BestPractice_Review-$($ComputerName).html"
$spacer = "<br />"
$DocDate=Get-Date -DisplayHint Date
$csinfo = Get-WmiObject Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object Name,Manufacturer,Model,
                            @{Name='Physical Processors';Expression={$_.NumberOfProcessors}},
                            @{Name='Logical Processors';Expression={$_.NumberOfLogicalProcessors}},
                            @{Name='Total Physical Memory (Gb)';Expression={
                                $tpm = $_.TotalPhysicalMemory/1GB;
                                "{0:F0}" -f $tpm
                            }},
                            DnsHostName,Domain
$osinfo= get-wmiobject Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop | Select-object Description,Caption,OSArchitecture,ServicePackMajorVersion
cd $Directory
$SQLServer =  new-object ('Microsoft.SqlServer.Management.Smo.Server') $SQLInstance -ErrorAction Stop
$SQLInfo =  new-object ('Microsoft.SqlServer.Management.Smo.Server') $SQLInstance -ErrorAction Stop | select Name,Version,Edition,IsClustered,ClusterName,LoginMode,FilestreamLevel,ServiceAccount,BrowserServiceAccount,InstallDataDirectory,InstallSharedDirectory,ErrorLogPath,MasterDBLogPath,MasterDBPath,DefaultFile,DefaultLog,BackupDirectory,RootDirectory        

$query= "select ServiceName,startup_type_desc as [StartUpMode],Status_desc as [Status], Service_account, last_startup_time,Is_Clustered, Cluster_NodeName, instant_file_initialization_enabled from sys.dm_server_services"
try
{
$Services=Invoke-sqlcmd -sqlInstance $SqlInstance -database master -query $query
}
catch
{write-output $_
}
$SQLVolumes=@()
$SystemData=$SQLServer.MasterDBPath.Substring(0,3)
$SystemLogs=$SQLServer.MasterDBPath.Substring(0,3)
$DefaultData=$SQLServer.DefaultFile.Substring(0,3)
$DefaultLog=$SQLServer.DefaultLog.Substring(0,3)
if($Systemdata){$SQLVolumes+=$Systemdata}
if ($SystemData -ne $SystemLogs -and $Systemlogs){$SQlVolumes+=$SystemLogs}
if($SystemData -ne $DefaultData){$SQlVolumes+=$DefaultData}
if($DefaultData -ne $DefaulLog){$SQlVolumes+=$DefaultLog}

$SQLConfiguration=$SQLServer.Configuration
$SQLTraceFlags=$SQLServer.EnumActiveGlobalTraceFlags()
$wql = "SELECT Label, Blocksize, Name, Capacity, Freespace FROM Win32_Volume WHERE FileSystem='NTFS'"
$DiskStorage=Get-WmiObject -Query $wql -ComputerName $ComputerName | Select-Object Label, Blocksize, Name, Capacity, Freespace




}


