CREATE LOGIN		[ENT\MIT-HWTRepository-Dev-ElevatedPrivilege-SECURE] 
FROM WINDOWS 
WITH				DEFAULT_DATABASE=[master]
				  , DEFAULT_LANGUAGE=[us_english]
;
GO

CREATE LOGIN		[ENT\MIT-HWTRepository-Dev-LowPrivilege-SECURE] 
FROM WINDOWS 
WITH				DEFAULT_DATABASE=[master]
				  , DEFAULT_LANGUAGE=[us_english]
;
GO

CREATE LOGIN		[HWTUser]
WITH				PASSWORD = N'$(HWTUserPassword)'
				  , DEFAULT_DATABASE = [master]
				  , DEFAULT_LANGUAGE = [us_english]
				  , CHECK_POLICY = OFF
;
