CREATE PROCEDURE	hwt.usp_LoadEquipmentFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadEquipmentFromStage
	Abstract:	Load equipment data from stage to hwt.Equipment and hwt.HeaderEquipment

	Logic Summary
	-------------
	1)	INSERT new Equipment data from temp storage into hwt
	2)	INSERT data into temp storage from PublishAudit and labViewStage
	3)	INSERT header AppConst data from temp storage into hwt.HeaderEquipment
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
	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.equipment_element' ) 
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

--	2)	INSERT new Equipment data from temp storage into hwt
	  INSERT	hwt.Equipment
					( Asset, Description, CostCenter, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				Asset				=	lvs.Asset
			  , Description			=	lvs.Description
			  , CostCenter			=	lvs.CostCenter
			  , UpdatedBy			=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Asset, lvs.Description, lvs.CostCenter ORDER BY lvs.ID )
			  , UpdatedDate			=	SYSDATETIME()
		FROM	labViewStage.equipment_element AS lvs
				INNER JOIN	@Records
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = lvs.HeaderID

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.Equipment AS e
					   WHERE	e.Asset = lvs.Asset
								AND e.Description = lvs.Description
								AND e.CostCenter = lvs.CostCenter
					)
;

--	3)	INSERT data into temp storage from PublishAudit
	  CREATE	TABLE #changes
				(
					ID					int
				  , HeaderID			int
				  , Asset				nvarchar(50)
				  , Description			nvarchar(250)
				  , CostCenter			nvarchar(50)
				  , CalibrationDueDate	nvarchar(50)
				  , NodeOrder			int
				  , CreatedDate			datetime2(3)
				  , OperatorName		nvarchar(50)
				  , EquipmentID			int
				)
;
	  INSERT	#changes
					(
						ID, HeaderID, Description, Asset, CalibrationDueDate, CostCenter
							, NodeOrder, CreatedDate, OperatorName, EquipmentID
					)
	  SELECT	i.ID
			  , i.HeaderID
			  , i.Description
			  , i.Asset
			  , CalibrationDueDate	=	CASE ISDATE( i.CalibrationDueDate )
														WHEN 1 THEN CONVERT( datetime, i.CalibrationDueDate )
														ELSE CONVERT( datetime, '1900-01-01' )
										END
			  , i.CostCenter
			  , i.NodeOrder
			  , i.CreatedDate
			  , h.OperatorName
			  , e.EquipmentID
		FROM	labViewStage.equipment_element AS i
				INNER JOIN	@Records
						ON	RecordID = i.ID

				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID

				INNER JOIN	hwt.Equipment AS e
						ON	e.Asset = i.Asset
							AND e.Description = i.Description
							AND e.CostCenter = i.CostCenter
;

--	4)	INSERT header equipment from temp storage into hwt.HeaderEquipment
	  INSERT	hwt.HeaderEquipment
					( HeaderID, EquipmentID, NodeOrder, CalibrationDueDate, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT 
				HeaderID
			  , EquipmentID
			  , NodeOrder
			  , CalibrationDueDate
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes
;
	RETURN 0 
;
END TRY
BEGIN CATCH
	 DECLARE	@pErrorData xml 
;
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
	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION 
;
	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
;
	RETURN 55555 
;
END CATCH
