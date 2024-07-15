# Define the backup file path
$BackupFilePath = "C:\Users\redgate\Desktop\Aardvark\backups\widget.bak"

# Define an array of database names to create
$DatabaseNames = @(
    "AutoPilotDev",
    "AutoPilotTest",
    "AutoPilotStaging",
    "AutoPilotProd",
    "AutoPilotShadow",
    "AutoPilotBuild",
    "AutoPilotCheck"
)

# Loop through each database name and create the database
foreach ($DatabaseName in $DatabaseNames) {
    # Construct logical file names and paths based on the database name
    $LogicalDataFileName = "aardvark_prod"
    $LogicalLogFileName = "aardvark_prod_log"
    $DataFilePath = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\" + $DatabaseName + "_Data.mdf"
    $LogFilePath = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\" + $DatabaseName + "_Log.ldf"

    # Create the database using SQL Server Management Objects (SMO)
    try {
        # Load the SQL Server SMO assembly
        [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
        
        # Connect to the SQL Server instance
        $serverInstance = New-Object Microsoft.SqlServer.Management.Smo.Server("localhost")
        
        # Check if the database already exists, drop it if it does
        if ($serverInstance.Databases.Contains($DatabaseName)) {
            Write-Host "Database $DatabaseName already exists. Dropping..."
            $serverInstance.KillAllProcesses($DatabaseName)
            $serverInstance.Databases[$DatabaseName].Drop()
            Write-Host "Database $DatabaseName dropped."
        }

        # Create a new database
        $database = New-Object Microsoft.SqlServer.Management.Smo.Database($serverInstance, $DatabaseName)
        $database.Create()

        # Restore the database from the backup with unique logical file names
        $restore = New-Object Microsoft.SqlServer.Management.Smo.Restore
        $restore.Database = $DatabaseName
        $restore.Action = [Microsoft.SqlServer.Management.Smo.RestoreActionType]::Database
        $restore.Devices.AddDevice($BackupFilePath, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)
        $restore.ReplaceDatabase = $true
        
        $fileData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($LogicalDataFileName, $DataFilePath)
        $fileLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($LogicalLogFileName, $LogFilePath)
        $restore.RelocateFiles.Add($fileData)
        $restore.RelocateFiles.Add($fileLog)

        $restore.SqlRestore($serverInstance)
        Write-Host "Database $DatabaseName restored from backup."

        # Put the database back in multi-user mode
        $multiUserSQL = "ALTER DATABASE [$DatabaseName] SET MULTI_USER"
        $serverInstance.Databases[$DatabaseName].ExecuteNonQuery($multiUserSQL)
        Write-Host "Database $DatabaseName set to multi-user mode."
    }
    catch {
        Write-Error "Error occurred while creating or restoring database $DatabaseName: $_"
    }
}
