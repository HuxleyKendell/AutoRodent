#SQLSERVER MODULE NEEDED

if (!(Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "SqlServer module not found. Installing module..."
    
    # Install the SqlServer module
    Install-Module -Name SqlServer -Force -AllowClobber
    Write-Host "SqlServer module installed successfully."
} else {
    Write-Host "SqlServer module is already installed."
}


# Prompt for input
$sourceDB = Read-Host "Enter the source database name (e.g., AutoPilotDev)"
$backupDir = Read-Host "Enter the backup directory path (e.g., C:\WorkingFolders\FWD\AutoPilot\backups)" #maybe do just project
$serverName = Read-Host "Enter the SQL Server name"
$backupFileName = "AutoBackup_$sourceDB.bak"  # Backup file naming convention
$backupPath = Join-Path $backupDir $backupFileName

# Step 1: Run the first script to create the schema backup
$sqlCreateBackup = @"
DECLARE @SourceDB NVARCHAR(128) = N'$sourceDB';
DECLARE @BackupDB NVARCHAR(128) = @SourceDB + N'_Schema';
DECLARE @BackupPath NVARCHAR(256) = N'$backupPath';

DBCC CLONEDATABASE (@SourceDB, @BackupDB) WITH NO_STATISTICS, NO_QUERYSTORE, VERIFY_CLONEDB;

DECLARE @BackupCommand NVARCHAR(MAX) = 
N'BACKUP DATABASE [' + @BackupDB + N'] TO DISK = ''' + @BackupPath + N''' WITH INIT, FORMAT, MEDIANAME = ''SQLServerBackups'', NAME = ''Full Backup of ' + @BackupDB + N''';';

EXEC sp_executesql @BackupCommand;

-- Drop Schema Database If Exists
DECLARE @drop NVARCHAR(100); -- Declare a variable to hold the drop database command
DECLARE @Result NVARCHAR(200); -- Declare a variable to hold the full drop database command with the database name
SET @drop = 'DROP DATABASE IF EXISTS'; -- Set the drop command
SET @Result = (@drop + ' ' + @BackupDB); -- Combine the drop command with the cloned database name
EXEC sp_executesql @Result; -- Execute the drop database command

"@

Invoke-Sqlcmd -Query $sqlCreateBackup -ServerInstance $serverName

# Step 2: Find the logical file paths of the original database
$sqlFindPaths = @"
USE $sourceDB;

DECLARE @LogicalDataFileName NVARCHAR(128);
DECLARE @LogicalLogFileName NVARCHAR(128);

-- Get logical file names
SELECT @LogicalDataFileName = df.name
FROM sys.database_files df
WHERE type_desc = 'ROWS';

SELECT @LogicalLogFileName = df.name
FROM sys.database_files df
WHERE type_desc = 'LOG';

-- Return the logical file names
SELECT @LogicalDataFileName AS Column1, @LogicalLogFileName AS Column2;
"@

$paths = Invoke-Sqlcmd -Query $sqlFindPaths -ServerInstance $serverName

# Reference Column1 and Column2 for the file names
$logicalDataFileName = $paths[0]
$logicalLogFileName = $paths[1]

# Output the results to verify
Write-Host "Logical Data File Name: $logicalDataFileName"
Write-Host "Logical Log File Name: $logicalLogFileName"

# Step 3: Prompt for the names of databases to restore to

$sqlRestore = @"

DECLARE @BackupFilePath NVARCHAR(128) = N'$backupPath';  -- Step 1. Change me to the backup location!
DECLARE @LogicalDataFileName NVARCHAR(128) = N'$logicalDataFileName';  -- Step 2. Make these match the original DB! Psst, you can use 2.FindLogicalPaths.sql
DECLARE @LogicalLogFileName NVARCHAR(128) = N'$logicalLogFileName';  -- Step 2. Make these match the original DB! Psst, you can use 2.FindLogicalPaths.sql
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

"@


Invoke-Sqlcmd -Query $sqlRestore -ServerInstance $serverName

Write-Host "Succesfully Restored: $logicalLogFileName"


Invoke-Sqlcmd -Query $sqlRestore -ServerInstance $serverName

Write-Host "Succesfully Restored: $logicalLogFileName"

# Step 4: Update the B001__baseline.sql script with the correct logical data and log file paths
$baselineFilePath = "C:\AutoPilotTests\Flyway-AutoPilot-AB\migrations\B001__baseline.sql"
$baselineContent = Get-Content $baselineFilePath

# Replace placeholders with actual logical data and log file names
$updatedBaselineContent = $baselineContent `
    -replace "TEMPORARYDATAFILENAME", $logicalDataFileName `
    -replace "LogicalLogFileName", $logicalLogFileName `

# Write the updated content back to the file
$updatedBaselineContent | Set-Content $baselineFilePath

Write-Host "Baseline script updated successfully with logical paths."
