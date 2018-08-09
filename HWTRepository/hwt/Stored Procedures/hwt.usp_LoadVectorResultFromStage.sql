CREATE	PROCEDURE hwt.usp_LoadVectorResultFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorResultFromStage
	Abstract:	Load changed result elements from stage to hwt.Result and hwt.VectorResult

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT data into temp storage from trigger
	3)	UPDATE NodeOrder in temp storage
	4)	INSERT new Result data from temp storage into hwt.Result
	5)	UPDATE ResultID back into temp storage
	6)	INSERT vector results from temp storage into hwt.VectorResult
	7)	UPDATE PublishDate on labViewStage.result_element
	8)	EXECUTE sp_releaseapplock to release lock


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

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.result_element' ) ;

--	2)	INSERT data into temp storage from PublishAudit
	  CREATE TABLE	#changes
					(
						ID					int
					  , VectorID			int
					  , Name				nvarchar(250)
					  , Type				nvarchar(50)
					  , Units				nvarchar(50)
					  , Value				nvarchar(max)
					  , NodeOrder			int
					  , OperatorName		nvarchar(50)
					  , ResultID			int
					)
					;

	  INSERT	#changes
					( ID, VectorID, Name, Type, Units, Value, NodeOrder, OperatorName )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , NodeOrder		=	ISNULL( NULLIF( i.NodeOrder, 0 ), i.ID )
			  , h.OperatorName
		FROM	labViewStage.result_element AS i
				INNER JOIN	labViewStage.PublishAudit AS pa
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = i.ID

				INNER JOIN	labViewStage.vector AS v
						ON	v.ID = i.VectorID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = v.HeaderID
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	4)	INSERT new Result data from temp storage into hwt.Result
		--	cte is the set of Result data that does not already exist on hwt
		--	newData is the set of data from cte with ID attached
		WITH	cte AS
					(
					  SELECT	Name		=	tmp.Name
							  , DataType	=	tmp.Type
							  , Units		=	tmp.Units
						FROM	#changes AS tmp

					  EXCEPT
					  SELECT	Name
							  , DataType
							  , Units
						FROM	hwt.Result
					)

			  , newData AS
					(
					  SELECT	DISTINCT
								ResultID	=	MIN( ID ) OVER( PARTITION BY c.Name, c.Type, c.Units )
							  , Name		=	cte.Name
							  , DataType	=	cte.DataType
							  , Units		=	cte.Units
						FROM	#changes AS c
								INNER JOIN cte
										ON cte.Name = c.Name
											AND cte.DataType = c.Type
											AND cte.Units = c.Units
					)

	  INSERT	hwt.Result
					( ResultID, Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	ResultID	=	newData.ResultID
			  , Name		=	newData.Name
			  , DataType	=	newData.DataType
			  , Units		=	newData.Units
			  , UpdatedBy	=	x.OperatorName
			  , UpdatedDate =	SYSDATETIME()
		FROM	newData
				CROSS APPLY
					( SELECT OperatorName FROM #changes AS c WHERE c.ID = newData.ResultID ) AS x
				;


--	5)	UPDATE ResultID back into temp storage
	  UPDATE	tmp
		 SET	ResultID  =	  r.ResultID
		FROM	#changes AS tmp
				INNER JOIN hwt.Result AS r
						ON r.Name = tmp.Name
							AND r.DataType = tmp.Type
							AND r.Units = tmp.Units
				;


--	6)	INSERT vector results from temp storage into hwt.VectorResult
		--	for #changes.Value records containing non-JSON data
	  INSERT	hwt.VectorResult
					( VectorID, ResultID, NodeOrder, ResultN, ResultValue, UpdatedBy, UpdatedDate )
	  SELECT	VectorID		=	tmp.VectorID
			  , ResultID		=	tmp.ResultID
			  , NodeOrder		=	tmp.NodeOrder
			  , ResultN			=	1
			  , ResultValue		=	CONVERT( nvarchar(100), LEFT( tmp.Value, 100 ) )
			  , UpdatedBy		=	OperatorName
			  , UpdatedDate		=	SYSDATETIME()
		FROM	#changes AS tmp

	   WHERE	LEFT( tmp.Type, 5 ) != N'ARRAY'
				;

		--	for #changes.Value records containing JSON data
	  INSERT	hwt.VectorResult
					( VectorID, ResultID, NodeOrder, ResultN, ResultValue, UpdatedBy, UpdatedDate )
	  SELECT	VectorID		=	tmp.VectorID
			  , ResultID		=	tmp.ResultID
			  , NodeOrder		=	tmp.NodeOrder
			  , ResultN			=	ISNULL( x.[Key] + 1, 1 )
			  , ResultValue		=	LEFT( ISNULL( x.Value, N'' ), 100 )
			  , UpdatedBy		=	OperatorName
			  , UpdatedDate		=	SYSDATETIME()
		FROM	#changes AS tmp
				CROSS APPLY OPENJSON( tmp.Value ) AS x

	   WHERE	LEFT( tmp.Type, 5 ) = N'ARRAY'
					AND ISJSON( tmp.Value ) = 1
				;


--	7)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	pa
		FROM	labViewStage.PublishAudit AS pa
				INNER JOIN	#changes AS tmp
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = tmp.ID
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

