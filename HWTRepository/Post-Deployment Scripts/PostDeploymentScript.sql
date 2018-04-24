/*
Post-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/

:r .\LoadTagTypesAndTags.sql

:r .\SQLEventLogPostDeployment.sql

:r .\ErrorMessages.sql

   ALTER 	DATABASE [$(DatabaseName)]
  MODIFY	FILEGROUP [HWTTables] 
			DEFAULT
			;

IF '$(Production)' = 'Production' 
	BEGIN 

		DROP USER [ENT\HWTRepository-Dev-ElevatedPrivilege] ;
		DROP LOGIN [ENT\HWTRepository-Dev-ElevatedPrivilege] ; 

		DROP USER [ENT\HWTRepository-Dev-LowPrivilege] ;
		DROP LOGIN [ENT\HWTRepository-Dev-LowPrivilege] ; 

		DROP USER [HWTValidator] ;
		DROP LOGIN [HWTValidator] ; 

	END 