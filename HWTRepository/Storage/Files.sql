   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILE
				(
					NAME		=	[HWTRepository_Primary]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_Primary.mdf'
				  , SIZE		=	64MB
				  , FILEGROWTH	=	64MB
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
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTTables1.mdf'
				  , SIZE		=	128MB
				  , FILEGROWTH	=	128MB
				  , MAXSIZE		=	UNLIMITED
				) 
			  , (
					NAME		=	[HWTRepository_HWTTables2]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTTables2.mdf'
				  , SIZE		=	128MB
				  , FILEGROWTH	=	128MB
				  , MAXSIZE		=	UNLIMITED
				) 

	  TO 	FILEGROUP [HWTTables] 
			;
	GO  

  
   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILE
				(
					NAME		=	[HWTRepository_HWTIndexes1]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTIndexes1.mdf'
				  , SIZE		=	128MB
				  , FILEGROWTH	=	128MB
				  , MAXSIZE		=	UNLIMITED
				) 
			  , (
					NAME		=	[HWTRepository_HWTIndexes2]
				  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_HWTIndexes2.mdf'
				  , SIZE		=	128MB
				  , FILEGROWTH	=	128MB
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
