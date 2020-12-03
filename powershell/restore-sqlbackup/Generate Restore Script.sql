/*
Generate Restore Script based on msdb backup history upto point in time.
Please note that the script does not do error handling for input. 
i.e. 
if you know you'll have url backups, you'll need to provide the @AzureCredential;
it does not check if the Credential exists on your destination server.
It does not check if the destination path exists, if you need to move the files you'll have to provide both @datapath and @logpath.
It does not check if the destination db exists, if it does, and you want to replace it, you have to set @WithReplace bit
It does not check if the backup path is accessible from the destination server.
if you need to leave the db in Recovery, you'll need to specify @NoRecovery

Important NOTE: Review the generated script for correctness and adjust accordingly before executing. 

Set the paramters on the SET Parameters Section.

*/
declare @databaseName sysname  -- This is the database name to check the backups and generate the restore script for. IF You want to use a different database name on the destination, set @RestoreasDBName.
declare @RestoreasDBName sysname-- This will be the db name of the restored database. Set this if you want a different db name.
declare @IncludeTlogs bit -- set this bit if you want to include tlog backups. 
declare @stopat datetime  -- this is the Restore point in time objective. If @IncludeTlogs = 0 the script will only look for the nearest full backup.
declare @datapath varchar(max) -- Set this if you want to move the database files to a different location in the destination server. Both @datapath and @logpath needs to be set if you want to move the files. Else it will reuse the original location.
declare @logpath varchar(max) -- Set this if you want to move the database files to a different location in the destination server. Both @datapath and @logpath needs to be set if you want to move the files. Else it will reuse the original location.
declare @WithReplace bit -- Set this bit to 1 if you want to replace the existing database with the same name at the destination server. Default is NOREPLACE
declare @Norecovery  bit -- Set this bit if you want to leave the database in Norecovery. Default is to fully recover the db at the end of the restore.
declare @AzureCredential varchar(500) -- This is the Credential with the secret key for URL backups. You need to create this in the destination server before executing the restore.
declare @FullBackupStartDate datetime

/*SET the parameters section, replace with your requirements*/
set @stopat =  'June 18, 2018 20:35:52'
set @databaseName = 'SalesExec_41443'
set @RestoreasDBName='SalesExec_41443_086E1A70_20180618T203552'--@databaseName
set @AzureCredential ='uwsesqlbackups'
set @WithReplace=1
set @Norecovery= 0
set @IncludeTlogs=1
set @datapath='f:\sqldata'
set @logpath='F:\sqldata'
/*End of SET the parameters section*/

declare @backup_set_id_start bigint
DECLARE @backup_set_id_end INT 

SELECT @backup_set_id_start = MAX(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @databaseName AND type = 'D' 
and backup_start_date < @stopat

set @FullBackupStartDate = (select backup_start_date from msdb.dbo.backupset where backup_set_id = @backup_set_id_start and [type]='D')

SELECT @backup_set_id_end = MIN(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @databaseName AND type = 'L' 
AND backup_set_id > @backup_set_id_start 
and backup_start_date > @stopat

create table #temp_restore_command (id int identity (1,1), command varchar(max))

IF @backup_set_id_end IS NULL SET @backup_set_id_end = 999999999 
if @WithReplace=1
BEGIN
insert into #temp_restore_command values  ('if exists (select name from sys.databases where name ='''+ @RestoreasDBName + ''') begin alter database ['+@RestoreasDBName+'] set offline with rollback immediate; end')
end
insert into #temp_restore_command values ('USE [master]')
insert into #temp_restore_command
select case mf.device_type
when 2 then 'RESTORE DATABASE [' + @RestoreasDBName + '] FROM DISK = ''' 
+ mf.physical_device_name + '''  WITH ' 
when 9 then 'RESTORE DATABASE [' + @RestoreasDBName + '] FROM URL = ''' 
+ mf.physical_device_name + '''  WITH Credential=''' + @AzureCredential + ''','
when 5 then 'RESTORE DATABASE [' + @RestoreasDBName + '] FROM TAPE = ''' 
+ mf.physical_device_name + '''  WITH ' 
end
FROM msdb.dbo.backupset b, 
msdb.dbo.backupmediafamily mf 
WHERE b.media_set_id = mf.media_set_id 
AND b.database_name = @databaseName 
AND b.backup_set_id = @backup_set_id_start 

if @datapath is not null and @logpath is not null
begin
if right(@datapath,1)<>'\' set @datapath=@datapath+'\'
if right(@logpath,1)<>'\' set @logpath=@logpath+'\'
insert into #temp_restore_command
select 'move '''+name+''' to '''+@datapath + replace(@RestoreasDBName,' ','_') + Right(filename,CHARINDEX('\',REVERSE(filename))-len(@databasename)-1) + ''',' from sys.sysaltfiles where dbid = db_id(@databasename) and filename not like '%ldf'
union all 
select 'move '''+name+''' to '''+@logpath+ replace(@RestoreasDBName,' ','_') +Right(filename,CHARINDEX('\',REVERSE(filename))-len(@databasename)-1) + ''',' from sys.sysaltfiles where dbid = db_id(@databasename) and filename like '%ldf'
end

if @WithReplace=1
Begin
insert into #temp_restore_command values (' REPLACE, NORECOVERY')
end
else
Begin
insert into #temp_restore_command values ('NORECOVERY')
end

if @IncludeTlogs=1
Begin
insert into #temp_restore_command
select case mf.device_type
when 2 then 'RESTORE DATABASE [' + @RestoreasDBName + '] FROM DISK = ''' 
+ mf.physical_device_name + ''' WITH NORECOVERY' 
when 9 then 'RESTORE DATABASE [' + @RestoreasDBName + '] FROM URL = ''' 
+ mf.physical_device_name + ''' WITH Credential=''' + @AzureCredential + ''',  NORECOVERY'
when 5 then 'RESTORE DATABASE [' + @RestoreasDBName + '] FROM TAPE = ''' 
+ mf.physical_device_name + ''' WITH  NORECOVERY' 
end
FROM msdb.dbo.backupset b, 
msdb.dbo.backupmediafamily mf 
WHERE b.media_set_id = mf.media_set_id 
AND b.database_name = @databaseName 
--AND b.backup_set_id >= @backup_set_id_start AND b.backup_set_id < @backup_set_id_end 
AND b.backup_start_date >= @FullBackupStartDate
AND b.backup_set_id < @backup_set_id_end 
AND b.type = 'L' 
ORDER BY backup_set_id
End

if @NoRecovery=0
Begin
insert into #temp_restore_command values('RESTORE DATABASE [' + @RestoreasDBName + '] with Recovery')
end

select Command from #temp_restore_command order by id asc
drop table #temp_restore_command
