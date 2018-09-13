﻿   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILE
				(
					NAME		=	[HWTRepository_Primary]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_Primary.mdf'
				  , SIZE		=	1GB
				  , FILEGROWTH	=	256MB
				) 
	  TO 	FILEGROUP [PRIMARY] 
			;

	GO


   ALTER 	DATABASE	[$(DatabaseName)]
	 ADD	LOG FILE 
				(
					NAME		=	[HWTRepository_log]
				  , FILENAME	=	'$(LogFileRoot)\$(DatabaseName).ldf'
				  , SIZE		=	1GB
				  , FILEGROWTH	=	256MB
				) 
			;
	GO


   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILE
				(
					NAME		=	[HWTRepository_HWTTables1]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTTables1.ndf'
				  , SIZE		=	256MB
				  , FILEGROWTH	=	256MB
				  , MAXSIZE		=	UNLIMITED
				) 
			  , (
					NAME		=	[HWTRepository_HWTTables2]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTTables2.ndf'
				  , SIZE		=	256MB
				  , FILEGROWTH	=	256MB
				  , MAXSIZE		=	UNLIMITED
				) 

	  TO 	FILEGROUP [HWTTables] 
			;
	GO  


   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILE
				(
					NAME		=	[HWTRepository_HWTValues1]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTValues1.ndf'
				  , SIZE		=	256MB
				  , FILEGROWTH	=	256MB
				  , MAXSIZE		=	UNLIMITED
				) 
			  , (
					NAME		=	[HWTRepository_HWTValues2]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTValues2.ndf'
				  , SIZE		=	256MB
				  , FILEGROWTH	=	256MB
				  , MAXSIZE		=	UNLIMITED
				) 

	  TO 	FILEGROUP [HWTValues] 
			;
	GO  
  
   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILE
				(
					NAME		=	[HWTRepository_HWTIndexes1]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTIndexes1.ndf'
				  , SIZE		=	256MB
				  , FILEGROWTH	=	256MB
				  , MAXSIZE		=	UNLIMITED
				) 
			  , (
					NAME		=	[HWTRepository_HWTIndexes2]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTIndexes2.ndf'
				  , SIZE		=	256MB
				  , FILEGROWTH	=	256MB
				  , MAXSIZE		=	UNLIMITED
				  ) 

	  TO 	FILEGROUP [HWTIndexes] 
			;
	GO  


	  
   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILE
				(
					NAME = [HWTRepository_FileStream]
				  , FILENAME = '$(FilestreamRoot)\$(FilestreamFolder)'
				) 
	  TO	FILEGROUP [HWTFiles] 
			;
