-- flyway:executeInTransaction=false
DECLARE @BackupFilePath NVARCHAR(128) = N'${flyway:workingDirectory}\backups\widget.bak';
DECLARE @DatabaseName NVARCHAR(128) = N'${flyway:database}';
DECLARE @LogicalDataFileName NVARCHAR(128)
DECLARE @LogicalLogFileName NVARCHAR(128)
DECLARE @DataFilePath NVARCHAR(260)
DECLARE @LogFilePath NVARCHAR(260)
DECLARE @mySQL NVARCHAR(MAX)
-- Use master database
USE [master]
-- Define logical file names and paths based on the database name
SET @LogicalDataFileName = 'aardvark_prod'
SET @LogicalLogFileName = 'aardvark_prod_log'
SET @DataFilePath = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\' + @DatabaseName + '_Data.mdf'
SET @LogFilePath = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\' + @DatabaseName + '_Log.ldf'
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
    -- Put the database back in multi_user mode
    SET @mySQL = N'ALTER DATABASE [' + @DatabaseName + '] SET MULTI_USER;'
    EXEC sp_executesql @mySQL
END TRY
BEGIN CATCH
    PRINT 'Error occurred during the restore operation for database ' + @DatabaseName
    PRINT ERROR_MESSAGE()
    RETURN
END CATCH
-- Create the Flyway schema history table
BEGIN
USE [${flyway:database}]
    CREATE TABLE [dbo].[flyway_schema_history](
	[installed_rank] [INT] NOT NULL,
	[version] [NVARCHAR](50) NULL,
	[description] [NVARCHAR](200) NULL,
	[type] [NVARCHAR](20) NOT NULL,
	[script] [NVARCHAR](1000) NOT NULL,
	[checksum] [INT] NULL,
	[installed_by] [NVARCHAR](100) NOT NULL,
	[installed_on] [DATETIME] NOT NULL,
	[execution_time] [INT] NOT NULL,
	[success] [BIT] NOT NULL,
 CONSTRAINT [flyway_schema_history_pk] PRIMARY KEY CLUSTERED 
(
	[installed_rank] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END

ALTER TABLE [dbo].[flyway_schema_history] ADD  DEFAULT (GETDATE()) FOR [installed_on]

USE [${flyway:database}]