DECLARE @BackupFilePath NVARCHAR(128) = N'C:\WorkingFolders\FWD\AutoRodent\backups\AutoBackup.bak'  -- Step 1. Change me to the backup location!
DECLARE @LogicalDataFileName NVARCHAR(128) = N'AdventureWorks2016_Data'  -- Step 2. Make these match the original DB! Psst, you can use 2.FindLogicalPaths.sql
DECLARE @LogicalLogFileName NVARCHAR(128) = N'AdventureWorks2016_Log'  -- Step 2. Make these match the original DB! Psst, you can use 2.FindLogicalPaths.sql
DECLARE @DataFilePath NVARCHAR(260)
DECLARE @LogFilePath NVARCHAR(260)
DECLARE @DatabaseName NVARCHAR(128)
-- Attempts to Auto Find the Paths to the logical files!
DECLARE @mdfLocation nvarchar(256) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(200));
DECLARE @ldfLocation nvarchar(256) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS nvarchar(200));

DECLARE @mySQL NVARCHAR(MAX)  -- Declare @mySQL once at the beginning

DECLARE @DatabaseList TABLE (
    DatabaseName NVARCHAR(128)
)

INSERT INTO @DatabaseList (DatabaseName)
VALUES ('AutoPilotDev'), ('AutoPilotTest'), ('AutoPilotStaging'), ('AutoPilotProd'), ('AutoPilotShadow'), ('AutoPilotBuild'), ('AutoPilotCheck')

DECLARE @Counter INT = 1
DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @DatabaseList)

WHILE @Counter <= @TotalCount
BEGIN
    SET @DatabaseName = (SELECT DatabaseName FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY DatabaseName) AS RowNum, DatabaseName 
        FROM @DatabaseList
    ) AS TempDB
    WHERE TempDB.RowNum = @Counter)

    -- Define file paths for current database


    SET @DataFilePath = @mdfLocation + @DatabaseName + '_Data.mdf'
	SET @LogFilePath = @ldfLocation + @DatabaseName + '_Log.ldf'

    -- Use master database
    USE [master]

    -- Check if the database already exists, and if it does, drop it
    IF EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        -- Try to set the database to single-user mode and drop it
        BEGIN TRY
            SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'
            EXEC sp_executesql @mySQL
            SET @mySQL = N'DROP DATABASE [' + @DatabaseName + '];'
            EXEC sp_executesql @mySQL
        END TRY
        BEGIN CATCH
            PRINT 'Error occurred while altering or dropping the existing database ' + @DatabaseName
            PRINT ERROR_MESSAGE()
            RETURN
        END CATCH
    END

    -- Restore the database from the backup with unique logical file names
    BEGIN TRY
        SET @mySQL = N'RESTORE DATABASE [' + @DatabaseName + ']
        FROM DISK = ''' + @BackupFilePath + '''
        WITH REPLACE,
        MOVE ''' + @LogicalDataFileName + ''' TO ''' + @DataFilePath + ''',
        MOVE ''' + @LogicalLogFileName + ''' TO ''' + @LogFilePath + ''';'
        EXEC sp_executesql @mySQL

        -- Put the database back in multi_user mode and set it to READ_WRITE
        SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET MULTI_USER;'
        EXEC sp_executesql @mySQL
        SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET READ_WRITE;'
        EXEC sp_executesql @mySQL
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred during the restore operation for database ' + @DatabaseName
        PRINT ERROR_MESSAGE()
        RETURN
    END CATCH

    SET @Counter = @Counter + 1
END