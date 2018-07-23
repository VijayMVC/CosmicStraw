CREATE	PROCEDURE hwt.usp_LoadVectorElementFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorElementFromStage
	Abstract:	Load changed vector elements from stage to hwt.Element and hwt.VectorElement

	Logic Summary
	-------------
	1)	INSERT data into temp storage from trigger
	2)	MERGE elements from temp storage into hwt.Element
	3)	MERGE vector elements into hwt.VectorElement

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
						  , Name		nvarchar(100)
						  , Type		nvarchar(50)
						  , Units		nvarchar(50)
						  , Value		nvarchar(1000)
						  , CreatedDate datetime
						)
						;

	CREATE TABLE	#changes
					(
						ID				int
					  , VectorID		int
					  , Name			nvarchar(100)
					  , Type			nvarchar(50)
					  , Units			nvarchar(50)
					  , Value			nvarchar(1000)
					  , OperatorName	nvarchar(50)
					  , ElementN		int
					  , ElementID		int
					)
					;

--	1)	INSERT data into temp storage from trigger
	  INSERT	INTO #changes
					( ID, VectorID, Name, Type, Units, Value, OperatorName, ElementN )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , h.OperatorName
			  , ElementN		=	existingCount.N + ROW_NUMBER() OVER( PARTITION BY i.VectorID, i.Name, i.Type, i.Units ORDER BY i.ID )
		FROM	#inserted AS i
				INNER JOIN labViewStage.vector AS v
						ON v.ID = i.VectorID

				INNER JOIN labViewStage.header AS h
						ON v.HeaderID = h.ID

				OUTER APPLY
					(
					  SELECT	COUNT(*)
						FROM	labViewStage.vector_element AS lvs
					   WHERE	lvs.VectorID = i.VectorID
									AND lvs.Name = i.Name
									AND lvs.Type = i.Type
									AND lvs.Units = i.Units
					) AS existingCount(N)
				;



--	2)	INSERT new Element data from temp storage into hwt.Element
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
					FROM	hwt.Element
				)

	  INSERT	hwt.Element
					( Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				Name		=	cte.Name
			  , DataType	=	cte.DataType
			  , Units		=	cte.Units
			  , UpdatedBy	=	tmp.OperatorName
			  , UpdatedDate =	SYSDATETIME()
		FROM	cte
				INNER JOIN #changes AS tmp
						ON tmp.Name = cte.Name
							AND tmp.Type = cte.DataType
							AND tmp.Units = cte.Units
				;

--	3)	UPDATE ElementID back into temp storage
	  UPDATE	tmp
		 SET	ElementID	=	e.ElementID
		FROM	#changes AS tmp
				INNER JOIN hwt.Element AS e
						ON e.Name = tmp.Name
							AND e.DataType = tmp.Type
							AND e.Units = tmp.Units
				;


--	4)	INSERT vector element data from temp storage into hwt.VectorElement
	  INSERT	hwt.VectorElement
					( VectorID, ElementID, ElementN, ElementValue, UpdatedBy, UpdatedDate )
	  SELECT	VectorID		=	VectorID
			  , ElementID		=	ElementID
			  , ElementN		=	ElementN
			  , ElementValue	=	Value
			  , UpdatedBy		=	OperatorName
			  , SYSDATETIME()
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
