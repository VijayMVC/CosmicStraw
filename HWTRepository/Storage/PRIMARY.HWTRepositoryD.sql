ALTER DATABASE	[$(DatabaseName)]
		   ADD	FILE 
					(
						NAME		=	[HWTRepositoryD]
					  , FILENAME	=	'$(DataRoot)\$(DatabaseName)_Primary.mdf'
					  , SIZE		=	1GB
					  , FILEGROWTH	=	256MB
					) 
				TO FILEGROUP [PRIMARY] ;

