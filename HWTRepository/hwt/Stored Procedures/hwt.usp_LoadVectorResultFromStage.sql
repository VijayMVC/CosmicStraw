CREATE	PROCEDURE hwt.usp_LoadVectorResultFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorResultFromStage
	Abstract:	Load changed result elements from stage to hwt.Result and hwt.VectorResult

	Logic Summary
	-------------
	1)	INSERT data into temp storage from trigger
	2)	MERGE elements from temp storage into hwt.Result
	3)	MERGE result elements into hwt.VectorResult

	Parameters
	----------

	Notes
	-----


	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	--	define temp storage tables
	IF	( 1 = 0 )
		CREATE TABLE	#inserted
						(
							ID			int
						  , VectorID	int
						  , Name		nvarchar(250)
						  , Type		nvarchar(50)
						  , Units		nvarchar(50)
						  , Value		nvarchar(max)
						  , CreatedDate datetime
						)
						;

	CREATE TABLE	#changes
					(
						ID					int
					  , VectorID			int
					  , VectorResultN		int
					  , Name				nvarchar(250)
					  , Type				nvarchar(50)
					  , Units				nvarchar(50)
					  , ResultN				int
					  , ResultValue			nvarchar(250)
					  , OperatorName		nvarchar(50)
					  , ResultID			int
					)
					;


--	1)	INSERT data into temp storage from trigger for non-array values
	  INSERT	#changes
					( ID, VectorID, Name, Type, Units, VectorResultN, ResultN, ResultValue, OperatorName )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Name
			  , i.Type
			  , i.Units
			  , VectorResultN	=	existingCount.N + DENSE_RANK() OVER( PARTITION BY i.VectorID, i.Name, i.Type, i.Units ORDER BY i.ID )
			  , ResultN			=	x.ItemNumber
			  , ResultValue		=	x.Item
			  , h.OperatorName
		FROM	#inserted AS i
				INNER JOIN labViewStage.vector AS v
						ON v.ID = i.VectorID

				INNER JOIN labViewStage.header AS h
						ON h.ID = v.HeaderID

				CROSS APPLY utility.ufn_SplitString( i.Value, ',' ) AS x

				OUTER APPLY
					(
					  SELECT	COUNT(*)
						FROM	labViewStage.result_element AS lvs
					   WHERE	lvs.VectorID = i.VectorID
									AND lvs.Name = i.Name
									AND lvs.Type = i.Type
									AND lvs.Units = i.Units
					) AS existingCount(N)
	   WHERE	ISJSON( i.Value ) = 0
				;

--	2)	INSERT data into temp storage from trigger for array values
	  INSERT	#changes
					( ID, VectorID, Name, Type, Units, VectorResultN, ResultN, ResultValue, OperatorName )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Name
			  , i.Type
			  , i.Units
			  , VectorResultN	=	existingCount.N + DENSE_RANK() OVER( PARTITION BY i.VectorID, i.Name, i.Type, i.Units ORDER BY i.ID )
			  , ResultN			=	ISNULL( x.[key] + 1, 1 )
			  , ResultValue		=	ISNULL( x.Value, '' )
			  , h.OperatorName
		FROM	#inserted AS i
				INNER JOIN labViewStage.vector AS v
						ON v.ID = i.VectorID

				INNER JOIN labViewStage.header AS h
						ON h.ID = v.HeaderID

				OUTER APPLY OPENJSON( i.Value ) AS x

				OUTER APPLY
					(
					  SELECT	COUNT(*)
						FROM	labViewStage.result_element AS lvs
					   WHERE	lvs.VectorID = i.VectorID
									AND lvs.Name = i.Name
									AND lvs.Type = i.Type
									AND lvs.Units = i.Units
					) AS existingCount(N)
	   WHERE	ISJSON( i.Value ) = 1
				;


--	3)	INSERT new Result data from temp storage into hwt.Result
		WITH	cte AS
				(
				  SELECT	DISTINCT
							Name		=	tmp.Name
						  , DataType	=	tmp.Type
						  , Units		=	tmp.Units
					FROM	#changes AS tmp

				  EXCEPT
				  SELECT	Name
						  , DataType
						  , Units
					FROM	hwt.Result
				)

	  INSERT	hwt.Result
					( Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				Name		=	cte.Name
			  , DataType	=	cte.DataType
			  , Units		=	cte.Units
			  , UpdatedBy	=	tmp.OperatorName
			  , UpdatedDate =	SYSDATETIME()
		FROM	cte
				INNER JOIN	#changes AS tmp
						ON	tmp.Name = cte.Name
								AND tmp.Type = cte.DataType
								AND tmp.Units = cte.Units
				;


--	4)	UPDATE ResultID back into temp storage
	  UPDATE	tmp
		 SET	ResultID  =	  r.ResultID
		FROM	#changes AS tmp
				INNER JOIN hwt.Result AS r
						ON r.Name = tmp.Name
							AND r.DataType = tmp.Type
							AND r.Units = tmp.Units
				;


--	5)	INSERT vector results from temp storage into hwt.VectorResult
	  INSERT	hwt.VectorResult
					( VectorID, ResultID, VectorResultN, ResultN, ResultValue, UpdatedBy, UpdatedDate )
	  SELECT	VectorID
			  , ResultID
			  , VectorResultN
			  , ResultN
			  , ResultValue
			  , UpdatedBy		=	OperatorName
			  , UpdatedDate		=	SYSDATETIME()
		FROM	#changes
				;

	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	*
												FROM	#inserted
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
										  , (
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

