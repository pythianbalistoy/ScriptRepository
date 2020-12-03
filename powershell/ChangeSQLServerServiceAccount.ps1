$Serverlistfile= "C:\powershell\servers.txt"
$servers= get-content -path ($Serverlistfile)
write-output "Applying to servers listed in $Serverlistfile"
foreach($server in $servers)
{
$NewServiceAccount='.\TestServiceAccount'
$NewPassword = ""
$services = get-wmiObject win32_service -computername $server | ?{($_.name -like 'MSSQLSERVER' -or $_.Name -like 'MSSQL$*' -or $_.Name -like 'SQLSERVERAGENT' -or $_.Name -like 'SQLAGENT*') -and $_.StartMode -notlike 'Disabled' }  | sort-object $_.Name -Descending

$tabname= "Services"
$table=New-Object system.Data.DataTable “$tabName”
$col1 = New-Object system.Data.DataColumn ServerName,([string])
$col2 = New-Object system.Data.DataColumn ServiceName,([string])
$col3 = New-Object system.Data.DataColumn OldServiceAccount,([string])
$col4 = New-Object system.Data.DataColumn PreviousStatus,([string])
$col5 = New-Object system.Data.DataColumn CurrentServiceAccount,([string])
$col6 = New-Object system.Data.DataColumn CurrentStatus,([string])
$col7 = New-Object system.Data.DataColumn Comment,([string])

$table.columns.add($col1)
$table.columns.add($col2)
$table.columns.add($col3)
$table.columns.add($col4)
$table.columns.add($col5)
$table.columns.add($col6)
$table.columns.add($col7)

$Servicescount=$services.count
write-output "Processing server $server"
write-output " $Servicescount enabled and running sql-related services found."
foreach($service in $Services)
{
$RestartAttempted = $null
$returncode=$null
$StartService=$null
$StopService=$null
$comment=$null

$StartMode= $Service.properties  | where-object {$_.Name -eq 'StartMode'} | SELECT -EXPANDPROPERTY VALUE 
$ServiceName= $Service.properties  | where-object {$_.Name -eq 'Name'} | SELECT -EXPANDPROPERTY VALUE 
$ServiceAccount = $Service.properties | where-object {$_.Name -eq 'StartName'} | select -EXPANDPROPERTY value
$PreviousStatus = $Service.properties | where-object {$_.Name -eq 'State'} | select -EXPANDPROPERTY value
try
{
$changePassword = $service.change($null,$null,$null,$null,$null,$null,$NewServiceAccount,$NewPassword,$null, $null, $null)
$returncode = $ChangePassword.returnvalue
start-sleep -s 5
if($ChangePassword.returnvalue -eq 0)
{write-output "Service Account changed from $ServiceAccount to $NewServiceAccount for $ServiceName on $Server"}
else
{write-output "Failed to change Service Account from $ServiceAccount to $NewServiceAccount for $ServiceName on $Server. Return Code: $returncode. Check on https://docs.microsoft.com/en-us/windows/desktop/cimwin32prov/change-method-in-class-win32-service for the error definition."}

}
catch
{
Write-Output  "Service Account changed failed for $ServiceName on $Server with error $_.Exception.Message"
}
##Restart the Service if it was running and set to Auto when we changed the sql service account. We're not restarting those in Manual
if ($changePassword.ReturnValue -eq 0 -and $PreviousStatus -eq 'Running' -and $StartMode -eq 'Auto')
{
try
{
$RestartAttempted = 1
Write-Output  "Stopping the service..."
$StopService=$Service.StopService()
start-sleep -s 5
$StopService.ReturnValue 

}
catch
{
write-output "Stopping the service $ServiceName on $Server failed. $_.ExceptionMessage"
}
if($StopService.ReturnValue -eq 0)
{
try 
{
Write-Output  "Starting the service..."
$StartService = $Service.StartService()
start-sleep -s 15
$StartService.ReturnValue
}
catch
{
write-output "Starting the service $ServiceName on $Server failed. $_.ExceptionMessage"
}
}
}
if($returncode -eq 0 -and $RestartAttempted -eq 1 -and ($stopservice.returnvalue -eq 0 -and $startservice.returnvalue -eq 0))
{$comment= "Changed and restarted successfully."}
if($returncode -eq 0 -and $StartMode -eq  'Manual')
{$comment= "Changed Successfull pending restart. Service is set to manual. Kindly check and restart if needed."}
if($returncode -ne 0)
{$Comment="Account Change failed with return code $returcode.  Check on https://docs.microsoft.com/en-us/windows/desktop/cimwin32prov/change-method-in-class-win32-service for the error definition."}
if($returncode -eq 0 -and $RestartAttempted -eq 1 -and ($stopservice.returnvalue -ne 0 -or $Startservice.returnvalue -ne 0))
{$Comment= "Account Changed but restart failed. Kindly Check."}
$CurrentServiceAccount = $Service.properties | where-object {$_.Name -eq 'StartName'} | select -EXPANDPROPERTY value
$CurrentStatus = $Service.properties | where-object {$_.Name -eq 'State'} | select -EXPANDPROPERTY value
$Rowadding=$table.rows.add($Server,$ServiceName,$ServiceAccount,$PreviousStatus,$CurrentServiceAccount,$CurrentStatus, $Comment)

}
}
$table | ft


