   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILEGROUP [HWTFiles] 
			CONTAINS FILESTREAM 
			;
	  GO

   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILEGROUP [HWTTables] 
			;
	  GO
	  
   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILEGROUP [HWTValues] 
			;
	  GO
	  
   ALTER 	DATABASE [$(DatabaseName)]
	 ADD	FILEGROUP [HWTIndexes] 
			;
	  GO
	  
	  
   ALTER 	DATABASE [$(DatabaseName)]
  MODIFY	FILEGROUP [HWTTables] 
			AUTOGROW_ALL_FILES
			;
	  GO	
	  
   ALTER 	DATABASE [$(DatabaseName)]
  MODIFY	FILEGROUP [HWTValues] 
			AUTOGROW_ALL_FILES
			;
	  GO

   ALTER 	DATABASE [$(DatabaseName)]
  MODIFY	FILEGROUP [HWTIndexes] 
			AUTOGROW_ALL_FILES
			;