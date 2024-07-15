DECLARE @BackupFilePath NVARCHAR(128) = N'C:\Users\redgate\Desktop\Aardvark\backups\widget.bak'
DECLARE @LogicalDataFileName NVARCHAR(128) = N'aardvark_prod'
DECLARE @LogicalLogFileName NVARCHAR(128) = N'aardvark_prod_log'
DECLARE @DataFilePath NVARCHAR(260)
DECLARE @LogFilePath NVARCHAR(260)
DECLARE @DatabaseName NVARCHAR(128)

DECLARE @DatabaseList TABLE (
    DatabaseName NVARCHAR(128)
)

INSERT INTO @DatabaseList (DatabaseName)
VALUES ('AutoPilotDev'), ('AutoPilotTest'), ('AutoPilotStaging'), ('AutoPilotProd'), ('AutoPilotShadow'), ('AutoPilotBuild'), ('AutoPilotCheck')

DECLARE @Counter INT = 1
DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @DatabaseList)

WHILE @Counter <= @TotalCount
BEGIN
    SET @DatabaseName = (SELECT DatabaseName FROM @DatabaseList WHERE DatabaseName = 'AutoPilotDev')

    -- Define file paths for current database
    SET @DataFilePath = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\' + @DatabaseName + '_Data.mdf'
    SET @LogFilePath = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\' + @DatabaseName + '_Log.ldf'

    -- Use master database
    USE [master]

    -- Check if the database already exists, and if it does, drop it
    IF EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        -- Try to set the database to single-user mode and drop it
        BEGIN TRY
            DECLARE @mySQL NVARCHAR(MAX)
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
        DECLARE @mySQL NVARCHAR(MAX)
        SET @mySQL = N'RESTORE DATABASE [' + @DatabaseName + ']
        FROM DISK = ''' + @BackupFilePath + '''
        WITH REPLACE,
        MOVE ''' + @LogicalDataFileName + ''' TO ''' + @DataFilePath + ''',
        MOVE ''' + @LogicalLogFileName + ''' TO ''' + @LogFilePath + ''';'
        EXEC sp_executesql @mySQL

        -- Put the database back in multi_user mode
        SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET MULTI_USER;'
        EXEC sp_executesql @mySQL
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred during the restore operation for database ' + @DatabaseName
        PRINT ERROR_MESSAGE()
        RETURN
    END CATCH

    SET @Counter = @Counter + 1
END
