CREATE	PROCEDURE hwt.usp_LoadVectorResultFromStage
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
	 
	 DECLARE	@Records 	TABLE	( RecordID int ) ; 

--	1)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit
	  OUTPUT 	deleted.RecordID 
	    INTO	@Records( RecordID ) 
	   WHERE	ObjectID = @ObjectID
				;
	 
	 
--	2)	INSERT new Result data from temp storage into hwt
	  INSERT	hwt.Result
					( Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				Name		=	lvs.Name
			  , DataType	=	lvs.Type
			  , Units		=	lvs.Units
			  , UpdatedBy	=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , UpdatedDate	=	SYSDATETIME()
		FROM	labViewStage.result_element AS lvs
				INNER JOIN	@Records 
						ON	RecordID = lvs.ID

				INNER JOIN 	labViewStage.vector AS v 
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
					( VectorID, ResultID, NodeOrder, IsArray, IsExtended, UpdatedBy, UpdatedDate ) 
	  SELECT	DISTINCT
				VectorID	=	lvs.VectorID
			  , ResultID	=	r.ResultID
			  , NodeOrder	=	ISNULL( NULLIF( lvs.NodeOrder, 0 ), ROW_NUMBER() OVER( PARTITION BY lvs.VectorID ORDER BY lvs.ID ) ) 
			  , IsArray		=	CONVERT( bit, ISJSON( lvs.Value ) )
			  , IsExtended	=	CASE ISJSON( lvs.Value ) 
									WHEN 	1 THEN 1 
									ELSE 	CASE  
												WHEN LEN( lvs.Value ) > 100 THEN 1 
												ELSE 0 
											END 
								END 
			  , UpdatedBy	=	FIRST_VALUE( h.OperatorName ) OVER( ORDER BY h.ID )
			  , UpdatedDate	=	SYSDATETIME()
		FROM	labViewStage.result_element AS lvs
				INNER JOIN	@Records 
						ON	RecordID = lvs.ID	

				INNER JOIN 	labViewStage.vector AS v 
						ON	v.ID = lvs.VectorID
							
				INNER JOIN	labViewStage.header AS h
						ON	h.ID = v.HeaderID

				INNER JOIN 	hwt.Result AS r 
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
					  , OperatorName		nvarchar(50)
					  , ResultID			int
					  , VectorResultID		int
					)
					;

	  INSERT	#changes
					( ID, VectorID, Name, Type, Units, Value, NodeOrder, OperatorName, ResultID, VectorResultID )
	  SELECT	i.ID
			  , i.VectorID
			  , i.Name			
			  , i.Type			
			  , i.Units
			  , i.Value			
			  , i.NodeOrder		
			  , h.OperatorName
			  , r.ResultID
			  , vr.VectorResultID
		FROM	labViewStage.result_element AS i
				INNER JOIN	@Records 
						ON	RecordID = i.ID

				INNER JOIN	labViewStage.vector AS v
						ON	v.ID = i.VectorID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = v.HeaderID
						
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
		--	LEN( Value ) < 100 
	  INSERT	hwt.VectorResultValue 
					( VectorResultID, ResultValue )
	  SELECT	VectorResultID	=	i.VectorResultID
			  , ResultValue		=	i.Value
		FROM	#changes AS i

	   WHERE	ISJSON( i.Value ) = 0 
					AND LEN( i.Value ) < = 100 
				;
				
		--	LEN( Value ) > 100 
	  INSERT	hwt.VectorResultExtended
					( VectorResultID, ResultValue )
		
	  SELECT	VectorResultID	=	i.VectorResultID
			  , ResultValue		=	i.Value
		FROM	#changes AS i

	   WHERE	ISJSON( i.Value ) = 1 OR LEN( i.Value ) > 100 
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

