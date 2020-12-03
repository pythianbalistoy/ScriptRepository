declare @databaseName sysname
declare @IncludeTlogs bit
declare @stopat datetime

set @stopat = '$(RestoreTime)'
set @databaseName = '$(DBName)'

declare @backup_set_id_start bigint
DECLARE @backup_set_id_end INT 

SELECT @backup_set_id_start = MAX(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @databaseName AND type = 'D' 
and backup_start_date < @stopat

SELECT @backup_set_id_end = MIN(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @databaseName AND type = 'L' 
AND backup_set_id > @backup_set_id_start 
and backup_start_date > @stopat

IF @backup_set_id_end IS NULL SET @backup_set_id_end = 999999999 

select  mf.physical_device_name
FROM msdb.dbo.backupset b, 
msdb.dbo.backupmediafamily mf 
WHERE b.media_set_id = mf.media_set_id 
AND b.database_name = @databaseName 
AND b.backup_set_id = @backup_set_id_start 
