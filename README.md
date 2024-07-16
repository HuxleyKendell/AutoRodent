# AutoRodent

## Overview
**AutoRodent** is a comprehensive solution designed to facilitate the creation of a complete Flyway project with full CI/CD capabilities. By providing a schema-only backup, users can automatically generate a Flyway project, making it easier to manage database migrations and integrations.

## Features
- Automatically generate Flyway projects from a schema-only backup.
- Scripts to create and restore necessary databases for testing.
- Full CI/CD integration with YAML configuration for Azure DevOps.
- Handy scripts to assist in managing database backups and logical file paths.
- An exercise book included in the repository to guide learning and practice.

## Getting Started

### Important: Use This Repository as a Template
**Do not fork this repository!** Instead, use it as a template to ensure your repository remains private. To do this, click on the "Use this template" button on the repository page.

### Step 1: Use this Repository as a Template
1. Navigate to the repository page.
2. Click on the "Use this template" button.
3. Create a new repository from this template.

### Step 2: Clone the Project
1. Copy the repository URL.
2. Open Flyway Desktop.
3. Select **Open From Version Control** and clone the project using the copied URL.

### Step 3: Supply a Schema-Only Backup
You will need to provide a schema-only backup of your desired database to model your project. The necessary scripts can be found in the `Scripts` folder.

### Step 4: Create a Schema-Only Backup (if needed)
If you do not have a schema-only backup, use the `CreateSchemaBackup.sql` file:
1. Open the file in SSMS.
2. Change the `SourceDB` variable on line 2 to your database name.
3. Change the project folder URL on line 9 to match your repository address.
4. Run the script to create a backup in the project's backup folder.

### Step 5: Create Databases for Testing
To create the necessary databases for testing Flyway:
1. Use the `CreateAllFromBackup.sql` script:
    - Ensure the variable on line 1 is correct.
    - Ensure the variables on line 2 & 3 are correct for `LogicalDataFileName` and `LogicalLogFileName`.
    - Use the `FindLogicalPaths.sql` script if needed to find these values.
2. Run the script to create all needed databases.

### Step 6: Use Flyway Desktop
You can now fully utilize Flyway Desktop for database migrations.

### Step 7: CI/CD Integration
To integrate with CI/CD:
1. Import your GitHub repository into Azure DevOps.
2. The YAML configuration inside the project folder should work automatically.
3. You may need to tweak the YAML and set necessary variables, as explained in the repository.

## Additional Resources
- An exercise book is included in the repository to help guide learning and practice. Make sure to check it out for a hands-on experience.
