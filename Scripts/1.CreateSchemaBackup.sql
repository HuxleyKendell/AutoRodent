-- Variables for source and cloned database names
DECLARE @SourceDB NVARCHAR(128) = N'AutoPilotDev'; -- Step 1. Change me to the DB name you wish to use!
DECLARE @BackupDB NVARCHAR(128) = @SourceDB + N'_Schema'; -- Define the cloned database name by appending '_Schema' to the source DB name

-- Clone the source database schema only
DBCC CLONEDATABASE (@SourceDB, @BackupDB) WITH NO_STATISTICS, NO_QUERYSTORE, VERIFY_CLONEDB; -- Clone the source database schema without statistics and Query Store

-- Backup the cloned database
DECLARE @BackupPath NVARCHAR(256) = N'C:\WorkingFolders\FWD\AutoRodent\backups\AutoBackup_Customer.bak';  -- Step 2. Change me to match the location of Flyway Project

-- Construct the BACKUP DATABASE command
DECLARE @BackupCommand NVARCHAR(MAX) = 
    N'BACKUP DATABASE [' + @BackupDB + N'] TO DISK = ''' + @BackupPath + N''' WITH INIT, FORMAT, MEDIANAME = ''SQLServerBackups'', NAME = ''Full Backup of ' + @BackupDB + N''';'; -- Construct the command to backup the cloned database

-- Execute the BACKUP DATABASE command
EXEC sp_executesql @BackupCommand; -- Execute the constructed backup command

-- Drop Schema Database If Exists
DECLARE @drop NVARCHAR(100); -- Declare a variable to hold the drop database command
DECLARE @Result NVARCHAR(200); -- Declare a variable to hold the full drop database command with the database name
SET @drop = 'DROP DATABASE IF EXISTS'; -- Set the drop command
SET @Result = (@drop + ' ' + @BackupDB); -- Combine the drop command with the cloned database name
EXEC sp_executesql @Result; -- Execute the drop database command
