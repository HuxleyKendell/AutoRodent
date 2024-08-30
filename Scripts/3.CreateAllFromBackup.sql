DECLARE @BackupFilePath NVARCHAR(128) = N'C:\WorkingFolders\FWD\AutoRodent\backups\AutoBackup.bak';  -- Step 1. Change me to the backup location!
DECLARE @LogicalDataFileName NVARCHAR(128) = N'AdventureWorks2016_Data';  -- Step 2. Make these match the original DB! Psst, you can use 2.FindLogicalPaths.sql
DECLARE @LogicalLogFileName NVARCHAR(128) = N'AdventureWorks2016_Log';  -- Step 2. Make these match the original DB! Psst, you can use 2.FindLogicalPaths.sql
DECLARE @DataFilePath NVARCHAR(260);  -- Declare a variable to hold the data file path
DECLARE @LogFilePath NVARCHAR(260);  -- Declare a variable to hold the log file path
DECLARE @DatabaseName NVARCHAR(128);  -- Declare a variable to hold the current database name

-- Attempts to Auto Find the Paths to the logical files!
DECLARE @mdfLocation NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(200));  -- Get the default data file path
DECLARE @ldfLocation NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(200));  -- Get the default log file path

DECLARE @mySQL NVARCHAR(MAX);  -- Declare a variable to hold SQL commands

DECLARE @DatabaseList TABLE (  -- Create a table variable to hold the list of databases
    DatabaseName NVARCHAR(128)
);

-- Insert the database names into the table variable
INSERT INTO @DatabaseList (DatabaseName)
VALUES ('AutoPilotDev'), ('AutoPilotTest'), ('AutoPilotProd'), ('AutoPilotShadow'), ('AutoPilotBuild'), ('AutoPilotCheck');

DECLARE @Counter INT = 1;  -- Initialize a counter for the loop
DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @DatabaseList);  -- Get the total count of databases

-- Loop through each database in the list
WHILE @Counter <= @TotalCount
BEGIN
    -- Get the current database name based on the counter
    SET @DatabaseName = (SELECT DatabaseName FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY DatabaseName) AS RowNum, DatabaseName 
        FROM @DatabaseList
    ) AS TempDB
    WHERE TempDB.RowNum = @Counter);

    -- Define file paths for the current database
    SET @DataFilePath = @mdfLocation + @DatabaseName + '_Data.mdf';
    SET @LogFilePath = @ldfLocation + @DatabaseName + '_Log.ldf';

    -- Use master database
    USE [master];

    -- Check if the database already exists, and if it does, drop it
    IF EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        -- Try to set the database to single-user mode and drop it
        BEGIN TRY
            SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
            EXEC sp_executesql @mySQL;
            SET @mySQL = N'DROP DATABASE [' + @DatabaseName + '];';
            EXEC sp_executesql @mySQL;
        END TRY
        BEGIN CATCH
            PRINT 'Error occurred while altering or dropping the existing database ' + @DatabaseName;
            PRINT ERROR_MESSAGE();
            RETURN;
        END CATCH
    END

    -- Restore the database from the backup with unique logical file names
    BEGIN TRY
        SET @mySQL = N'RESTORE DATABASE [' + @DatabaseName + ']
        FROM DISK = ''' + @BackupFilePath + '''
        WITH REPLACE,
        MOVE ''' + @LogicalDataFileName + ''' TO ''' + @DataFilePath + ''',
        MOVE ''' + @LogicalLogFileName + ''' TO ''' + @LogFilePath + ''';';
        EXEC sp_executesql @mySQL;

        -- Put the database back in multi-user mode and set it to READ_WRITE
        SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET MULTI_USER;';
        EXEC sp_executesql @mySQL;
        SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET READ_WRITE;';
        EXEC sp_executesql @mySQL;
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred during the restore operation for database ' + @DatabaseName;
        PRINT ERROR_MESSAGE();
        RETURN;
    END CATCH

    SET @Counter = @Counter + 1;  -- Increment the counter
END
