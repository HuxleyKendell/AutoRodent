USE AutoPilotDev;  -- Step 1. Change me to the DB name to match the database you backed up!
GO

DECLARE @LogicalDataFileName NVARCHAR(128); -- Declare a variable to hold the logical data file name
DECLARE @LogicalLogFileName NVARCHAR(128); -- Declare a variable to hold the logical log file name

-- Get logical file names
SELECT 
    @LogicalDataFileName = df.name
FROM 
    sys.database_files df
WHERE 
    df.type = 0; -- Data file

SELECT 
    @LogicalLogFileName = df.name
FROM 
    sys.database_files df
WHERE 
    df.type = 1; -- Log file

-- Verify the logical file names
SELECT @LogicalDataFileName AS LogicalDataFileName, @LogicalLogFileName AS LogicalLogFileName; -- Display the logical data and log file names
