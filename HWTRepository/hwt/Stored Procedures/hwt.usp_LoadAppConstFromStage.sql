CREATE 	PROCEDURE hwt.usp_LoadAppConstFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadAppConstFromStage
    Abstract:   Load AppConst data from stage to hwt.AppConst and hwt.HeaderAppConst

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  INSERT new AppConst data from temp storage into hwt.AppConst
	3)	UPDATE AppConstID back into temp storage
	4)  INSERT header AppConst data from temp storage into hwt.HeaderAppConst

    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling


***********************************************************************************************************************************
*/	
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

    --  define temp storage tables
    IF  ( 1 = 0 )
		CREATE TABLE 	#inserted
						(
							ID          int
						  , HeaderID    int
						  , Name        nvarchar(100)
						  , Type        nvarchar(50)
						  , Units       nvarchar(50)
						  , Value       nvarchar(1000)
						  , CreatedDate	datetime
						) 
						;

    CREATE TABLE 	#changes
					(
						ID              int
					  , HeaderID        int
					  , Name            nvarchar(100)
					  , Type            nvarchar(50)
					  , Units           nvarchar(50)
					  , Value           nvarchar(50)
					  , OperatorName    nvarchar(1000)
					  , AppConstN		int
					  , AppConstID      int
					) 
					;

		
--  1)  INSERT data into temp storage from trigger
      INSERT	#changes
					( ID, HeaderID, Name, Type, Units, Value, OperatorName, AppConstN )
	  SELECT	i.ID          
              , i.HeaderID    
              , i.Name        
              , i.Type        
              , i.Units       
              , i.Value
			  , h.OperatorName
			  , AppConstN		=	existingCount.N + ROW_NUMBER() OVER( PARTITION BY i.HeaderID, i.Name, i.Type, i.Units ORDER BY i.ID )
		FROM 	#inserted AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID 
						
				OUTER APPLY
					(
					  SELECT 	COUNT(*) 
					    FROM	labViewStage.appConst_element AS lvs
					   WHERE	lvs.HeaderID = i.HeaderID 
									AND lvs.Name = i.Name 
									AND lvs.Type = i.Type
									AND lvs.Units = i.Units
					) AS existingCount(N)
				;


--  2)  INSERT new AppConst data from temp storage into hwt.AppConst
        WITH	cte AS
					(
					  SELECT 	DISTINCT 
								Name        =   tmp.Name
							  , DataType    =   tmp.Type
							  , Units       =   tmp.Units
						FROM 	#changes AS tmp
					
					  EXCEPT 
					  SELECT 	Name        
							  , DataType    
							  , Units       
						FROM 	hwt.AppConst 
					)
			
	  INSERT	hwt.AppConst 
					( Name, DataType, Units, UpdatedBy, UpdatedDate ) 
	  SELECT 	DISTINCT 
				Name 		=	cte.Name
			  , DataType    =	cte.DataType
			  , Units       =	cte.Units
			  , UpdatedBy	=	tmp.OperatorName   
			  , UpdatedDate	=	SYSDATETIME()
		FROM 	cte
				INNER JOIN 	#changes AS tmp 
						ON 	tmp.Name = cte.Name 
								AND tmp.Type = cte.DataType
								AND	tmp.Units = cte.Units 
				; 

--	3)	UPDATE AppConstID back into temp storage
	  UPDATE 	tmp
		 SET 	AppConstID  =   ac.AppConstID
		FROM 	#changes AS tmp
				INNER JOIN hwt.AppConst AS ac
						ON ac.Name = tmp.Name
							AND ac.DataType = tmp.Type
							AND ac.Units = tmp.Units 
				;


--  4)  INSERT header AppConst data from temp storage into hwt.HeaderAppConst
	  INSERT	hwt.HeaderAppConst
					( HeaderID, AppConstID, AppConstN, AppConstValue, UpdatedBy, UpdatedDate ) 

	  SELECT 	HeaderID
			  , AppConstID
			  , AppConstN
			  , Value
			  , OperatorName
			  , SYSDATETIME()
		FROM 	#changes
				; 

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData	xml ; 

      SELECT	@pErrorData	=	( 
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
											FOR XML PATH( 'usp_LoadAppConstFromStage' ), TYPE
								)
				;

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	 EXECUTE	eLog.log_CatchProcessing 
					@pProcID 	=	@@PROCID 
				  , @pErrorData	=	@pErrorData 
				; 
	 
	RETURN 55555 ; 

END CATCH
