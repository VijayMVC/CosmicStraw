CREATE PROCEDURE
	hwt.usp_LoadVectorElementFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorElementFromStage
	Abstract:	Load changed vector elements from stage to hwt.Element and hwt.VectorElement

	Logic Summary
	-------------
	1)	INSERT new Element data from temp storage into hwt
	2)	INSERT data into temp storage from PublishAudit and labViewStage
	3)	INSERT vector Element data from temp storage into hwt.VectorElement
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

	 DECLARE	@objectID	int	=	OBJECT_ID( N'labViewStage.vector_element' ) ;

	 DECLARE	@records	TABLE	( RecordID int ) ;

--	7)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit
	  OUTPUT	deleted.RecordID
		INTO	@records( RecordID )
	   WHERE	ObjectID = @ObjectID
				;

--	3)	INSERT new Element data from temp storage into hwt.Element
	  INSERT	hwt.Element
					( Name, DataType, Units, CreatedBy, CreatedDate )
	  SELECT	DISTINCT
				Name		=	lvs.Name
			  , DataType	=	lvs.Type
			  , Units		=	lvs.Units
			  , CreatedBy	=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , CreatedDate =	SYSDATETIME()
		FROM	labViewStage.vector_element AS lvs
				INNER JOIN	@records
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.vector AS v
						ON	v.ID = lvs.VectorID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = v.HeaderID

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.Element AS e
					   WHERE	e.Name = lvs.Name
								AND e.DataType = lvs.Type
								AND e.Units = lvs.Units
					)
				;


--	2)	INSERT data into temp storage from PublishAudit
	CREATE TABLE
		#changes
			(
				ID				int
			  , VectorID		int
			  , Value			nvarchar(1000)
			  , NodeOrder		int
			  , ElementID		int
			)
		;

	  INSERT	INTO #changes
					( ID, VectorID, Value, NodeOrder, ElementID )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Value
			  , i.NodeOrder
			  , e.ElementID
		FROM	labViewStage.vector_element AS i
				INNER JOIN	@records
						ON	RecordID = i.ID

				INNER JOIN	labViewStage.vector AS v
						ON	v.ID = i.VectorID

				INNER JOIN	hwt.Element AS e
						ON	e.Name = i.Name
								AND e.DataType = i.Type
								AND e.Units = i.Units
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	5)	INSERT vector element data from temp storage into hwt.VectorElement
	  INSERT	hwt.VectorElement
					( VectorID, ElementID, NodeOrder, ElementValue )
	  SELECT	VectorID        =	i.VectorID        
			  , ElementID       =	e.ElementID       
			  , NodeOrder       =	i.NodeOrder       
			  , ElementValue	=	i.Value	
		FROM	labViewStage.vector_element AS i
				INNER JOIN	@records
						ON	RecordID = i.ID

				INNER JOIN	hwt.Element AS e
						ON	e.Name = i.Name
								AND e.DataType = i.Type
								AND e.Units = i.Units
				;


	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	i.*
												FROM	labViewStage.vector_element AS i
														INNER JOIN	@records
																ON	RecordID = i.ID
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
