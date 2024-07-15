USE [''];
GO

DECLARE @LogicalDataFileName NVARCHAR(128);
DECLARE @LogicalLogFileName NVARCHAR(128);

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
SELECT @LogicalDataFileName AS LogicalDataFileName, @LogicalLogFileName AS LogicalLogFileName;
