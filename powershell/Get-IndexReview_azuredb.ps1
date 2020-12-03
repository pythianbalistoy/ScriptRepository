function Invoke-SQL {
    param(
        [string] $dataSource,
        [string] $database ,
        [string] $uid,
        [string] $pwd,
        [string] $sqlCommand = $(throw "Please specify a query.")
      )
    $connectionString = "Data Source=$dataSource; User ID =$uid;Password =$pwd; Initial Catalog=$database;" 
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $connection.Close()
    $dataSet.Tables
}
        [string] $dataSource = "tcp:uw-se-sqldw.database.windows.net,1433"
        [string] $database = "Master"
        [string] $uid="****************"
        [string] $pwd="****************"
        [string] $sqlCommand = "Select name from sys.databases where name <> 'master'"
        $count = 0
      
  $dataset = Invoke-SQL $dataSource $database $uid $pwd $sqlcommand
  
  
  $UnusedIndexes =@()
  $MIssingIndexes = @()
  $ContentionIndexes = @()
  $FragmentedIndexes = @()
  $PageLOckDisabledIndexes = @()

    ForEach ($Dbrow in $dataset.name)
    {
    #get costly unused indexes
    $database = $Dbrow
    $sqlcommand = "SELECT TOP 10    
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates    
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
ORDER BY user_updates DESC;
"
    $unusedINdexes += Invoke-SQL $dataSource $database $uid $pwd $sqlcommand

#Get missing index
    $sqlcommand = "SELECT  TOP 10 
        [DatabaseName]=db_name() ,
		[Total Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
        , avg_user_impact
        , TableName = statement
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [Include Cloumns] = included_columns
FROM        sys.dm_db_missing_index_groups g 
INNER JOIN    sys.dm_db_missing_index_group_stats s 
       ON s.group_handle = g.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details d 
       ON d.index_handle = g.index_handle
ORDER BY [Total Cost] DESC;
"

  $MissingIndexes += Invoke-SQL $dataSource $database $uid $pwd $sqlcommand

  #Get Index with High contentions
    $sqlcommand = "select top 10 
db_name() [DatabaseName]
, objectname=object_name(s.object_id)
	, indexname=i.name, i.index_id	--, partition_number
	, row_lock_count, row_lock_wait_count
	, [block %]=cast (100.0 * row_lock_wait_count / (1 + row_lock_count) as numeric(15,2))
	, row_lock_wait_in_ms
	, [avg row lock waits in ms]=cast (1.0 * row_lock_wait_in_ms / (1 + row_lock_wait_count) as numeric(15,2))

from sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) s
	,sys.indexes i
where objectproperty(s.object_id,'IsUserTable') = 1
and i.object_id = s.object_id
and i.index_id = s.index_id
and row_lock_wait_count > 0
order by row_lock_wait_count desc
"

  $ContentionIndexes += Invoke-SQL $dataSource $database $uid $pwd $sqlcommand

   #Get fragmented indexes
    $sqlcommand = "SELECT 
        db_name() [Database_Name]
		,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
FROM sys.dm_db_index_physical_stats(null, null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
	and avg_fragmentation_in_percent > 30
	and page_count > 100
ORDER BY [Fragmentation %] DESC
"

  $FragmentedIndexes += Invoke-SQL $dataSource $database $uid $pwd $sqlcommand

  
   #Get fragmented indexes
    $sqlcommand = "select  db_name() [Database_Name]
		,TableName = OBJECT_NAME([object_id])
        ,IndexName = name from sys.indexes where allow_page_locks = 0
"

  $PageLOckDisabledIndexes += Invoke-SQL $dataSource $database $uid $pwd $sqlcommand

    }
    $unusedIndexes | export-csv C:\Pythian\Unused_Indexes.csv
    $MIssingIndexes | export-csv C:\Pythian\Missing_Indexes.csv
  $ContentionIndexes | export-csv C:\Pythian\Indexes_With_Contention.csv
  $FragmentedIndexes | export-csv C:\Pythian\Fragmented_Indexes.csv
  $PageLOckDisabledIndexes | export-csv C:\Pythian\Indexes_With_PageLockDisabled.csv