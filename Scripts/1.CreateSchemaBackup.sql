-- Variables for source and cloned database names
DECLARE @SourceDB NVARCHAR(128) = N'AutoPilotDev'; -- Step 1. Change me to the DB name you wish to use!
DECLARE @BackupDB NVARCHAR(128) = @SourceDB + N'_Schema';

-- Clone the source database schema only
DBCC CLONEDATABASE (@SourceDB, @BackupDB) WITH NO_STATISTICS, NO_QUERYSTORE, VERIFY_CLONEDB;

-- Backup the cloned database
DECLARE @BackupPath NVARCHAR(256) = N'C:\WorkingFolders\FWD\AutoRodent\backups\AutoBackup.bak';  -- Step 2. Change me to match the location of Flyway Project

-- Construct the BACKUP DATABASE command
DECLARE @BackupCommand NVARCHAR(MAX) = 
    N'BACKUP DATABASE [' + @BackupDB + N'] TO DISK = ''' + @BackupPath + N''' WITH INIT, FORMAT, MEDIANAME = ''SQLServerBackups'', NAME = ''Full Backup of ' + @BackupDB + N''';';

-- Execute the BACKUP DATABASE command
EXEC sp_executesql @BackupCommand;

-- Drop Schema Database If Exists
DECLARE @drop nvarchar(100);
DECLARE @Result NVARCHAR(200);
SET @drop = 'DROP DATABASE IF EXISTS'
SET @Result = (@drop+ ' '+@BackupDB)
EXEC sp_executesql @Result