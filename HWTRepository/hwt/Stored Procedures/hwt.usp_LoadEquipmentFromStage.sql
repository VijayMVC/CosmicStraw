CREATE PROCEDURE
	hwt.usp_LoadEquipmentFromStage
		(
			@pHeaderXML		xml
		)
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

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@loadHeader		TABLE	( HeaderID	int ) ;
	 DECLARE	@lvsRecord		TABLE	( RecordID	int ) ;


--	1)	SELECT the HeaderIDs that need to be published

	  INSERT	@loadHeader( HeaderID )
	  SELECT	loadHeader.xmlData.value( '@value[1]', 'int' )
		FROM	@pHeaderXML.nodes('LoadHeader/HeaderID') AS loadHeader(xmlData)
				;


--	2)	SELECT the labViewStage records that need to be published
	  INSERT	@lvsRecord( RecordID )
	  SELECT	ID
		FROM	labViewStage.equipment_element AS lvs
				INNER JOIN	@loadHeader AS h
						ON	h.HeaderID = lvs.HeaderID
				;

	IF	( @@ROWCOUNT = 0 ) RETURN ;


--	1)	INSERT new Equipment data from temp storage into hwt
	  INSERT	hwt.Equipment
					( Asset, Description, CostCenter, CreatedBy, CreatedDate )
	  SELECT	DISTINCT
				Asset				=	lvs.Asset
			  , Description			=	lvs.Description
			  , CostCenter			=	lvs.CostCenter
			  , CreatedBy			=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Asset, lvs.Description, lvs.CostCenter ORDER BY lvs.ID )
			  , CreatedDate			=	SYSDATETIME()
		FROM	labViewStage.equipment_element AS lvs
				INNER JOIN	@lvsRecord
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


--	3)	INSERT header equipment from temp storage into hwt.HeaderEquipment
	  INSERT	hwt.HeaderEquipment
					( HeaderID, EquipmentID, NodeOrder, CalibrationDueDate )
	  SELECT	HeaderID			=	i.HeaderID
			  , EquipmentID			=	e.EquipmentID
			  , NodeOrder			=	i.NodeOrder
			  , CalibrationDueDate	=	CASE ISDATE( i.CalibrationDueDate )
														WHEN 1 THEN CONVERT( datetime, i.CalibrationDueDate )
														ELSE CONVERT( datetime, '1900-01-01' )
										END
		FROM	labViewStage.equipment_element AS i
				INNER JOIN	@lvsRecord
						ON	RecordID = i.ID

				INNER JOIN	hwt.Equipment AS e
						ON	e.Asset = i.Asset
							AND e.Description = i.Description
							AND e.CostCenter = i.CostCenter
				;


	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	lvs.*
												FROM	labViewStage.equipment_element AS lvs
														INNER JOIN	@lvsRecord
																ON	RecordID = lvs.ID
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
