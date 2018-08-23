﻿  CREATE	TABLE xmlStage.error_element
				(
					ID				int				NOT NULL	IDENTITY
				  , VectorID		int				NOT NULL
				  , ErrorType		int				NOT NULL	DEFAULT 1
						--	ErrorType 1:  test error
						--	ErrorType 2:  data error
						--	ErrorType 3:  input parameter error

				  , ErrorCode		int				NOT NULL
				  , ErrorText		nvarchar(max)	NOT NULL
				  , NodeOrder		int				NOT NULL	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_xmlStage_error_element
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_xmlStage_error_element_vector
						FOREIGN KEY( VectorID )
						REFERENCES xmlStage.vector( ID )

				  , CONSTRAINT	CK_xmlStage_VectorError_ErrorType
						CHECK( ErrorType IN ( 1, 2, 3 ) )
				)
				ON	[HWTTables]
				TEXTIMAGE_ON [HWTTables]
			;
