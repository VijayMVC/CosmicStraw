CREATE PROCEDURE 
	hwt.usp_UpdateTagInRepository
		(
			@pUserID		sysname			=	NULL
		  , @pTagID			int
		  , @pName			nvarchar(50)
		  , @pDescription	nvarchar(100)
		  , @pIsPermanent	int				=	0
		)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_UpdateTagInRepository
	Abstract:	Updates existing tag in repository

	Logic Summary
	-------------
	1)	UPDATE data into hwt.Tag from input parameters

	Parameters
	----------
	@pUserID		nvarchar(128)
	@pTagTypeID		int
	@pName			nvarchar(50)
	@pDescription	nvarchar(100)
	@pIsPermanent	int

	Notes
	-----


	Revision
	--------
	carsoc3		2018-04-27		production release


***********************************************************************************************************************************
*/
AS
SET NOCOUNT, XACT_ABORT ON ;


BEGIN TRY

	  UPDATE	hwt.Tag
		 SET	Name			=	@pName
			  , Description		=	@pDescription
			  , UpdatedDate		=	SYSDATETIME()
			  , UpdatedBy		=	COALESCE( @pUserID, CURRENT_USER )
	   WHERE	TagID = @pTagID ;

	RETURN 0 ;

END TRY

BEGIN CATCH

	 DECLARE	@pInputParameters	nvarchar(4000) ;

	  SELECT	@pInputParameters	=	(
											SELECT	[usp_UpdateTagInRepository.@pUserID]		=	@pUserID
												  , [usp_UpdateTagInRepository.@pTagID]			=	@pTagID
												  , [usp_UpdateTagInRepository.@pName]			=	@pName
												  , [usp_UpdateTagInRepository.@pDescription]	=	@pDescription
												  , [usp_UpdateTagInRepository.@pIsPermanent]	=	@pIsPermanent

													FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
										)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pInputParameters
				;

	RETURN 55555 ;

END CATCH

