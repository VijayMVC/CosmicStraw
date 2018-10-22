CREATE PROCEDURE	xmlStage.usp_ShredLegacyXML
	(
		@pFileID	uniqueidentifier
	  , @pHeaderID	int 	OUTPUT 
	)
/*
***********************************************************************************************************************************

    Procedure:  xmlStage.usp_ShredLegacyXML
    Abstract:   shreds legacy XML data into labViewStage tables

    Logic Summary
    -------------
	1)	Load desired file from FileTable into XML variable
	2)	Shred header data from XML variable into labViewStage schema
	3)	Shred AppConst_element data from XML variable into labViewStage schema
	4)	Shred equipment data from XML variable into labViewStage schema
	5)	Shred LibraryInfo data from XML variable into labViewStage schema
	6)	Shred option_element data from XML variable into labViewStage schema
	7)	Shred vector data from XML variable into labViewStage schema
	8)	Shred vector_element from XML variable into labViewStage schema
	9)	Shred result_element data from XML variable into labViewStage schema
	10)	Shred error_element data from XML variable into labViewStage schema
	11)	Load shredded data from labViewStage schema into hwt schema

    Parameters
    ----------
	@pFileID	uniqueidentifier	GUID designating incoming XML file to be shreded
	@pHeaderID	int 				OUTPUT variable containing ID from INSERTed labViewStage.header data
	
	
    Notes
    -----

    Revision
    --------
    carsoc3     2018-02-01      alpha release
	carsoc3		2018-10-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY


--	1)	Load desired file from FileTable into XML variable
	 DECLARE	@xmlData 	xml
;
	  SELECT	@xmlData	=	CONVERT( xml, file_stream ) 
	    FROM	xmlStage.LegacyXML_Files AS f 
	   WHERE	f.stream_id = @pFileID 
; 

--	2)	Shred header data from XML variable into labViewStage schema
	--	Load IDENTITY from XML variable into temp storage 
	  INSERT	labViewStage.header
					(
						ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev
							, HardwareRev, PartSN, OperatorName, TestMode, TestStationID, TestName
							, TestConfigFile, TestCodePathName, TestCodeRev, HWTSysCodeRev, KdrivePath
							, Comments, ExternalFileInfo, IsLegacyXML, VectorCount
					)
	
	  SELECT	ResultFile			=	header.xmlData.value( 'Result_File[1]', 'nvarchar(1000)' )
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
											WHEN CHARINDEX( 'Evaluation', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0	THEN 'Evaluation'
											WHEN CHARINDEX( 'Simulation', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0	THEN 'Simulation'
											WHEN CHARINDEX( 'Development', header.xmlData.value( 'Comments[1]', 'nvarchar(max)' ) ) > 0	 THEN 'Development'
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
			  , VectorCount			=	( SELECT @xmlData.value('count(root/vector)', 'int') )

		FROM	@xmlData.nodes( 'root/header' ) AS header( xmlData ) 
; 
	  SELECT  	@pHeaderID = SCOPE_IDENTITY()
;
	
--	3)	Shred AppConst_element data from XML variable into labViewStage schema
	--	construction for the Value field
	--		use the query() method to extract the individual <value> nodes into a comma-separated string
	--		if the type is Array, create a JSON string from the use the comma-separated string
	--		if the type is not array, use the comma-separated string
		WITH	cte_AppConst_element AS
					(
					  SELECT	HeaderID	=	@pHeaderID
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
															ELSE REPLACE( REPLACE( CONVERT( nvarchar(max), appConst.xmlData.query('./value') ), '<value>', '' ), '</value>', ''	 )
												END
							  , NodeOrder	=	DENSE_RANK() OVER( ORDER BY appConst.xmlData )
						FROM	@xmlData.nodes( 'root/header/options/AppConst_element' ) AS appConst( xmlData )
					)
	  INSERT	labViewStage.appConst_element
					( HeaderID, Name, Type, Units, Value, NodeOrder )
	  SELECT	HeaderID	=	HeaderID
			  , Name		=	Name
			  , Type		=	Type
			  , Units		=	Units
			  , Value		=	Value
			  , NodeOrder	=	NodeOrder
		FROM	cte_AppConst_element
;

--	4)	Shred equipment data from XML variable into labViewStage schema
	  INSERT	labViewStage.equipment_element
					( HeaderID, Description, Asset, CalibrationDueDate, CostCenter, NodeOrder )
	  SELECT	HeaderID			=	@pHeaderID
			  , Description			=	equipment.xmlData.value( 'Description[1]', 'nvarchar(100)' )
			  , Asset				=	equipment.xmlData.value( 'Asset[1]', 'nvarchar(50)' )
			  , CalibrationDueDate	=	equipment.xmlData.value( 'Calibration_Due_Date[1]', 'nvarchar(50)' )
			  , CostCenter			=	equipment.xmlData.value( 'Cost_Center[1]', 'nvarchar(50)' )
			  , NodeOrder			=	DENSE_RANK() OVER ( ORDER BY equipment.xmlData )
		FROM	@xmlData.nodes( 'root/header/equipment/equipment_element' ) AS equipment( xmlData )
;

--	5)	Shred LibraryInfo data from XML variable into labViewStage schema
	  INSERT 	labViewStage.libraryInfo_file
					( HeaderID, FileName, FileRev, Status, HashCode, NodeOrder )
	  SELECT	HeaderID	=	@pHeaderID
			  , FileName	=	libraryInfo.xmlData.value( '@name[1]', 'nvarchar(400)' )
			  , FileRev		=	libraryInfo.xmlData.value( '@rev[1]', 'nvarchar(50)' )
			  , Status		=	libraryInfo.xmlData.value( '@status[1]', 'nvarchar(50)' )
			  , HashCode	=	libraryInfo.xmlData.value( '@HashCode[1]', 'nvarchar(100)' )
			  , NodeOrder	=	DENSE_RANK() OVER ( ORDER BY libraryInfo.xmlData )
		FROM	@xmlData.nodes( 'root/header/LibraryInfo/file' ) AS libraryInfo( xmlData ) 
;

--	6)	Shred option_element data from XML variable into labViewStage schema
	  INSERT	labViewStage.option_element
					( HeaderID, Name, Type, Units, Value, NodeOrder )
	  SELECT 	HeaderID	=	@pHeaderID
			  , Name		=	options.xmlData.value( 'name[1]', 'nvarchar(100)' )
			  , Type		=	options.xmlData.value( 'type[1]', 'nvarchar(50)' )
			  , Units		=	options.xmlData.value( 'units[1]', 'nvarchar(50)' )
			  , Value		=	options.xmlData.value( 'value[1]', 'nvarchar(1000)' )
			  , NodeOrder	=	DENSE_RANK() OVER ( ORDER BY options.xmlData )
		FROM	@xmlData.nodes( 'root/header/options/option_element' ) AS options( xmlData )
;

--	7)	Shred vector data from XML variable into labViewStage schema
	--	Create temp storage to hold INSERTed VectorID values 
	--	VectorOrdinal column corresponds to the physical order of <vector> nodes in the legacy XML file
	 DECLARE 	@VectorOrdinal AS TABLE 
					( 
						VectorID		INT 
					  , VectorOrdinal	INT		IDENTITY( 1 , 1 ) 
					) 
;
	--	StartTime and EndTime for legacy data is carried in legacy XML as hh:mm:ss 
	--	This value needs to be extended to hh:mm:ss.nnn for HWT Repository
	--	Vectors are ordered and ranked within a given second for the milliseconds value
		WITH 	cte_vector AS 
					(
					  SELECT 	HeaderID				=	@pHeaderID 
							  , VectorNum				=	vector.xmlData.value( 'num[1]', 'int' )
							  , Loop					=	ISNULL( vector.xmlData.value( 'Loop[1]', 'int' ), 0 )
							  , ReqID					=	STUFF
															( 
																REPLACE( REPLACE( CONVERT( nvarchar(max), vector.xmlData.query('ReqID') ) , '<ReqID>', ','  ) , '</ReqID>' , ''  )
																, 1, 1, '' 
															)
							  , StartTime				=	vector_ts.xmlData.value( 'StartTime[1]', 'nvarchar(50)' ) 
							  , EndTime					=	vector_ts.xmlData.value( 'EndTime[1]', 'nvarchar(50)' ) 
							  , StartHasMilliseconds	=	CHARINDEX( N'.', vector_ts.xmlData.value( 'StartTime[1]', 'nvarchar(50)' ) )
							  , FinishHasMilliseconds	=	CHARINDEX( N'.', vector_ts.xmlData.value( 'EndTime[1]', 'nvarchar(50)' ) )
							  , StartTime_ms			=	RIGHT( '000' + CONVERT( nvarchar(20), DENSE_RANK() 	OVER 
																													( 
																														PARTITION BY	DATEPART( ss, CONVERT( datetime2(3), vector_ts.xmlData.value( 'StartTime[1]', 'nvarchar(50)' ) ) ) 
																														ORDER BY 		vector.xmlData ) ), 3 
																													)
							  , EndTime_ms				=	RIGHT( '000' + CONVERT( nvarchar(20), DENSE_RANK() OVER 
																												    ( 
																														PARTITION BY 	DATEPART( ss, CONVERT( datetime2(3), vector_ts.xmlData.value( 'EndTime[1]', 'nvarchar(50)' ) ) ) 
																															ORDER BY 	vector.xmlData ) ), 3 
																													)
						FROM 	@xmlData.nodes( 'root/vector' ) AS vector( xmlData ) 
									CROSS APPLY vector.xmlData.nodes('Timestamp') AS vector_ts( xmlData ) 
					) 
	  INSERT 	labViewStage.Vector 
					( HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime )
	  OUTPUT	inserted.ID
		INTO	@VectorOrdinal( VectorID ) 
	  SELECT 	HeaderID		=	cte.HeaderID
			  , VectorNum		=	cte.VectorNum
			  , Loop			=	cte.Loop
			  , ReqID			=	cte.ReqID 
  			  , StartTime		=	CASE 
										WHEN cte.StartHasMilliseconds != 0 THEN cte.StartTime  
										ELSE cte.StartTime + N'.' + cte.StartTime_ms
									END
  			  , EndTime			=	CASE 
  			  							WHEN cte.FinishHasMilliseconds != 0 THEN cte.EndTime
  			  							ELSE cte.EndTime + N'.' + cte.EndTime_ms
  			  						END

		FROM 	cte_vector AS cte
	ORDER BY 	1, 2, 5
; 

--	8)	Shred vector_element from XML variable into labViewStage schema
		WITH	cte_vector_element AS
					(	
					  SELECT	Name			=	vector_element.xmlData.value( 'name[1]', 'nvarchar(100)' )
							  , Type			=	vector_element.xmlData.value( 'type[1]', 'nvarchar(100)' )
							  , Units			=	vector_element.xmlData.value( 'units[1]', 'nvarchar(100)' )
							  , Value			=	vector_element.xmlData.value( 'value[1]', 'nvarchar(100)' )
							  , NodeOrder		=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY vector_element.xmlData )
							  , VectorOrdinal	=	DENSE_RANK() OVER( ORDER BY vector.xmlData )
						FROM	@xmlData.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes( 'vector_element' ) AS vector_element( xmlData )
					)
	  INSERT 	labViewStage.vector_element
					( VectorID, Name, Type, Units, Value, NodeOrder )
	  SELECT 	VectorID	=	v.VectorID
			  , Name		=	cte.Name
			  , Type		=	cte.Type
			  , Units		=	cte.Units
			  , Value		=	cte.Value
			  , NodeOrder	=	cte.NodeOrder
		FROM	cte_vector_element AS cte 
				INNER JOIN @VectorOrdinal AS v 
						ON v.VectorOrdinal = cte.VectorOrdinal 
;

--	9)	Shred result_element data from XML variable into labViewStage schema
		WITH	cte_result_element AS 
					(
					  SELECT	Name			=	result_element.xmlData.value( 'name[1]', 'nvarchar(250)' )
							  , Type			=	result_element.xmlData.value( 'type[1]', 'nvarchar(100)' )
							  , Units			=	result_element.xmlData.value( 'units[1]', 'nvarchar(100)' )
							  , Value			=	CASE	LEFT( result_element.xmlData.value( 'type[1]', 'nvarchar(100)' ), 3 )
															WHEN 'ARR'
																THEN '[' +	( SELECT	ISNULL(
																								STUFF
																									(
																										REPLACE( REPLACE( CONVERT( nvarchar(max), result_element.xmlData.query('./value') ), '<value>', ',"' ), '</value>', '"'	 )
																										, 1, 1, ''
																									)
																							, '')
																			) + ']'
																ELSE REPLACE( REPLACE( CONVERT( nvarchar(max), result_element.xmlData.query('./value') ), '<value>', '' ), '</value>', ''  )
													END
							  , NodeOrder		=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY result_element.xmlData )
							  , VectorOrdinal	=	DENSE_RANK() OVER( ORDER BY vector.xmlData )
						FROM	@xmlData.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes( 'result_element' ) AS result_element( xmlData )
					)
	  INSERT 	INTO labViewStage.result_element
					( VectorID, Name, Type, Units, Value, NodeOrder )
	  SELECT	VectorID	=	v.VectorID
			  , Name		=	cte.Name
			  , Type		=	cte.Type
			  , Units		=	cte.Units
			  , Value		=	cte.Value
			  , NodeOrder	=	cte.NodeOrder
		FROM	cte_result_element AS cte
				LEFT JOIN 	@VectorOrdinal AS v 
						ON 	v.VectorOrdinal = cte.VectorOrdinal 
;

--	10)	Shred error_element data from XML variable into labViewStage schema
		WITH	cte_error_element AS
					(
					  SELECT	ErrorType		=	1
							  , ErrorCode		=	error_element.xmlData.value( '( test_error/@code)[1]', 'int' )
							  , ErrorText		=	error_element.xmlData.value( 'test_error[1]', 'nvarchar(max)' )
							  , NodeOrder		=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY error_element.xmlData )
							  , VectorOrdinal	=	DENSE_RANK() OVER( ORDER BY vector.xmlData )							  
						FROM	@xmlData.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes('error_element') AS error_element( xmlData )

				   UNION ALL
					  SELECT	ErrorType		=	2
							  , ErrorCode		=	error_element.xmlData.value( '(data_error/@num)[1]', 'int' )
							  , ErrorText		=	error_element.xmlData.value( 'data_error[1]', 'nvarchar(max)' )
							  , NodeOrder		=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY error_element.xmlData )
							  , VectorOrdinal	=	DENSE_RANK() OVER( ORDER BY vector.xmlData )							  
						FROM	@xmlData.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes('error_element') AS error_element( xmlData )

				   UNION ALL
					  SELECT	ErrorType		=	3
							  , ErrorCode		=	error_element.xmlData.value( '(input_param_error/@num)[1]', 'int' )
							  , ErrorText		=	error_element.xmlData.value( 'input_param_error[1]', 'nvarchar(max)' )
							  , NodeOrder		=	DENSE_RANK() OVER( PARTITION BY vector.xmlData ORDER BY error_element.xmlData )
							  , VectorOrdinal	=	DENSE_RANK() OVER( ORDER BY vector.xmlData )							  
						FROM	@xmlData.nodes( 'root/vector' ) AS vector( xmlData )
								CROSS APPLY vector.xmlData.nodes('error_element') AS error_element( xmlData )
					)
	  INSERT 	INTO labViewStage.error_element
					( VectorID, ErrorType, ErrorCode, ErrorText, NodeOrder )
	  SELECT	VectorID	=	v.VectorID
			  , ErrorType	=	cte.ErrorType
			  , ErrorCode	=	cte.ErrorCode
			  , ErrorText	=	cte.ErrorText
			  , NodeOrder	=	cte.NodeOrder
		FROM	cte_error_element AS cte 
				INNER JOIN @VectorOrdinal AS v 
						ON v.VectorOrdinal = cte.VectorOrdinal 
	   WHERE	cte.ErrorCode IS NOT NULL
; 

--	11)	Load shredded data from labViewStage schema into hwt schema
	 EXECUTE 	hwt.usp_LoadRepositoryFromStage
;
	RETURN 0 
; 

END TRY
BEGIN CATCH

	IF @@trancount > 0 ROLLBACK TRANSACTION 
; 
	EXECUTE 	eLog.log_CatchProcessing  @pProcID = @@PROCID  
; 
	RETURN 55555 
; 
END CATCH