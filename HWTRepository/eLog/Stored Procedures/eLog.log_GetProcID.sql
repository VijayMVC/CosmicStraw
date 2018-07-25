CREATE 	PROCEDURE eLog.log_GetProcID
			( 
				@pProcID		int
			  ,	@pProcName		nvarchar(257) 	OUTPUT
			)
/*
***********************************************************************************************************************************

    Procedure:	utility.log_GetProcID
     Abstract:  helper procedure, get proc name from SPID 
	
	
    Logic Summary
    -------------
	From original comments:
	
	This is a helper procedure called by eLog.log_InsertEvent
	Translate object id to object name. 
	
	User may not have permissions to read this information. So, procedure is signed with a certificate,
	and the user created from the certificate is granted VIEW METADATA on database level.

    Parameters
    ----------
	@pProcID	bigint 				OBJECT_ID for object that threw original error
	@pProcName	varchar(255)		OBJECT_NAME that corresponds to inbound OBJECT_ID

  
    Notes
    -----
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP 
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )

    Revision
    --------
    carsoc3     2018-02-20		Added to alpha release
	
***********************************************************************************************************************************
*/
AS
SET XACT_ABORT, NOCOUNT ON ; 

-- Translate the object name from incoming object_id
  SELECT	@pProcName	=	s.name + '.' + o.name
	FROM	master.sys.objects AS o

			INNER JOIN master.sys.schemas AS s 
					ON o.schema_id = s.schema_id
   
   WHERE	o.object_id = @pProcID 
			;