CREATE PROCEDURE	hwt.usp_LoadVectorResultFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadVectorResultFromStage
    Abstract:   Load changed result elements from stage to hwt.Result and hwt.VectorResult

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE elements from temp storage into hwt.Result
    3)  MERGE result elements into hwt.VectorResult

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
					ID          int
				  , VectorID    int
				  , Name        nvarchar(250)
				  , Type        nvarchar(50)
				  , Units       nvarchar(50)
				  , Value       nvarchar(max)
				) 
				;
		END 

    CREATE TABLE	#changes
		(
            ID              	int
          , VectorID        	int
		  , VectorResultNumber	int 
          , Name            	nvarchar(250)
          , Type            	nvarchar(50)
          , Units           	nvarchar(50)
          , ResultN         	int
          , ResultValue     	nvarchar(250)
          , OperatorName    	nvarchar(50)
          , HWTChecksum     	int
          , ResultID        	int
        ) 
		;

--	1)	Scrub any escaped XML from input 
	DECLARE 	@EscapedXMLPattern	nvarchar(20) = N'%&%;%' ;
	IF	EXISTS	( SELECT 1 FROM #changes WHERE PATINDEX( Name, @EscapedXMLPattern ) > 0 ) 
		BEGIN 
			  UPDATE 	#changes 
			     SET 	Name 	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( Name, '&amp;', '&' ), '&lt;', '<' ), '&gt', '>' ), '&quot', '"' ), '&apos;', '''' )
			   WHERE    PATINDEX( Name, @EscapedXMLPattern ) > 0
						;
		END
		
	IF	EXISTS	( SELECT 1 FROM #changes WHERE PATINDEX( Type, @EscapedXMLPattern ) > 0 ) 
		BEGIN 
			  UPDATE 	#changes 
			     SET 	Name 	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( Type, '&amp;', '&' ), '&lt;', '<' ), '&gt', '>' ), '&quot', '"' ), '&apos;', '''' )
			   WHERE    PATINDEX( Type, @EscapedXMLPattern ) > 0
						;
		END
		
	IF	EXISTS	( SELECT 1 FROM #changes WHERE PATINDEX( Units, @EscapedXMLPattern ) > 0 ) 
		BEGIN 
			  UPDATE 	#changes 
			     SET 	Units 	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( Units, '&amp;', '&' ), '&lt;', '<' ), '&gt', '>' ), '&quot', '"' ), '&apos;', '''' )
			   WHERE    PATINDEX( Units, @EscapedXMLPattern ) > 0
						;
		END		
		
	IF	EXISTS	( SELECT 1 FROM #changes WHERE PATINDEX( ResultValue, @EscapedXMLPattern ) > 0 ) 
		BEGIN 
			  UPDATE 	#changes 
			     SET 	ResultValue 	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( ResultValue, '&amp;', '&' ), '&lt;', '<' ), '&gt', '>' ), '&quot', '"' ), '&apos;', '''' )
			   WHERE    PATINDEX( ResultValue, @EscapedXMLPattern ) > 0
						;
		END		
	
				
--  2)  INSERT data into temp storage from trigger
      INSERT 	#changes
					( 
						ID, VectorID, VectorResultNumber, Name, Type
							, Units, ResultN, ResultValue, OperatorName, HWTChecksum 
					)
      SELECT	i.ID
			  , i.VectorID
			  , ROW_NUMBER() OVER( PARTITION BY i.VectorID, i.ID ORDER BY i.ID ) 
			  , i.Name
			  , i.Type
			  , i.Units
			  , ResultN         =   x.ItemNumber
			  , ResultValue     =   x.Item
			  , h.OperatorName
			  , HWTChecksum     =   BINARY_CHECKSUM
									(
										Name
									  , Type
									  , Units
									)
		FROM	#inserted AS i
				INNER JOIN labViewStage.vector AS v
						ON v.ID = i.VectorID
				
				INNER JOIN labViewStage.header AS h
						ON h.ID = v.HeaderID

				CROSS APPLY utility.ufn_SplitString( i.Value, ',' ) AS x 
				;				

--  3)  MERGE elements from temp storage into hwt.Result
        WITH	cte AS
				(
				  SELECT 	DISTINCT
							Name        =   tmp.Name
						  , DataType    =   tmp.Type
						  , Units       =   tmp.Units
						  , HWTChecksum =   tmp.HWTChecksum
						  , UpdatedBy   =   tmp.OperatorName
					FROM 	#changes AS tmp
				)
				
	   MERGE 	INTO hwt.Result AS tgt
				USING cte AS src
					ON src.Name = tgt.Name
    
		WHEN 	MATCHED AND src.HWTChecksum != tgt.HWTChecksum 
				THEN  UPDATE
						 SET	tgt.DataType    =   src.DataType
							  , tgt.Units       =   src.Units
							  , tgt.HWTChecksum =   src.HWTChecksum
							  , tgt.UpdatedBy   =   src.UpdatedBy
							  , tgt.UpdatedDate =   GETDATE()
		
		WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT	
						( Name, DataType, Units, HWTChecksum, UpdatedBy, UpdatedDate )
					  VALUES	
						( src.Name, src.DataType, src.Units, src.HWTChecksum, src.UpdatedBy, GETDATE() ) 
				;

    --  Apply ResultID back into temp storage
      UPDATE	tmp
         SET 	ResultID    =   r.ResultID
        FROM	#changes AS tmp
				INNER JOIN hwt.Result AS r
						ON r.Name = tmp.Name 
				;


--  4)  MERGE result elements from temp storage into hwt.VectorResult
		WITH	cte AS
				(
				  SELECT	VectorID    		=   c.VectorID
						  , ResultID    		=   r.ResultID
						  , VectorResultNumber	=	c.VectorResultNumber
						  , ResultN     		=   c.ResultN
						  , ResultValue 		=   c.ResultValue
					FROM	#changes AS c
							INNER JOIN hwt.Result AS r
									ON r.ResultID = c.ResultID
				)
				
			  , cteVectorResult AS
				(	
				  SELECT	*
					FROM    hwt.VectorResult AS vr
				   WHERE   	EXISTS
							(	  
							  SELECT 	1 
								FROM 	#changes AS c
							   WHERE 	c.VectorID = vr.VectorID 
											AND c.ResultID				=	vr.ResultID 
											AND c.VectorResultNumber	=	vr.VectorResultNumber 
							)
				)
				
	   MERGE 	INTO cteVectorResult AS tgt
				USING cte AS src
					ON  src.VectorID 				=	tgt.VectorID
						AND src.ResultID			=	tgt.ResultID 
						AND src.VectorResultNumber	= 	tgt.VectorResultNumber
						AND src.ResultN 			= 	tgt.ResultN
    
	    WHEN 	MATCHED AND src.ResultValue <> tgt.ResultValue
				THEN  UPDATE
						 SET	tgt.ResultValue =   src.ResultValue
    
		WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT	( VectorID, ResultID, VectorResultNumber, ResultN, ResultValue )
					  VALUES	( src.VectorID, src.ResultID, src.VectorResultNumber, src.ResultN, src.ResultValue ) 
				;

    RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) 
		ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH
