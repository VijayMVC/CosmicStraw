CREATE LOGIN	[HWTUser]
		WITH	PASSWORD = N'$(HWTUserPassword)'
			  , DEFAULT_DATABASE = [master]
			  , DEFAULT_LANGUAGE = [us_english]
			  , CHECK_POLICY = OFF
		;
GO

CREATE LOGIN	[ENT\HWTRepository-Prod-ElevatedPrivilege]
		FROM	WINDOWS
		WITH	DEFAULT_DATABASE=[master]
			  , DEFAULT_LANGUAGE=[us_english]
		;
GO

CREATE LOGIN	[ENT\HWTRepository-Prod-LowPrivilege]
		FROM	WINDOWS
		WITH	DEFAULT_DATABASE=[master]
			  , DEFAULT_LANGUAGE=[us_english]
		;
GO


CREATE LOGIN	[ENT\svc-crmhwtlab]
		FROM	WINDOWS
		WITH	DEFAULT_DATABASE=[master]
			  , DEFAULT_LANGUAGE=[us_english]
		;
GO


--	Test logins
CREATE LOGIN	[ENT\HWTRepository-Dev-ElevatedPrivilege]
		FROM	WINDOWS
		WITH	DEFAULT_DATABASE=[master]
			  , DEFAULT_LANGUAGE=[us_english]
		;
GO

CREATE LOGIN	[ENT\HWTRepository-Dev-LowPrivilege]
		FROM	WINDOWS
		WITH	DEFAULT_DATABASE=[master]
			  , DEFAULT_LANGUAGE=[us_english]
		;
GO


CREATE LOGIN	[HWTValidator]
		WITH	PASSWORD = N'$(HWTValidatorPassword)'
			  , DEFAULT_DATABASE = [master]
			  , DEFAULT_LANGUAGE = [us_english]
			  , CHECK_POLICY = OFF
		;
