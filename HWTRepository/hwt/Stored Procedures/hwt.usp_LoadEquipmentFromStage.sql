CREATE PROCEDURE	hwt.usp_LoadEquipmentFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadEquipmentFromStage
	Abstract:	Load equipment data from stage to hwt.Equipment and hwt.HeaderEquipment

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT data into temp storage from trigger
	3)	INSERT new Equipment data from temp storage into hwt.Equipment
	4)	UPDATE EquipmentID back into temp storage
	5)	INSERT header Equipment data from temp storage into hwt.HeaderEquipment
	6)	UPDATE PublishDate on labViewStage.equipment_element
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

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.equipment_element' ) ;

--	2)	INSERT data into temp storage from PublishAudit
	  CREATE	TABLE #changes
				(
					ID					int
				  , HeaderID			int
				  , Description			nvarchar(100)
				  , Asset				nvarchar(50)
				  , CalibrationDueDate	nvarchar(50)
				  , CostCenter			nvarchar(50)
				  , NodeOrder			int
				  , CreatedDate			datetime2(3)
				  , OperatorName		nvarchar(50)
				  , EquipmentID			int
				)
				;

	  INSERT	#changes
					( ID, HeaderID, Description, Asset, CalibrationDueDate, CostCenter, NodeOrder, CreatedDate, OperatorName )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.Description
			  , i.Asset
			  , CalibrationDueDate	=	CASE ISDATE( i.CalibrationDueDate )
														WHEN 1 THEN CONVERT( datetime, i.CalibrationDueDate )
														ELSE CONVERT( datetime, '1900-01-01' )
													END
			  , i.CostCenter
			  , NodeOrder			=	ISNULL( NULLIF( i.NodeOrder, 0 ), i.ID )
			  , i.CreatedDate
			  , h.OperatorName
		FROM	labViewStage.equipment_element AS i
				INNER JOIN	labViewStage.PublishAudit AS pa
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = i.ID

				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	3)	INSERT new Equipment data from temp storage into hwt.Equipment
		--	cte is the set of Equipment data that does not already exist on hwt
		--	newData is the set of data from cte with ID attached
		WITH	cte AS
					(
					  SELECT	Asset				=	tmp.Asset
							  , Description			=	tmp.Description
							  , CostCenter			=	tmp.CostCenter
						FROM	#changes AS tmp

					  EXCEPT
					  SELECT	Asset
							  , Description
							  , CostCenter
						FROM	hwt.Equipment
					)

			  , newData AS
					(
					  SELECT	DISTINCT
								EquipmentID		=	MIN( ID ) OVER( PARTITION BY c.Asset, c.Description, c.CostCenter )
							  , Asset			=	cte.Asset
							  , Description		=	cte.Description
							  , CostCenter		=	cte.CostCenter
						FROM	#changes AS c
								INNER JOIN cte
										ON cte.Asset = c.Asset
											AND cte.Description = c.Description
											AND cte.CostCenter = c.CostCenter
					)

	  INSERT	hwt.Equipment
					( EquipmentID, Asset, Description, CostCenter, UpdatedBy, UpdatedDate )
	  SELECT	EquipmentID			=	newData.EquipmentID
			  , Asset				=	newData.Asset
			  , Description			=	newData.Description
			  , CostCenter			=	newData.CostCenter
			  , UpdatedBy			=	x.OperatorName
			  , UpdatedDate			=	SYSDATETIME()
		FROM	newData
				CROSS APPLY
					( SELECT OperatorName FROM #changes AS c WHERE c.ID = newData.EquipmentID ) AS x
				;


--	4)	UPDATE EquipmentID back into temp storage
	  UPDATE	tmp
		 SET	EquipmentID =	e.EquipmentID
		FROM	#changes AS tmp
				INNER JOIN hwt.Equipment AS e
						ON e.Asset = tmp.Asset
							AND e.Description = tmp.Description
							AND e.CostCenter = tmp.CostCenter
				;


--	5)	INSERT header equipment from temp storage into hwt.HeaderEquipment
	  INSERT	hwt.HeaderEquipment
					( HeaderID, EquipmentID, NodeOrder, CalibrationDueDate, UpdatedBy, UpdatedDate )
	  SELECT	HeaderID
			  , EquipmentID
			  , NodeOrder
			  , CalibrationDueDate
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
								  SELECT
											(
											  SELECT	*
												FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadEquipmentFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH
