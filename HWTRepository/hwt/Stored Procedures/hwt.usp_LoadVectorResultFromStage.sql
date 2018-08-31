CREATE PROCEDURE
	hwt.usp_LoadVectorResultFromStage
		(
			@pValueLength	int		=	100
		)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorResultFromStage
	Abstract:	Load changed result elements from stage to hwt.Result and hwt.VectorResult

	Logic Summary
	-------------
	1)	INSERT new Result data from temp storage into hwt
	2)	INSERT new VectorResult data from temp storage into hwt
	3)	INSERT data into temp storage from PublishAudit
	4)	INSERT non-JSON values data FROM temp storage
	5)	INSERT JSON values data FROM temp storage
	6)	UPDATE hwt.VectorResult with overflow data
	7)	DELETE processed records from labViewStage.PublishAudit


	Parameters
	----------

	@pValueLength	int		result values greater than this length will be written to hwt.VectorResultExtended

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

	 DECLARE	@objectID		int	=	OBJECT_ID( N'labViewStage.result_element' ) ;

	 DECLARE	@records	TABLE	( RecordID int ) ;

--	1)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit
	  OUTPUT	deleted.RecordID
		INTO	@records( RecordID )
	   WHERE	ObjectID = @objectID
				;


--	2)	INSERT new Result data from temp storage into hwt
	  INSERT	hwt.Result
					( Name, DataType, Units, CreatedBy, CreatedDate )
	  SELECT	DISTINCT
				Name		=	lvs.Name
			  , DataType	=	lvs.Type
			  , Units		=	lvs.Units
			  , CreatedBy	=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , CreatedDate	=	SYSDATETIME()
		FROM	labViewStage.result_element AS lvs
				INNER JOIN	@records
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.vector AS v
						ON	v.ID = lvs.VectorID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = v.HeaderID

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.Result AS r
					   WHERE	r.Name = lvs.Name
									AND r.DataType = lvs.Type
									AND r.Units = lvs.Units
					)
				;


--	2)	INSERT new VectorResult data from temp storage into hwt
	  INSERT	hwt.VectorResult
					( VectorID, ResultID, NodeOrder, IsArray, IsExtended )
	  SELECT	DISTINCT
				VectorID	=	lvs.VectorID
			  , ResultID	=	r.ResultID
			  , NodeOrder	=	ISNULL( NULLIF( lvs.NodeOrder, 0 ), ROW_NUMBER() OVER( PARTITION BY lvs.VectorID ORDER BY lvs.ID ) )
			  , IsArray		=	CONVERT( bit, ISJSON( lvs.Value ) )
			  , IsExtended	=	CASE ISJSON( lvs.Value )
									WHEN	1 THEN 1
									ELSE	CASE
												WHEN LEN( lvs.Value ) > @pValueLength THEN 1
												ELSE 0
											END
								END
		FROM	labViewStage.result_element AS lvs
				INNER JOIN	@records
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.vector AS v
						ON	v.ID = lvs.VectorID

				INNER JOIN	hwt.Result AS r
					   ON	r.Name = lvs.Name
								AND r.DataType = lvs.Type
								AND r.Units = lvs.Units
				;


--	3)	INSERT data into temp storage from PublishAudit
	  CREATE TABLE	#changes
					(
						ID					int
					  , VectorID			int
					  , Name				nvarchar(250)
					  , Type				nvarchar(50)
					  , Units				nvarchar(50)
					  , Value				nvarchar(max)
					  , NodeOrder			int
					  , ResultID			int
					  , VectorResultID		int
					)
					;

	  INSERT	#changes
					( ID, VectorID, Value, NodeOrder, ResultID, VectorResultID )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Value
			  , i.NodeOrder
			  , r.ResultID
			  , vr.VectorResultID
		FROM	labViewStage.result_element AS i
				INNER JOIN	@records
						ON	RecordID = i.ID

				INNER JOIN	labViewStage.vector AS v
						ON	v.ID = i.VectorID

				INNER JOIN	hwt.Result AS r
						ON	r.Name = i.Name
								AND r.DataType = i.Type
								AND r.Units = i.Units

				INNER JOIN	hwt.VectorResult AS vr
						ON	vr.VectorID = i.VectorID
								AND vr.ResultID = r.ResultID
								AND vr.NodeOrder = i.NodeOrder
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	4)	INSERT non-JSON values data FROM temp storage
		--	LEN( Value ) < = @pValueLength
	  INSERT	hwt.VectorResultValue
					( VectorResultID, ResultValue )
	  SELECT	VectorResultID	=	i.VectorResultID
			  , ResultValue		=	i.Value
		FROM	#changes AS i

	   WHERE	ISJSON( i.Value ) = 0
					AND LEN( i.Value ) < = @pValueLength
				;

		--	LEN( Value ) > @pValueLength
	  INSERT	hwt.VectorResultExtended
					( VectorResultID, ResultValue )

	  SELECT	VectorResultID	=	i.VectorResultID
			  , ResultValue		=	i.Value
		FROM	#changes AS i

	   WHERE	ISJSON( i.Value ) = 1 OR LEN( i.Value ) > @pValueLength
				;


	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadVectorResultFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH

