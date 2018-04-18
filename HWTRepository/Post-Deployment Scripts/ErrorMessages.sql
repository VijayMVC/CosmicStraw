IF NOT EXISTS( SELECT 1 FROM eLog.UserMessage )
	BEGIN 
		  INSERT 	eLog.UserMessage
						( MessageID, LCID, MessageText, UpdatedBy, UpdatedDate ) 
		  VALUES 	( N'60000', 1033, N'Test Error Message', 'HWTAdmin', '2018-05-01' )
					; 
	END 
GO	  