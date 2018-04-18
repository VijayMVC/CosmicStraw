CREATE PROCEDURE	hwt.usp_LoadOptionFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadOptionFromStage
    Abstract:   Load changed test options data from stage to hwt.Option and hwt.HeaderOption

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE test options from temp storage into hwt.Option
    3)  MERGE header test options from temp storage into hwt.HeaderOption

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
        CREATE TABLE 	#inserted
			(
                ID          int
              , HeaderID    int
              , Name        nvarchar(100)
              , Type        nvarchar(50)
              , Units       nvarchar(50)
              , Value       nvarchar(1000)
            ) ;

    CREATE TABLE	#changes
		(
            ID              int
          , HeaderID        int
          , Name            nvarchar(100)
          , Type            nvarchar(50)
          , Units           nvarchar(50)
          , Value           nvarchar(1000)
          , OperatorName    nvarchar(50)
          , HWTChecksum     int
          , OptionID        int
        ) ;

--  1)  INSERT data into temp storage from trigger
      INSERT 	INTO #changes
					( ID, HeaderID, Name, Type, Units, Value, OperatorName, HWTChecksum )
      SELECT 	i.ID          
              , i.HeaderID    
              , i.Name        
              , i.Type        
              , i.Units       
              , i.Value       
			  , h.OperatorName
			  , HWTChecksum     =   BINARY_CHECKSUM
										(
											i.Name
										  , i.Type
										  , i.Units
										)
		FROM	#inserted AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID ;


--  2)  MERGE test options from temp storage into hwt.Option
		WITH	cte AS
				(
				  SELECT	DISTINCT 
							Name        =   tmp.Name
						  , DataType    =   tmp.Type
						  , Units       =   tmp.Units
						  , HWTChecksum =   tmp.HWTChecksum
						  , UpdatedBy   =   tmp.OperatorName
					FROM 	#changes AS tmp
				)

	   MERGE 	INTO hwt.[Option] AS tgt
				USING cte AS src
					ON src.Name = tgt.Name
    
		WHEN 	MATCHED AND src.HWTChecksum != tgt.HWTChecksum 
				THEN  UPDATE
						 SET 	tgt.DataType    =   src.DataType
							  , tgt.Units       =   src.Units
							  , tgt.HWTChecksum =   src.HWTChecksum
							  , tgt.UpdatedBy   =   src.UpdatedBy
							  , tgt.UpdatedDate =   GETDATE()
    
		WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT	( Name, DataType, Units, HWTChecksum, UpdatedBy, UpdatedDate )
					  VALUES	( src.Name, src.DataType, src.Units, src.HWTChecksum, src.UpdatedBy, GETDATE() ) ;

    --  Apply OptionID back into temp storage
      UPDATE 	tmp
		 SET 	OptionID    =   o.OptionID
		FROM 	#changes AS tmp
				INNER JOIN
					hwt.[Option] AS o
						ON o.Name = tmp.Name ;


--  3)  MERGE header test options from temp storage into hwt.HeaderOption
		WITH	cte AS
				(
				  SELECT 	HeaderID    =   c.HeaderID
						  , OptionID    =   o.OptionID
						  , OptionValue =   c.Value
						  , UpdatedBy   =   c.OperatorName
					FROM 	#changes AS c
							INNER JOIN hwt.[Option] AS o
									ON c.OptionID = o.OptionID
				)
	   
	   MERGE 	INTO hwt.HeaderOption AS tgt
				USING cte AS src
					ON  src.HeaderID = tgt.HeaderID
						AND src.OptionID = tgt.OptionID
    
		WHEN 	MATCHED AND src.OptionValue <> tgt.OptionValue
				THEN  UPDATE
						 SET 	tgt.OptionValue =   src.OptionValue
							  , tgt.UpdatedBy   =   src.UpdatedBy
							  , tgt.UpdatedDate =   GETDATE()
		
		WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT	( HeaderID, OptionID, OptionValue, UpdatedBy, UpdatedDate )
					  VALUES	( src.HeaderID, src.OptionID, src.OptionValue, src.UpdatedBy, GETDATE() ) ;

 	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH
