CREATE PROCEDURE	hwt.usp_LoadHeaderFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadHeaderFromStage
    Abstract:   Load changed header data from stage to hwt.Header

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  DELETE header records that are unchanged from temp storage
    3)  INSERT header tags associated with header changes
    4)  MERGE header changes from temp storage into hwt.Header
    5)  INSERT tags from temp storage into hwt.Tag
    6)  MERGE new header tag data into hwt.HeaderTag

    Parameters
    ----------
	@pIsFromLabView		bit		denotes whether or not incoming data is inserted from active HWT connection
								default is 1

    Notes
    -----
	When data is being inserted by HWT, there are no tags for either Project or HWIncrement
		For legacy XML, those tags will come from directly from the XML
	

    Revision
    --------
    carsoc3     2018-04-27      production release

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

    --  define temp storage tables
    IF  ( 1 = 0 )
		CREATE TABLE #inserted
			(
                ID                  int
              , ResultFile          nvarchar(1000)
              , StartTime           nvarchar(100)
              , FinishTime          nvarchar(100)
              , TestDuration        nvarchar(100)
              , ProjectName         nvarchar(100)
              , FirmwareRev         nvarchar(100)
              , HardwareRev         nvarchar(100)
              , PartSN              nvarchar(100)
              , OperatorName        nvarchar(100)
              , TestMode            nvarchar(50)
              , TestStationID       nvarchar(100)
              , TestName            nvarchar(250)
              , TestConfigFile      nvarchar(400)
              , TestCodePathName    nvarchar(400)
              , TestCodeRev         nvarchar(100)
              , HWTSysCodeRev       nvarchar(100)
              , KdrivePath          nvarchar(400)
              , Comments            nvarchar(max)
              , ExternalFileInfo    nvarchar(max)
			  , IsLegacyXML			int
			  , CreatedDate			datetime
            ) 
			;
	
    CREATE TABLE #changes
		(
            ID                  int
          , ResultFile          nvarchar(1000)
          , StartTime           nvarchar(100)
          , FinishTime          nvarchar(100)
          , TestDuration        nvarchar(100)
          , ProjectName         nvarchar(100)
          , FirmwareRev         nvarchar(100)
          , HardwareRev         nvarchar(100)
          , PartSN              nvarchar(100)
          , OperatorName        nvarchar(100)
          , TestMode            nvarchar(50)
          , TestStationID       nvarchar(100)
          , TestName            nvarchar(250)
          , TestConfigFile      nvarchar(400)
          , TestCodePathName    nvarchar(400)
          , TestCodeRev         nvarchar(100)
          , HWTSysCodeRev       nvarchar(100)
          , KdrivePath          nvarchar(400)
          , Comments            nvarchar(max)
          , ExternalFileInfo    nvarchar(max)
		  , IsLegacyXML			int
          , HWTChecksum         int
        ) 
		;


--  1)  INSERT data into temp storage from trigger
      INSERT 	#changes
					( 
						ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev
							, HardwareRev, PartSN, OperatorName, TestMode, TestStationID, TestName
							, TestConfigFile, TestCodePathName, TestCodeRev, HWTSysCodeRev, KdrivePath
							, Comments, ExternalFileInfo, IsLegacyXML, HWTChecksum
					)
      SELECT	ID
              , ResultFile          
              , StartTime           
              , FinishTime          
              , TestDuration        
              , ProjectName         
              , FirmwareRev         
              , HardwareRev         
              , PartSN              
              , OperatorName        
              , TestMode            
              , TestStationID       
              , TestName            
              , TestConfigFile      
              , TestCodePathName    
              , TestCodeRev         
              , HWTSysCodeRev       
              , KdrivePath          
              , Comments            
              , ExternalFileInfo 
			  , IsLegacyXML
			  , HWTChecksum 		=   BINARY_CHECKSUM
										(
											ResultFile
										  , StartTime
										  , FinishTime
										  , TestDuration
										  , ProjectName
										  , FirmwareRev
										  , HardwareRev
										  , PartSN
										  , OperatorName
										  , TestMode
										  , TestStationID
										  , TestName
										  , TestConfigFile
										  , TestCodePathName
										  , TestCodeRev
										  , HWTSysCodeRev
										  , KdrivePath
										  , LEFT( Comments, 500 )
										  , LEFT( ExternalFileInfo, 500 )
										)
		FROM	#inserted
				;


--  2)  DELETE header records that are unchanged from temp storage
        --  HWTChecksum includes tag data, so this means that tags are also unchanged
      DELETE 	tmp
		FROM 	#changes AS tmp
				INNER JOIN hwt.Header as h
						ON h.HWTChecksum = tmp.HWTChecksum 
				;

	   
    --  exit if no records remain ( there were no header changes )
    IF NOT EXISTS( SELECT 1 FROM #changes )
        RETURN 0 ;


--  3)  INSERT header tags associated with header changes
    DROP TABLE IF EXISTS #tags ;
	
	CREATE TABLE #tags
		(	
			HeaderID    	int 			
		  , TagTypeID   	int 			
		  , Name        	nvarchar(50) 	
		  , Description 	nvarchar(200) 	
		  , UpdatedBy   	sysname 		
		  , TagID       	int 			
		) 
		; 

    --  INSERT tags into temp storage from following header fields:
    --      OperatorName
    --      FirmwareRevision
    --      DeviceSN
	--		TestMode
	
	  INSERT 	#tags
					( HeaderID, TagTypeID, Name, Description, UpdatedBy, TagID ) 
	
      SELECT 	HeaderID    =   tmp.ID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   tmp.OperatorName
			  , Description =   'Operator loaded from test dataset'
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
		FROM 	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType
	   
	   WHERE 	tType.Name = 'Operator'
					AND ISNULL( tmp.OperatorName, '' ) != ''
    
	   UNION
	  SELECT	HeaderID    =   tmp.ID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   tmp.FirmwareRev
			  , Description =   N'Firmware Rev loaded from test dataset'
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
		FROM 	#changes AS tmp
				CROSS JOIN  hwt.TagType AS tType

	   WHERE 	tType.Name = N'FWRevision'
					AND ISNULL( tmp.FirmwareRev, '' ) != ''
    
	   UNION
	  SELECT	HeaderID    =   tmp.ID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   RTRIM( LTRIM( x.Item ) )
			  , Description =   N'Device SN loaded from test dataset'
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
		FROM 	#changes AS tmp
				CROSS JOIN 	hwt.TagType AS tType
				CROSS APPLY	utility.ufn_SplitString
					( tmp.PartSN, ',' ) AS x	   
	   WHERE 	tType.Name = N'DeviceSN'
					AND ISNULL( RTRIM( LTRIM( x.Item ) ), '' ) != ''
					
	   UNION
	  SELECT 	HeaderID    =   tmp.ID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   tmp.TestMode
			  , Description =   N'Test Mode loaded from test dataset'
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
        FROM 	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType
      
	   WHERE	tType.Name = N'TestMode'
					AND ISNULL( tmp.TestMode, '' ) != '' 
				;

	--  INSERT tags into temp storage from following header fields:
	--		Project ( if not coming from HWT )
	--		HW Increment ( if not coming from HWT )
	
	  INSERT 	#tags
					( HeaderID, TagTypeID, Name, Description, UpdatedBy, TagID ) 

	  SELECT	HeaderID    =   tmp.ID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   tmp.ProjectName
			  , Description =   N'Project loaded from test dataset'
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
		FROM 	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType
				
	   WHERE 	tType.Name = 'Project'
					AND ISNULL( tmp.ProjectName, '' ) != '' 
					AND tmp.IsLegacyXML = 1
						
	   UNION 
	  SELECT 	HeaderID    =   tmp.ID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   tmp.HardwareRev
			  , Description =   N'Hardware Increment loaded from test dataset'
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
		FROM 	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType
				
	   WHERE 	tType.Name = N'HWIncrement'
					AND ISNULL( tmp.HardwareRev, '' ) != '' 
					AND tmp.IsLegacyXML = 1 
				;
	
--  4)  MERGE header changes from temp storage into hwt.Header
		WITH	cte AS
				(
				  SELECT	HeaderID            =   tmp.ID
						  , ResultFileName      =   LEFT( tmp.ResultFile, 250 )
						  , StartTime           =   CONVERT( datetime, tmp.StartTime, 109 )
						  , FinishTime          =   NULLIF( CONVERT( datetime, tmp.FinishTime, 109 ), '1900-01-01' )
						  , Duration			=	tmp.TestDuration
						  , TestStationID       =   tmp.TestStationID
						  , TestName            =   tmp.TestName
						  , TestConfigFile      =   tmp.TestConfigFile
						  , TestCodePathName    =   tmp.TestCodePathName
						  , TestCodeRevision    =   tmp.TestCodeRev
						  , HWTSysCodeRevision  =   tmp.HWTSysCodeRev
						  , KdrivePath          =   tmp.KdrivePath
						  , Comments            =   tmp.Comments
						  , ExternalFileInfo    =   tmp.ExternalFileInfo
						  , OperatorName        =   tmp.OperatorName
						  , HWTChecksum         =   tmp.HWTChecksum
					FROM	#changes AS tmp
				)
	   MERGE 	INTO hwt.Header AS tgt
				USING cte AS src
					ON src.HeaderID = tgt.HeaderID
					
		WHEN 	MATCHED 
				THEN  UPDATE
							SET	tgt.ResultFileName      =   src.ResultFileName
							  , tgt.StartTime           =   src.StartTime
							  , tgt.FinishTime          =   src.FinishTime
							  , tgt.Duration			=	src.Duration
							  , tgt.TestStationName     =   src.TestStationID
							  , tgt.TestName            =   src.TestName
							  , tgt.TestConfigFile      =   src.TestConfigFile
							  , tgt.TestCodePath        =   src.TestCodePathName
							  , tgt.TestCodeRevision    =   src.TestCodeRevision
							  , tgt.HWTSysCodeRevision  =   src.HWTSysCodeRevision
							  , tgt.KdrivePath          =   src.KdrivePath
							  , tgt.Comments            =   src.Comments
							  , tgt.ExternalFileInfo    =   src.ExternalFileInfo
							  , tgt.HWTChecksum         =   src.HWTChecksum
							  , tgt.UpdatedBy           =   src.OperatorName
							  , tgt.UpdatedDate         =   GETDATE()

		WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT																
							(
								HeaderID, ResultFileName, StartTime
							  , FinishTime, Duration, TestStationName
							  , TestName, TestConfigFile, TestCodePath
							  , TestCodeRevision, HWTSysCodeRevision, KdrivePath
							  , Comments, ExternalFileInfo, HWTChecksum
							  , UpdatedBy, UpdatedDate
							)
					  VALUES(	
								src.HeaderID, src.ResultFileName, src.StartTime
							  , src.FinishTime, src.Duration, src.TestStationID
							  , src.TestName, src.TestConfigFile, src.TestCodePathName
							  , src.TestCodeRevision, src.HWTSysCodeRevision, src.KdrivePath
							  , src.Comments, src.ExternalFileInfo, src.HWTChecksum
							  , src.OperatorName, GETDATE()
							) 
							;


--  5)  INSERT tags from temp storage into hwt.Tag
		WITH	newTags AS
				(
				  SELECT 	DISTINCT 
							TagTypeID
						  , Name
						  , Description
						  , IsDeleted		=	0
						  , UpdatedBy
						  , UpdatedDate		=	GETDATE()
					FROM	#tags AS tmp
				   WHERE	NOT EXISTS
							(
							  SELECT	1
								FROM    hwt.Tag AS tag
								WHERE   tag.TagTypeID = tmp.TagTypeID 
											AND tag.Name = tmp.Name
							)
				)
      INSERT 	hwt.Tag
					( TagTypeID, Name, Description, IsDeleted, UpdatedBy, UpdatedDate )
      SELECT	* 
	    FROM 	newTags 
				;

    --  Apply new TagID back into temp storage
      UPDATE	tmp
		 SET 	TagID   =   tag.TagID
		FROM	#tags AS tmp
				INNER JOIN
					hwt.Tag AS tag
						ON tag.TagTypeID = tmp.TagTypeID
							AND tag.Name = tmp.Name 
				;


--  6)  MERGE new header tag data into hwt.HeaderTag
	DECLARE 	@HeaderID		int ; 
	DECLARE 	@TagID			nvarchar(max) ; 
	DECLARE		@OperatorName	sysname ; 
	
				
	WHILE EXISTS ( SELECT 1 FROM #tags ) 
		BEGIN 
		
			  SELECT 	DISTINCT 
						@HeaderID 		=	HeaderID 
					  , @OperatorName	=	UpdatedBy
				FROM 	#tags 
						; 
				
			  SELECT	@TagID 		=	STUFF
										(
											(	
											  SELECT 	N'|' + CONVERT( nvarchar(20), t.TagID )
												FROM 	#tags AS t 
											   WHERE 	t.HeaderID = @HeaderID 
														FOR XML PATH (''), TYPE
											).value('.', 'nvarchar(max)'), 1, 1, '' 
										) 
						; 
						
			 EXECUTE 	hwt.usp_AssignTagsToDatasets 
							@pUserID	= @OperatorName
						  , @pHeaderID	= @HeaderID 
						  , @pTagID		= @TagID 
						  , @pNotes		= 'Tag assigned during header load.'
						;

			  DELETE	#tags 
			   WHERE	HeaderID = @HeaderID 
						AND UpdatedBy = @OperatorName
						; 
		END 

	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH
