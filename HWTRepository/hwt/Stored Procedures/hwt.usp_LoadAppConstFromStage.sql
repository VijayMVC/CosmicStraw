CREATE	PROCEDURE hwt.usp_LoadAppConstFromStage
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

SET XACT_ABORT, NOCOUNT ON 
;

BEGIN TRY
	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.appConst_element' ) 
;
	 DECLARE	@Records	TABLE	( RecordID int ) 
;

--	1)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit 
	  OUTPUT	deleted.RecordID
		INTO	@Records( RecordID )
	   WHERE	ObjectID = @ObjectID
;
	IF	( @@ROWCOUNT = 0 )
		RETURN 0 
;

--	2)	INSERT new AppConst data from temp storage into hwt
	  INSERT	hwt.AppConst
					( Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				Name		=	lvs.Name
			  , DataType	=	lvs.Type
			  , Units		=	lvs.Units
			  , UpdatedBy	=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , UpdatedDate	=	SYSDATETIME()
		FROM	labViewStage.appConst_element AS lvs
				INNER JOIN	@Records
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = lvs.HeaderID

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.AppConst AS ac
					   WHERE	ac.Name = lvs.Name COLLATE SQL_Latin1_General_CP1_CS_AS
								AND ac.DataType = lvs.Type
								AND ac.Units = lvs.Units COLLATE SQL_Latin1_General_CP1_CS_AS
					)
;

--	3)	INSERT data into temp storage from PublishAudit and labViewStage
	  CREATE	TABLE #changes
					(
						ID				int
					  , HeaderID		int
					  , Name			nvarchar(250)
					  , Type			nvarchar(50)
					  , Units			nvarchar(250)
					  , Value			nvarchar(max)
					  , NodeOrder		int
					  , OperatorName	nvarchar(50)
					  , AppConstID		int
					)
;
	  INSERT	#changes
					(
						ID, HeaderID, Name, Type, Units, Value
							, NodeOrder, OperatorName, AppConstID
					)
	  SELECT	i.ID
			  , i.HeaderID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , i.NodeOrder
			  , h.OperatorName
			  , ac.AppConstID
		FROM	labViewStage.appConst_element AS i
				INNER JOIN	@Records
						ON	RecordID = i.ID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = i.HeaderID

				INNER JOIN	hwt.AppConst AS ac
						ON	ac.Name = i.Name COLLATE SQL_Latin1_General_CP1_CS_AS 
							AND ac.DataType = i.Type
							AND ac.Units = i.Units COLLATE SQL_Latin1_General_CP1_CS_AS 
;

--	4)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
	  INSERT	hwt.HeaderAppConst
					( HeaderID, AppConstID, NodeOrder, AppConstValue, UpdatedBy, UpdatedDate )

	  SELECT	DISTINCT 
				HeaderID
			  , AppConstID
			  , NodeOrder
			  , Value
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes
;
	RETURN 0 
;
END TRY
BEGIN CATCH
	 DECLARE	@pErrorData	xml 
;
	  SELECT	@pErrorData	=	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadAppConstFromStage' ), TYPE
								)
;
	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION 
;
	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pErrorData
;
	RETURN 55555 
;
END CATCH
