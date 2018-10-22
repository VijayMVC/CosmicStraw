CREATE	PROCEDURE hwt.usp_LoadVectorElementFromStage
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

SET XACT_ABORT, NOCOUNT ON 
;

BEGIN TRY
	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.vector_element' ) 
;
	 DECLARE	@Records	TABLE	( RecordID int ) 
; 
	 
--	1)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit
	  OUTPUT	deleted.RecordID 
	    INTO	@Records( RecordID ) 
	   WHERE	ObjectID = @ObjectID
;

--	2)	INSERT new Element data from temp storage into hwt.Element
	  INSERT	hwt.Element
					( Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				Name		=	lvs.Name
			  , DataType	=	lvs.Type
			  , Units		=	lvs.Units
			  , UpdatedBy	=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , UpdatedDate =	SYSDATETIME()
		FROM	labViewStage.vector_element AS lvs
				INNER JOIN	@Records 
						ON	RecordID = lvs.ID
							
				INNER JOIN 	labViewStage.vector AS v
						ON 	v.ID = lvs.VectorID
	
				INNER JOIN 	labViewStage.header AS h
						ON 	h.ID = v.HeaderID 

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.Element AS e
					   WHERE	e.Name = lvs.Name COLLATE SQL_Latin1_General_CP1_CS_AS 
								AND e.DataType = lvs.Type
								AND e.Units = lvs.Units COLLATE SQL_Latin1_General_CP1_CS_AS 
					)
;
				
--	3)	INSERT data into temp storage from PublishAudit
	CREATE TABLE	#changes
					(
						ID				int
					  , VectorID		int
					  , Name			nvarchar(250)
					  , Type			nvarchar(50)
					  , Units			nvarchar(250)
					  , Value			nvarchar(1000)
					  , NodeOrder		int
					  , OperatorName	nvarchar(50)
					  , ElementID		int
					)
;
	  INSERT	INTO #changes
					( ID, VectorID, Name, Type, Units, Value, NodeOrder, OperatorName, ElementID )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , i.NodeOrder		
			  , h.OperatorName
			  , e.ElementID
		FROM	labViewStage.vector_element AS i
				INNER JOIN	@Records 
						ON	RecordID = i.ID

				INNER JOIN 	labViewStage.vector AS v
						ON 	v.ID = i.VectorID
	
				INNER JOIN 	labViewStage.header AS h
						ON 	h.ID = v.HeaderID 
						
				INNER JOIN	hwt.Element AS e
						ON	e.Name = i.Name COLLATE SQL_Latin1_General_CP1_CS_AS 
								AND e.DataType = i.Type
								AND e.Units = i.Units COLLATE SQL_Latin1_General_CP1_CS_AS 
;
	IF	( @@ROWCOUNT = 0 )
		RETURN 0 
;

--	4)	INSERT vector element data from temp storage into hwt.VectorElement
	  INSERT	hwt.VectorElement
					( VectorID, ElementID, NodeOrder, ElementValue, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT 
				VectorID
			  , ElementID
			  , NodeOrder
			  , Value
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes
	ORDER BY	VectorID ASC, ElementID ASC
;
	RETURN 0 
;
END TRY
BEGIN CATCH
	 DECLARE	@pErrorData xml 
;
	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadVectorElementFromStage' ), TYPE
								)
;
	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION 
;
	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
;
	RETURN 55555 
;
END CATCH
