CREATE PROCEDURE
	hwt.usp_LoadAppConstFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadAppConstFromStage
	Abstract:	Load AppConst data from stage to hwt.AppConst and hwt.HeaderAppConst

	Logic Summary
	-------------
	1)	INSERT new AppConst data from temp storage into hwt
	2)	INSERT data into temp storage from PublishAudit and labViewStage
	3)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
	4)	DELETE processed records from labViewStage.PublishAudit


	Parameters
	----------

	Notes
	-----


	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling
								updated messaging architecture
									--	extract all records not published
									--	publish to hwt
									--	update stage data with publish date

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@objectID	int	=	OBJECT_ID( N'labViewStage.appConst_element' ) ;

	 DECLARE	@records	TABLE	( RecordID int ) ;


--	4)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit
	  OUTPUT	deleted.RecordID
		INTO	@records( RecordID )
	   WHERE	ObjectID = @objectID
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	1)	INSERT new AppConst data from temp storage into hwt
	  INSERT	hwt.AppConst
					( Name, DataType, Units, CreatedBy, CreatedDate )
	  SELECT	DISTINCT
				Name		=	lvs.Name
			  , DataType	=	lvs.Type
			  , Units		=	lvs.Units
			  , CreatedBy	=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , CreatedDate	=	SYSDATETIME()
		FROM	labViewStage.appConst_element AS lvs
				INNER JOIN	@records
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = lvs.HeaderID

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.AppConst AS ac
					   WHERE	ac.Name = lvs.Name
								AND ac.DataType = lvs.Type
								AND ac.Units = lvs.Units
					)
				;


--	3)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
	  INSERT	hwt.HeaderAppConst
					( HeaderID, AppConstID, NodeOrder, AppConstValue )
	  SELECT	HeaderID		=	i.HeaderID
			  , AppConstID		=	ac.AppConstID
			  , NodeOrder		=	i.NodeOrder
			  , AppConstValue	=	i.Value
		FROM	labViewStage.appConst_element AS i
				INNER JOIN	@records
						ON	RecordID = i.ID

				INNER JOIN	hwt.AppConst AS ac
						ON	ac.Name = i.Name
							AND ac.DataType = i.Type
							AND ac.Units = i.Units
				;

	RETURN 0 ;

END TRY

BEGIN CATCH

	 DECLARE	@pErrorData	xml ;

	  SELECT	@pErrorData	=	(
								  SELECT	(
											  SELECT	lvs.*
												FROM	labViewStage.appConst_element AS lvs
														INNER JOIN	@records
																ON	RecordID = lvs.ID
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadAppConstFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pErrorData
				;

	RETURN 55555 ;

END CATCH
