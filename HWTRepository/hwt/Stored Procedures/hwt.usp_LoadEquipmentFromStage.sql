CREATE PROCEDURE	hwt.usp_LoadEquipmentFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadEquipmentFromStage
	Abstract:	Load equipment data from stage to hwt.Equipment and hwt.HeaderEquipment

	Logic Summary
	-------------
	1)	INSERT data into temp storage from trigger
	2)	INSERT new Equipment data from temp storage into hwt.Equipment
	3)	UPDATE EquipmentID back into temp storage
	4)	INSERT header Equipment from temp storage into hwt.HeaderEquipment


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
	  CREATE	TABLE #inserted
				(
					ID					int
				  , HeaderID			int
				  , Description			nvarchar(100)
				  , Asset				nvarchar(50)
				  , CalibrationDueDate	nvarchar(50)
				  , CostCenter			nvarchar(50)
				  , CreatedDate			datetime
				)
				;

	  CREATE	TABLE #changes
				(
					ID					int
				  , HeaderID			int
				  , Description			nvarchar(100)
				  , Asset				nvarchar(50)
				  , CalibrationDueDate	nvarchar(50)
				  , CostCenter			nvarchar(50)
				  , OperatorName		nvarchar(50)
				  , EquipmentN			int
				  , EquipmentID			int
				)
				;

--	1)	INSERT data into temp storage from trigger
	  INSERT	#changes
					( ID, HeaderID, Description, Asset, CalibrationDueDate, CostCenter, OperatorName, EquipmentN )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.Description
			  , i.Asset
			  , CalibrationDueDate	=	CASE ISDATE( i.CalibrationDueDate )
														WHEN 1 THEN CONVERT( datetime, i.CalibrationDueDate )
														ELSE CONVERT( datetime, '1900-01-01' )
													END
			  , i.CostCenter
			  , h.OperatorName
			  , EquipmentN			=	existingCount.N + ROW_NUMBER() OVER( PARTITION BY i.HeaderID, i.Asset, i.Description, i.CostCenter
																				 ORDER BY i.ID )
		FROM	#inserted AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID

				OUTER APPLY
					(
					  SELECT	COUNT(*)
						FROM	labViewStage.equipment_element AS lvs
					   WHERE	lvs.HeaderID = i.HeaderID
									AND lvs.Asset = i.Asset
									AND lvs.Description = i.Description
									AND lvs.CostCenter = i.CostCenter
					) AS existingCount(N)
				;


--	2)	INSERT new Equipment data from temp storage into hwt.Equipment
		WITH	cte AS
				(
				  SELECT	DISTINCT
							Asset				=	tmp.Asset
						  , Description			=	tmp.Description
						  , CostCenter			=	tmp.CostCenter
					FROM	#changes AS tmp

				  EXCEPT
				  SELECT	Asset
						  , Description
						  , CostCenter
					FROM	hwt.Equipment
				)

	  INSERT	hwt.Equipment
					( Asset, Description, CostCenter, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				Asset				=	cte.Asset
			  , Description			=	cte.Description
			  , CostCenter			=	cte.CostCenter
			  , UpdatedBy			=	tmp.OperatorName
			  , UpdatedDate			=	SYSDATETIME()
		FROM	cte
				INNER JOIN	#changes AS tmp
						ON	tmp.Asset = cte.Asset
								AND tmp.Description = cte.Description
								AND tmp.CostCenter = cte.CostCenter
				;

--	3)	UPDATE EquipmentID back into temp storage
	  UPDATE	tmp
		 SET	EquipmentID =	e.EquipmentID
		FROM	#changes AS tmp
				INNER JOIN hwt.Equipment AS e
						ON e.Asset = tmp.Asset
							AND e.Description = tmp.Description
							AND e.CostCenter = tmp.CostCenter
				;


--	4)	INSERT header equipment from temp storage into hwt.HeaderEquipment
	  INSERT	hwt.HeaderEquipment
					( HeaderID, EquipmentID, EquipmentN, CalibrationDueDate, UpdatedBy, UpdatedDate )
	  SELECT	HeaderID
			  , EquipmentID
			  , EquipmentN
			  , CalibrationDueDate
			  , OperatorName
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
