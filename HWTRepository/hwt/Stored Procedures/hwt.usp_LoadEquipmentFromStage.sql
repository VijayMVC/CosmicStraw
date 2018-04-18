CREATE PROCEDURE	hwt.usp_LoadEquipmentFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadEquipmentFromStage
    Abstract:   Load equipment data from stage to hwt.Equipment and hwt.HeaderEquipment

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE equipment from temp storage into hwt.Equipment
    3)  MERGE header equipment from temp storage into hwt.HeaderEquipment

    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

    --  define temp storage tables
    IF  ( 1 = 0 )
		BEGIN 
			CREATE TABLE	#inserted
				(
					ID                  int
				  , HeaderID            int
				  , Description         nvarchar(100)
				  , Asset               nvarchar(50)
				  , CalibrationDueDate  nvarchar(50)
				  , CostCenter          nvarchar(50)
				) 
				;
		END 
		
	CREATE TABLE 	#changes
		(
			ID                  int
		  , HeaderID            int
		  , Description         nvarchar(100)
		  , Asset               nvarchar(50)
		  , CalibrationDueDate  nvarchar(50)
		  , CostCenter          nvarchar(50)
		  , OperatorName        nvarchar(50)
		  , HWTChecksum         int
		  , EquipmentID         int
		) 
		;

--  1)  INSERT data into temp storage from trigger
	  INSERT	#changes
					( ID, HeaderID, Description, Asset, CalibrationDueDate, CostCenter, OperatorName, HWTChecksum )
	  SELECT 	i.ID                  
			  , i.HeaderID            
			  , i.Description         
			  , i.Asset               
			  , CalibrationDueDate	=   CASE ISDATE( i.CalibrationDueDate )
														WHEN 1 THEN CONVERT( datetime, i.CalibrationDueDate )
														ELSE CONVERT( datetime, '1900-01-01' )
													END  
			  , i.CostCenter          
	  	      , h.OperatorName
			  , HWTChecksum     	=   BINARY_CHECKSUM
											(
												i.Description
											  , i.Asset
											  , i.CalibrationDueDate
											  , i.CostCenter
											)
		FROM 	#inserted AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID 
				;


--  2)  MERGE equipment from temp storage into hwt.Equipment
		WITH	cte AS
				(
				  SELECT 	DISTINCT 
							Asset               =   tmp.Asset
						  , Description         =   tmp.Description
						  , CalibrationDueDate  =   CASE ISDATE( tmp.CalibrationDueDate )
														WHEN 1 THEN CONVERT( datetime, tmp.CalibrationDueDate )
														ELSE CONVERT( datetime, '1900-01-01' )
													END
						  , CostCenter          =   tmp.CostCenter
						  , HWTChecksum         =   tmp.HWTChecksum
						  , UpdatedBy           =   tmp.OperatorName
					FROM 	#changes AS tmp
				)
	   MERGE 	INTO hwt.Equipment  AS tgt
				USING cte AS src
					ON src.Asset = tgt.Asset
						AND src.CalibrationDueDate = tgt.CalibrationDueDate
		
		WHEN 	MATCHED AND src.HWTChecksum != tgt.HWTChecksum 
				THEN  UPDATE
						 SET	tgt.Asset               =   src.Asset
							  , tgt.Description         =   src.Description
							  , tgt.CalibrationDueDate  =   src.CalibrationDueDate
							  , tgt.CostCenter          =   src.CostCenter
							  , tgt.HWTChecksum         =   src.HWTChecksum
							  , tgt.UpdatedBy           =   src.UpdatedBy
							  , tgt.UpdatedDate         =   GETDATE()

		WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT
						( 	
							Asset, Description, CalibrationDueDate, CostCenter
								, HWTChecksum, UpdatedBy, UpdatedDate 
						)		
					  VALUES
						(	src.Asset, src.Description, src.CalibrationDueDate, src.CostCenter
								, src.HWTChecksum, src.UpdatedBy, GETDATE()
						) 
				;

    --  Apply EquipmentID back into temp storage
      UPDATE	tmp
		 SET	EquipmentID =   e.EquipmentID
		FROM 	#changes AS tmp
				INNER JOIN hwt.Equipment AS e
						ON e.Asset = tmp.Asset
							AND e.CalibrationDueDate = tmp.CalibrationDueDate 
				; 


--  3)  MERGE header equipment from temp storage into hwt.HeaderEquipment
		WITH	cte AS
				(
				  SELECT 	HeaderID    =   chg.HeaderID
						  , EquipmentID =   chg.EquipmentID
						  , UpdatedBy   =   chg.OperatorName
					FROM 	#changes AS chg
				)
	   
	   MERGE 	INTO hwt.HeaderEquipment  AS tgt
				USING cte AS src
					ON src.HeaderID = tgt.HeaderID
						AND src.EquipmentID = tgt.EquipmentID

		WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT( HeaderID, EquipmentID, UpdatedBy, UpdatedDate )
					  VALUES( src.HeaderID, src.EquipmentID, src.UpdatedBy, GETDATE() ) 
				;

    	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@trancount > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH
