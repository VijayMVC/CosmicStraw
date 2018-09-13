CREATE PROCEDURE	[xmlStage].[usp_ShredXMLData]
						(
							@pInputXML 	xml( CONTENT xmlStage.LabViewXSD )
						  , @pHeaderID	int OUTPUT
						)
/*
***********************************************************************************************************************************

    Procedure:  xmlStage.usp_ShredXMLData
    Abstract:   shreds XML data into xmlStage tables

    Logic Summary
    -------------


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
	  
	 DECLARE	@HeaderID	int	
	  
	  SELECT	@pHeaderID	=	header.xmlData.value( '@ID', 'int' )
	    FROM	@pInputXML.nodes( 'root/header' ) AS header( xmlData ) 
				; 
				
	IF(	@pHeaderID IS NULL ) 
		SELECT @pHeaderID = ISNULL( MAX( ID ), 0 ) + 1 FROM labViewStage.header ;
		
	  SELECT @HeaderID = @pHeaderID ;
	   
	SET IDENTITY_INSERT xmlStage.header ON ; 
	--	Shred Header Data 
	  INSERT 	xmlStage.header
					(	
						ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev
							, HardwareRev, PartSN, OperatorName, TestMode, TestStationID, TestName
							, TestConfigFile, TestCodePathName, TestCodeRev, HWTSysCodeRev, KdrivePath
							, Comments, ExternalFileInfo, IsLegacyXML, VectorCount
					)
	
	  SELECT	ID					=	@HeaderID
			  , ResultFile			=	header.xmlData.value( 'Result_File[1]', 'nvarchar(1000)' )
			  , StartTime			=	header.xmlData.value( 'Start_Time[1]', 'nvarchar(100)' )
			  , FinishTime			=	header.xmlData.value( 'Finish_Time[1]', 'nvarchar(100)' )
			  , TestDuration		=	header.xmlData.value( 'Test_Duration[1]', 'nvarchar(100)' )
			  , ProjectName			=	header.xmlData.value( 'Project_Name[1]', 'nvarchar(100)' )
			  , FirmwareRev			=	header.xmlData.value( 'Firmware_Rev[1]', 'nvarchar(100)' )
			  , HardwareRev			=	header.xmlData.value( 'Hardware_Rev[1]', 'nvarchar(100)' )
			  , PartSN				=	header.xmlData.value( 'Part_SN[1]', 'nvarchar(100)' )
			  , OperatorName		=	header.xmlData.value( 'Operator_Name[1]', 'nvarchar(100)' )
			  , TestMode			=	CASE
											WHEN CHARINDEX( 'Verification', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0  THEN 'Verification'
											WHEN CHARINDEX( 'Characterization', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0  THEN 'Characterization'
											WHEN CHARINDEX( 'Evaluation', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0  THEN 'Evaluation'
											WHEN CHARINDEX( 'Simulation', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0  THEN 'Simulation'
											WHEN CHARINDEX( 'Development', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0  THEN 'Development'
										END 
			  , TestStationID		=	header.xmlData.value( 'Test_Station_ID[1]', 'nvarchar(100)' )
			  , TestName			=	header.xmlData.value( 'Test_Name[1]', 'nvarchar(250)' )
			  , TestConfigFile		=	header.xmlData.value( 'Test_Config_File[1]', 'nvarchar(400)' )
			  , TestCodePathName	=	header.xmlData.value( 'Test_Code_Path_Name[1]', 'nvarchar(400)' )
			  , TestCodeRev			=	header.xmlData.value( 'Test_Code_Rev[1]', 'nvarchar(100)' )
			  , HWTSysCodeRev		=	header.xmlData.value( 'HWTSys_Code_Rev[1]', 'nvarchar(100)' )
			  , KdrivePath			=	header.xmlData.value( 'Kdrive_Path[1]', 'nvarchar(400)' )
			  , Comments			=	header.xmlData.value( 'Comments[1]', 'nvarchar(max)' )
			  , ExternalFileInfo	=	header.xmlData.value( 'External_File_Info[1]', 'nvarchar(max)' )
			  , IsLegacyXML			=	1 
			  , VectorCount			=	( SELECT @pInputXML.value('count(root/vector)', 'int') )

		FROM	@pInputXML.nodes( 'root/header' ) AS header( xmlData ) ; 

	SET IDENTITY_INSERT xmlStage.header OFF ; 

	
	--	Shred AppConst data 
		WITH	cte_AppConst_element AS 
					(
					  SELECT	HeaderID	=	@HeaderID
							  , Name		=	appConst.xmlData.value( 'name[1]', 'nvarchar(250)' )
							  , Type		=	appConst.xmlData.value( 'type[1]', 'nvarchar(50)' )
							  , Units		=	appConst.xmlData.value( 'units[1]', 'nvarchar(250)' )
							  , Value		=	CASE	LEFT( appConst.xmlData.value( 'type[1]', 'nvarchar(50)' ), 3 ) 
														WHEN 'ARR' 
															THEN '[' +	( SELECT	ISNULL( 
																							STUFF
																								( 
																									REPLACE( REPLACE( CONVERT( nvarchar(max), appConst.xmlData.query('./value') ), '<value>', ',"' ), '</value>', '"'  )
																									, 1, 1, '' 
																								)
																						   , '')
																		) + ']'
															ELSE REPLACE( REPLACE( CONVERT( nvarchar(max), appConst.xmlData.query('./value') ), '<value>', '' ), '</value>', ''  ) 
												END 
					
							  , NodeOrder	=	DENSE_RANK() OVER( ORDER BY appConst.xmlData ) 
					FROM	@pInputXML.nodes( 'root/header/options/AppConst_element' ) AS appConst( xmlData ) 
					)
	  INSERT 	xmlStage.appConst_element
					( HeaderID, Name, Type, Units, Value, NodeOrder )
	  SELECT 	HeaderID	=	HeaderID
			  , Name		=	Name
			  , Type		=	Type
			  , Units		=	Units
			  , Value		=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( [Value], CHAR(10), CHAR(13) + CHAR(10) ), '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , NodeOrder	=	NodeOrder

		FROM	cte_AppConst_element 
				; 

		
	   
	--	Shred equipment data 
	  INSERT 	xmlStage.equipment_element
					( HeaderID, Description, Asset, CalibrationDueDate, CostCenter, NodeOrder )
	  SELECT 	HeaderID			=	@HeaderID
			  , Description			=	equipment.xmlData.value( 'Description[1]', 'nvarchar(100)' )
			  , Asset				=	equipment.xmlData.value( 'Asset[1]', 'nvarchar(50)' )
			  , CalibrationDueDate	=	equipment.xmlData.value( 'Calibration_Due_Date[1]', 'nvarchar(50)' )
			  , CostCenter			=	equipment.xmlData.value( 'Cost_Center[1]', 'nvarchar(50)' )
			  , NodeOrder			=	DENSE_RANK() OVER ( ORDER BY equipment.xmlData )
			  
		FROM	@pInputXML.nodes( 'root/header/equipment/equipment_element' ) AS equipment( xmlData ) ;



	--	Shred LibraryFile data 
	  INSERT 	xmlStage.libraryInfo_file
					( HeaderID, FileName, FileRev, Status, HashCode, NodeOrder )
	  SELECT 	HeaderID	=	@HeaderID
			  , FileName	=	libraryInfo.xmlData.value( '@name[1]', 'nvarchar(400)' )
			  , FileRev		=	libraryInfo.xmlData.value( '@rev[1]', 'nvarchar(50)' )
			  , Status		=	libraryInfo.xmlData.value( '@status[1]', 'nvarchar(50)' )
			  , HashCode	=	libraryInfo.xmlData.value( '@HashCode[1]', 'nvarchar(100)' )
			  , NodeOrder	=	DENSE_RANK() OVER ( ORDER BY libraryInfo.xmlData )
			  
		FROM	@pInputXML.nodes( 'root/header/LibraryInfo/file' ) AS libraryInfo( xmlData ) ;

	--	Shred options data 
	  INSERT 	xmlStage.option_element
					( HeaderID, Name, Type, Units, Value, NodeOrder )
	  SELECT 	HeaderID	=	@HeaderID
			  , Name		=	options.xmlData.value( 'name[1]', 'nvarchar(100)' )
			  , Type		=	options.xmlData.value( 'type[1]', 'nvarchar(50)' )
			  , Units		=	options.xmlData.value( 'units[1]', 'nvarchar(50)' )
			  , Value		=	options.xmlData.value( 'value[1]', 'nvarchar(1000)' )
			  , NodeOrder	=	DENSE_RANK() OVER ( ORDER BY options.xmlData )
			  
		FROM	@pInputXML.nodes( 'root/header/options/option_element' ) AS options( xmlData ) ;


	   
	--	Shred vector data 
	--		For detailed description of ReqID construction, see notes at top of proc
	
	--	Build temp table to hold vector output data 
	  INSERT 	xmlStage.vector
					( HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime )
	  SELECT 	HeaderID	=	@HeaderID
			  , VectorNum	=	vector.xmlData.value( 'num[1]', 'int' )
			  , Loop		=	ISNULL( vector.xmlData.value( 'Loop[1]', 'int' ), 0 )
			  , ReqID		=	STUFF
								( 
									REPLACE( REPLACE( CONVERT( nvarchar(max), vector.xmlData.query('ReqID') ) , '<ReqID>', ','  ) , '</ReqID>' , ''  )
									, 1, 1, '' 
								)
			  , StartTime	=	vector.xmlData.value( 'Timestamp/StartTime[1]', 'nvarchar(50)' )
			  , EndTime		=	vector.xmlData.value( 'Timestamp/EndTime[1]', 'nvarchar(50)' )
			  
		FROM	@pInputXML.nodes( 'root/vector' ) AS vector( xmlData ) ;


	--	Shred vector_element data 
		WITH	cte_vector_element AS
					(	
					  SELECT	HeaderID	=	@HeaderID
							  , VectorNum	=	vector.xmlData.value( 'num[1]', 'int' )
							  , Loop		=	ISNULL( vector.xmlData.value( 'Loop[1]', 'int' ), 0 )
							  , StartTime	=	vector.xmlData.value( 'Timestamp/StartTime[1]', 'nvarchar(50)' )
							  , Name		=	vector_element.xmlData.value( 'name[1]', 'nvarchar(100)' )
							  , Type		=	vector_element.xmlData.value( 'type[1]', 'nvarchar(100)' )
							  , Units		=	vector_element.xmlData.value( 'units[1]', 'nvarchar(100)' )
							  , Value		=	vector_element.xmlData.value( 'value[1]', 'nvarchar(100)' )
							  , NodeOrder	=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY vector_element.xmlData ) 
						FROM	@pInputXML.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes( 'vector_element' ) AS vector_element( xmlData )
					)

	  INSERT 	xmlStage.vector_element
					( VectorID, Name, Type, Units, Value, NodeOrder )
	  SELECT 	VectorID	=	v.ID
			  , Name		=	cte.Name
			  , Type		=	cte.Type
			  , Units		=	cte.Units
			  , Value		=	cte.Value
			  , NodeOrder	=	cte.NodeOrder
		FROM	cte_vector_element AS cte 
				INNER JOIN xmlStage.vector AS v 
						ON v.HeaderID = cte.HeaderID 
							AND v.VectorNum = cte.VectorNum 
							AND v.Loop = cte.Loop 
							AND v.StartTime = cte.StartTime ; 


	--	Shred result_element data 
	--		For detailed description of Value construction, see notes at top of proc
		WITH	cte_result_element AS 
					(
					  SELECT	HeaderID	=	@HeaderID
							  , VectorNum	=	vector.xmlData.value( 'num[1]', 'int' )
							  , Loop		=	ISNULL( vector.xmlData.value( 'Loop[1]', 'int' ), 0 )
							  , StartTime	=	vector.xmlData.value( 'Timestamp/StartTime[1]', 'nvarchar(50)' )									  
							  , Name		=	result_element.xmlData.value( 'name[1]', 'nvarchar(250)' )
							  , Type		=	result_element.xmlData.value( 'type[1]', 'nvarchar(100)' )
							  , Units		=	result_element.xmlData.value( 'units[1]', 'nvarchar(100)' )
							  , Value		=	CASE	LEFT( result_element.xmlData.value( 'type[1]', 'nvarchar(100)' ), 3 ) 
														WHEN 'ARR' 
															THEN '[' +	( SELECT	ISNULL( 
																							STUFF
																								( 
																									REPLACE( REPLACE( CONVERT( nvarchar(max), result_element.xmlData.query('./value') ), '<value>', ',"' ), '</value>', '"'  )
																									, 1, 1, '' 
																								)
																						   , '')
																		) + ']'
															ELSE REPLACE( REPLACE( CONVERT( nvarchar(max), result_element.xmlData.query('./value') ), '<value>', '' ), '</value>', ''  ) 
												END 
					
							  , NodeOrder	=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY result_element.xmlData ) 
						FROM	@pInputXML.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes( 'result_element' ) AS result_element( xmlData )
					)
	
	  INSERT 	INTO xmlStage.result_element
					( VectorID, Name, Type, Units, Value, NodeOrder )
	  SELECT	VectorID	=	v.ID
			  , Name		=	cte.Name
			  , Type		=	cte.Type
			  , Units		=	cte.Units
			  , Value		=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( cte.Value, CHAR(10), CHAR(13) + CHAR(10) ), '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , NodeOrder	=	cte.NodeOrder
		FROM	cte_result_element AS cte
				LEFT JOIN xmlStage.vector AS v 
						ON v.HeaderID = cte.HeaderID 
							AND v.VectorNum = cte.VectorNum 
							AND v.Loop = cte.Loop 
							AND v.StartTime = cte.StartTime 
				; 


	--	Shred error_element data 
		WITH	cte_error_element AS 
					(
					  SELECT	HeaderID	=	@HeaderID
							  , VectorNum	=	vector.xmlData.value( 'num[1]', 'int' )
							  , Loop		=	ISNULL( vector.xmlData.value( 'Loop[1]', 'int' ), 0 )
							  , StartTime	=	vector.xmlData.value( 'Timestamp/StartTime[1]', 'nvarchar(50)' )	
							  , ErrorType	=	1									  
							  , ErrorCode	=	error_element.xmlData.value( ' ( test_error/@code ) [1]', 'int' )
							  , ErrorText	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( error_element.xmlData.value( 'test_error[1]', 'nvarchar(max)' ), CHAR(10), CHAR(13) + CHAR(10) ), '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
							  , NodeOrder	=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY error_element.xmlData ) 
						FROM	@pInputXML.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes('error_element') AS error_element( xmlData )

				   UNION ALL
					  SELECT	HeaderID	=	@HeaderID
							  , VectorNum	=	vector.xmlData.value( 'num[1]', 'int' )
							  , Loop		=	ISNULL( vector.xmlData.value( 'Loop[1]', 'int' ), 0 )
							  , StartTime	=	vector.xmlData.value( 'Timestamp/StartTime[1]', 'nvarchar(50)' )	
							  , ErrorType	=	2
							  , ErrorCode	=	error_element.xmlData.value( ' ( data_error/@num) [1]', 'int' )
							  , ErrorText	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( error_element.xmlData.value( 'data_error[1]', 'nvarchar(max)' ), CHAR(10), CHAR(13) + CHAR(10) ), '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
							  , NodeOrder	=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY error_element.xmlData ) 
						FROM	@pInputXML.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes('error_element') AS error_element( xmlData )
				   UNION ALL
					  SELECT	HeaderID	=	@HeaderID
							  , VectorNum	=	vector.xmlData.value( 'num[1]', 'int' )
							  , Loop		=	ISNULL( vector.xmlData.value( 'Loop[1]', 'int' ), 0 )
							  , StartTime	=	vector.xmlData.value( 'Timestamp/StartTime[1]', 'nvarchar(50)' )	
							  , ErrorType	=	3
							  , ErrorCode	=	error_element.xmlData.value( ' ( input_param_error/@num) [1]', 'int' )
							  , ErrorText	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( error_element.xmlData.value( 'input_param_error[1]', 'nvarchar(max)' ), CHAR(10), CHAR(13) + CHAR(10) ), '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
							  , NodeOrder	=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY error_element.xmlData ) 
						FROM	@pInputXML.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes('error_element') AS error_element( xmlData )

					)
	
	  INSERT 	INTO xmlStage.error_element
					( VectorID, ErrorType, ErrorCode, ErrorText, NodeOrder )
	  SELECT	VectorID	=	v.ID
			  , ErrorType	=	cte.ErrorType
			  , ErrorCode	=	cte.ErrorCode
			  , ErrorText	=	cte.ErrorText
			  , NodeOrder	=	cte.NodeOrder
		FROM	cte_error_element AS cte 
				INNER JOIN xmlStage.vector AS v 
						ON v.HeaderID = cte.HeaderID 
							AND v.VectorNum = cte.VectorNum 
							AND v.Loop = cte.Loop 
							AND v.StartTime = cte.StartTime 
	   WHERE	cte.ErrorCode IS NOT NULL ; 


	RETURN 0 ; 

END TRY

BEGIN CATCH

	IF @@trancount > 0 ROLLBACK TRANSACTION ; 
	
	EXECUTE 	eLog.log_CatchProcessing  @pProcID = @@PROCID  ; 
	
	RETURN 55555 ; 

END CATCH