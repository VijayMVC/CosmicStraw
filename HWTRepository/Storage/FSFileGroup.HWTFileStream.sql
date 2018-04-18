ALTER DATABASE	[$(DatabaseName)]
		   ADD	FILE 
					(
						NAME = [HWTFileStream]
					  , FILENAME = '$(FilestreamRoot)\$(FilestreamFolder)') 
			TO	FILEGROUP [FSFileGroup] ;

