﻿CREATE TABLE 	xmlStage.LegacyXML_Files 
		  AS 	FILETABLE 
				FILESTREAM_ON [HWTFiles]
		WITH	( 
					FILETABLE_COLLATE_FILENAME = SQL_Latin1_General_CP1_CI_AS
				  , FILETABLE_DIRECTORY = N'Legacy_XML' 
				) ;

