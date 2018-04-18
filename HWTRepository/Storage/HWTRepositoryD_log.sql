ALTER DATABASE	[$(DatabaseName)]
		   ADD	LOG FILE 
					(
						NAME		=	[HWTRepositoryD_log]
					  , FILENAME	=	'$(LogFileRoot)\$(DatabaseName).ldf'
					  , SIZE		=	1GB
					  , FILEGROWTH	=	256MB
					) ;