/*
	Creates and signs certificate for utility.translate_procid_sp

	This allows any user to execute the proc where they may not otherwise 
		have required permissions 

*/

--	Create throwaway password.
 DECLARE	@password	char(40)		=	CONVERT( char(36), NEWID() ) + ' Aa1?'
		  , @sql		nvarchar(max)
			;


-- Drop any existing certificate and user.
	DROP USER IF EXISTS eLog_log_GetProcID$cert ; 

	IF EXISTS( SELECT 1 FROM sys.certificates WHERE name = 'eLog_log_GetProcID' )
		DROP CERTIFICATE eLog_log_GetProcID ;

-- Construct the SQL and create the certificate.
  SELECT	@sql =	' CREATE CERTIFICATE eLog_log_GetProcID' +
					' ENCRYPTION BY PASSWORD = ' + QUOTENAME( @password, '''' ) +
					' WITH SUBJECT = ''To sign eLog.log_GetProcID'', ' +
					' START_DATE = ''' + CONVERT( char(8), GETUTCDATE(), 112 ) + ''', ' +
					' EXPIRY_DATE   = ''20300101''' +
					' ADD SIGNATURE TO eLog.log_GetProcID ' +
					' BY CERTIFICATE eLog_log_GetProcID ' +
					' WITH PASSWORD = ' + QUOTENAME( @password, '''' )
			; 

	EXEC	( @sql ) ;

GO

-- Create the user and grant permission.
  CREATE 	USER eLog_log_GetProcID$cert
			FROM CERTIFICATE eLog_log_GetProcID 
			; 
GO
   GRANT 	VIEW DEFINITION 
      TO 	eLog_log_GetProcID$cert 
			;
GO

IF 	EXISTS( SELECT 1 FROM sys.servers WHERE name = 'LOOPBACK' )
	EXECUTE	sp_dropserver 'LOOPBACK' ; 

EXECUTE sp_addlinkedserver 'LOOPBACK', '', 'SQLNCLI', @@servername ;
EXECUTE sp_serveroption  'LOOPBACK', 'remote proc transaction promotion', 'false' ;
EXECUTE sp_serveroption  'LOOPBACK', 'rpc out', 'true' ;
