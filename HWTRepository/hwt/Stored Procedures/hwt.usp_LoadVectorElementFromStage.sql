CREATE	PROCEDURE hwt.usp_LoadVectorElementFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorElementFromStage
	Abstract:	Load changed vector elements from stage to hwt.Element and hwt.VectorElement

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT data into temp storage from labViewStage
	3)	INSERT new Element data from temp storage into hwt.Element
	4)	UPDATE ElementID back into temp storage
	5)	INSERT vector element data from temp storage into hwt.VectorElement
	6)	UPDATE PublishDate on labViewStage.vector_element
	7)	EXECUTE sp_releaseapplock to release lock

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

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.vector_element' ) ;

--	2)	INSERT data into temp storage from PublishAudit
	CREATE TABLE	#changes
					(
						ID				int
					  , VectorID		int
					  , Name			nvarchar(100)
					  , Type			nvarchar(50)
					  , Units			nvarchar(50)
					  , Value			nvarchar(1000)
					  , NodeOrder		int
					  , OperatorName	nvarchar(50)
					  , ElementID		int
					)
					;

	  INSERT	INTO #changes
					( ID, VectorID, Name, Type, Units, Value, NodeOrder, OperatorName )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , NodeOrder		=	ISNULL( NULLIF( i.NodeOrder, 0 ), i.ID )
			  , h.OperatorName
		FROM	labViewStage.vector_element AS i
				INNER JOIN	labViewStage.PublishAudit AS pa
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = i.ID

				INNER JOIN 	labViewStage.vector AS v
						ON 	v.ID = i.VectorID
	
				INNER JOIN 	labViewStage.header AS h
						ON 	h.ID = v.HeaderID 
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	3)	INSERT new Element data from temp storage into hwt.Element
		--	cte is the set of AppConst data that does not already exist on hwt
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
					FROM	hwt.Element
				)

			  , newData AS
					(
					  SELECT	DISTINCT
								ElementID	=	MIN( ID ) OVER( PARTITION BY c.Name, c.Type, c.Units )
							  , Name		=	cte.Name
							  , DataType	=	cte.DataType
							  , Units		=	cte.Units
						FROM	#changes AS c
								INNER JOIN cte
										ON cte.Name = c.Name
											AND cte.DataType = c.Type
											AND cte.Units = c.Units
					)

	  INSERT	hwt.Element
					( ElementID, Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	ElementID	=	newData.ElementID
			  , Name		=	newData.Name
			  , DataType	=	newData.DataType
			  , Units		=	newData.Units
			  , UpdatedBy	=	x.OperatorName
			  , UpdatedDate =	SYSDATETIME()
		FROM	newData
				CROSS APPLY
					( SELECT OperatorName FROM #changes AS c WHERE c.ID = newData.ElementID ) AS x
				;


--	4)	UPDATE ElementID back into temp storage
	  UPDATE	tmp
		 SET	ElementID	=	e.ElementID
		FROM	#changes AS tmp
				INNER JOIN hwt.Element AS e
						ON e.Name = tmp.Name
							AND e.DataType = tmp.Type
							AND e.Units = tmp.Units
				;


--	5)	INSERT vector element data from temp storage into hwt.VectorElement
	  INSERT	hwt.VectorElement
					( VectorID, ElementID, NodeOrder, ElementValue, UpdatedBy, UpdatedDate )
	  SELECT	VectorID
			  , ElementID
			  , NodeOrder
			  , Value
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes
				;


--	7)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	pa
		FROM	labViewStage.PublishAudit AS pa
				INNER JOIN	#changes AS tmp
						ON	pa.ObjectID = @ObjectID
							AND tmp.ID = pa.RecordID
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
											FOR XML PATH( 'usp_LoadVectorElementFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH
