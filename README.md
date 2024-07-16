# AutoRodent

## Overview
**AutoRodent** is a comprehensive solution designed to facilitate the creation of a complete Flyway project with full CI/CD capabilities. By providing a schema-only backup, users can automatically generate a Flyway project, making it easier to manage database migrations and integrations.

## Features
- Automatically generate a Flyway project from a schema-only backup.
- Includes scripts to create necessary databases.
- Integrates seamlessly with Flyway Desktop and Azure DevOps for CI/CD.

## Usage Instructions

### 1. Use this Repository as a Template
**Important:** Do not fork this repository. Use it as a template to keep your repository private.

### 2. Clone the Project
Copy the URL and click **Open From Version Control** inside Flyway Desktop. Clone the project.

### 3. Provide a Schema-Only Backup
You need to supply the project with a schema-only backup of your desired database. Handy scripts can be found inside the Flyway project, in the `Scripts` folder.

### 4. Create a Schema-Only Backup
If you do not have a schema-only backup, you can use the `CreateSchemaBackup.sql` file. Running it inside SSMS allows you to change the name of the database at the top of the script and have a backup put inside the project's `backups` folder.

**Script: `CreateSchemaBackup.sql`**
-- Change the source database name and backup file path
'DECLARE @SourceDB NVARCHAR(128) = 'YourDatabaseName'; -- Change this line'
'DECLARE @BackupFilePath NVARCHAR(260) = N'C:\YourPath\AutoBackup.bak'; -- Change this line '

## 5. Restore Databases from Backup
To create the necessary databases for Flyway, you can manually restore them using the backup file or use the `CreateAllFromBackup.sql` script.
You can see a snippet of code, which will likely need changing. You can use the **FindLogicalPaths.sql** to help find these values!

**Script: `CreateAllFromBackup.sql`**
```sql
DECLARE @BackupFilePath NVARCHAR(128) = N'C:\YourPath\AutoBackup.bak'; -- Change this line
DECLARE @LogicalDataFileName NVARCHAR(128) = 'OriginalLogicalDataFileName'; -- Set to original logical data file name
DECLARE @LogicalLogFileName NVARCHAR(128) = 'OriginalLogicalLogFileName'; -- Set to original logical log file name
```

## Use Flyway Desktop
You can now fully utilize Flyway Desktop for database changes and deployments.

## CI/CD Integration
For CI/CD integration, import your GitHub repo into Azure DevOps. The YAML file inside the project folder should work automatically. Often with YAML, it may need some tweaking and variables; all is explained inside the repository and YAML files.

## Additional Resources
An exercise book is included in the repository to help guide learning and further understanding.
