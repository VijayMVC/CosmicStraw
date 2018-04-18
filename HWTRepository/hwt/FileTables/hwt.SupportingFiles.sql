CREATE TABLE 	hwt.SupportingFiles 
		  AS 	FILETABLE 
				FILESTREAM_ON [FSFileGroup]
		WITH	( 
					FILETABLE_COLLATE_FILENAME	=	SQL_Latin1_General_CP1_CI_AS
				  , FILETABLE_DIRECTORY 		= 	N'SupportingFiles' 
				) ;

