CREATE PROCEDURE
	hwt.usp_InsertTagToRepository
		(
			@pUserID		sysname			=	NULL
		  , @pTagType		nvarchar(50)
		  , @pName			nvarchar(50)
		  , @pDescription	nvarchar(100)
		  , @pIsPermanent	int				=	0
		)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_InsertTagToRepository
	Abstract:	Adds new tags to repository

	Logic Summary
	-------------
	1)	INSERT data into hwt.Tag from input parameters

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
	carsoc3		2018-02-01		alpha release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/
AS
SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

	  INSERT	hwt.Tag
					( TagTypeID, Name, Description, IsDeleted, UpdatedDate, UpdatedBy )

	  SELECT	TagTypeID	=	tType.TagTypeID
			  , Name		=	@pName
			  , Description =	@pDescription
			  , IsDeleted	=	0
			  , UpdatedDate	=	GETDATE()
			  , UpdatedBy	=	COALESCE( @pUserID, CURRENT_USER )
		FROM	hwt.TagType AS tType
	   WHERE	tType.Name = @pTagType
				;

	RETURN 0 ;

END TRY

BEGIN CATCH

 DECLARE	@pInputParameters	nvarchar(4000) ;

  SELECT	@pInputParameters	=	(
										SELECT	[usp_InsertTagToRepository.@pUserID]		=	@pUserID
											  , [usp_InsertTagToRepository.@pTagType]		=	@pTagType
											  , [usp_InsertTagToRepository.@pName]			=	@pName
											  , [usp_InsertTagToRepository.@pDescription]	=	@pDescription
											  , [usp_InsertTagToRepository.@pIsPermanent]	=	@pIsPermanent

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
