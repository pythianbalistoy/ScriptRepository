function Invoke-SQL {
    param(
        [string] $dataSource,
        [string] $database ,
        [string] $uid,
        [string] $pwd,
        [string] $sqlCommand = $(throw "Please specify a query.")
      )
if (!$uid)
{$connectionString = "Data Source=$dataSource;Initial Catalog=$database;Integrated Security=SSPI;"}
else
    {$connectionString = "Data Source=$dataSource; User ID =$uid;Password =$pwd; Initial Catalog=$database;" }
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $connection.Close()
    $dataSet.Tables[0]
}
   
  

$PrimaryServer='dent-p-sqlcl01'
$SecondaryServer= 'dent-p-sqlcl02'

        [string] $dataSource = $primaryServer
        [string] $database = "Master"
        [string] $sqlCommand = "select name,SID=Substring(( MASTER.dbo.Fn_varbintohexstr(SID) ), 1, 2) +Substring(Upper(MASTER.dbo.Fn_varbintohexstr(SID)), 3, 8000),type,is_disabled,create_date, default_database_name, default_language_name from sys.server_principals where name not like '##M%' and name not like 'NT Authority%' and name not like 'NT SERVICE%' and type not in  ('r','c','k');
"
        $count = 0
try {
$logins1 = Invoke-SQL $dataSource $database $uid $pwd $sqlcommand
}
catch
{
write-output "Query Failed on $PrimaryServer. $_.ExceptionMessage"
break
}
try {
[string] $dataSource = $SecondaryServer
$Logins2= Invoke-SQL $dataSource $database $uid $pwd $sqlcommand
}
catch
{
write-output "Query Failed on $SecondaryyServer. $_.ExceptionMessage"
break
}
if ($Logins1 -and $Logins2)
{
write-output "The following logins are not existing on both servers. 
Note: 
<= means it is only at $primaryserver
=> means it is only at $Secondaryserver"

Compare-object $logins1 $logins2 -Property "name" -passthru | select-object sideindicator, name , create_date


$existing1= $Logins1 | where-object {$Logins2.name -contains $_.name}
$existing2 = $Logins2 |  where-object {$Logins1.name -contains $_.name}


$tabname= "sidissues"
$table=New-Object system.Data.DataTable “$tabName”
$col1 = New-Object system.Data.DataColumn Name,([string])
$col2 = New-Object system.Data.DataColumn PrimarySID,([string])
$col3 = New-Object system.Data.DataColumn SecondarySID,([string])
$col4 = New-Object system.Data.DataColumn type,([string])

$null=$table.columns.add($col1)
$null=$table.columns.add($col2)
$null=$table.columns.add($col3)
$null=$table.columns.add($col4)



write-output "The following logins does not have the same SID on both servers."

foreach ($login in $existing1)
{ $checking = $existing2 | where-object {$_.name -eq $Login.name}

  if($checking.sid -ne $Login.sid)
    {$Rowadding=$table.rows.add($login.name,$login.sid,$checking.sid,$login.type)}
}
$table | ft
}
else
{ if(!$Logins1){write-output "No logins found for $PrimaryServer!"}
else{write-output "No logins found for $SecondaryServer!"}
}