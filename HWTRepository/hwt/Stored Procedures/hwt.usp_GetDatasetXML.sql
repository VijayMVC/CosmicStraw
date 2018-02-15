CREATE PROCEDURE
    hwt.usp_GetDatasetXML(
        @pHeaderID  nvarchar(max)
    )
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_GetDatasetXML
    Abstract:   Returns dataset names and XML representations of input headerIDs
    Logic Summary
    -------------
    1)  SELECT dataset name and XML representation for each Header.HeaderID value in dataset.

    Parameters
    ----------
    @pHeaderID  nvarchar(max)   pipe-delimited list of Header.HeaderID values

    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

DECLARE @ErrorMessage   nvarchar(max)   =   NULL ;


--	1)	Parse input parameter into temp storage 
	DROP TABLE IF EXISTS #headers ; 
	
	SELECT	HeaderID	=	CONVERT( int, x.Item )
	INTO 	#headers
	FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x 
	ORDER BY 1
	; 

--  1)  SELECT dataset name and XML representation for each Header.HeaderID value in dataset.
SELECT
    DatasetName =   RIGHT( ResultFileName, CHARINDEX( '\', REVERSE( h.ResultFileName ) + '\' ) - 1 )
  , DatasetXML  =   (   SELECT
                            (   SELECT  
									Result_File         =   h2.ResultFileName
                                  , Start_Time          =   h2.StartTime
                                  , Finish_Time         =   h2.FinishTime
                                  , Test_Duration       =   h2.Duration
                                  , Project_Name        =   p.Name 
                                  , Firmware_Rev        =   fw.Name
                                  , Hardware_Rev        =   '' /* select tag */
                                  , Part_SN             =   '' /* select tag */
                                  , Operator_Name       =   '' /* select tag */
                                  , Test_Station_ID     =   h2.TestStationName
                                  , Test_Name           =   h2.TestName
                                  , Test_Config_File    =   h2.TestConfigFile
                                  , Test_Code_Path_Name =   h2.TestCodePath
                                  , Test_Code_Rev       =   h2.TestCodeRevision
                                  , HWT_Sys_Code_Rev    =   h2.HWTSysCodeRevision
                                  , Kdrive_Path         =   h2.KdrivePath
                                  , External_File_Info  =   h2.ExternalFileInfo
                                  , Comments            =   h2.Comments
                                  , (   SELECT
                                            (   SELECT  
													Description
                                                  , Asset
                                                  , CalibrationDueDate
                                                  , CostCenter
                                                FROM    
													hwt.Equipment AS e
                                                INNER JOIN
                                                    hwt.HeaderEquipment AS he 
														ON he.EquipmentID = e.EquipmentID
                                                WHERE   
													he.HeaderID = h2.HeaderID
                                                FOR XML 
													PATH( 'equipment_element' ), TYPE
                                                )
                                        FOR XML 
											PATH( 'equipment' ), TYPE
                                        )
                                  , (   SELECT
											(   SELECT  
													Name    =   o.Name
                                                  , Type    =   o.DataType
                                                  , Units   =   o.Units
                                                  , Value   =   ho.OptionValue
                                                FROM    
													hwt.[Option] AS o
                                                INNER JOIN
													hwt.HeaderOption AS ho 
														ON ho.OptionID= o.OptionID
                                                WHERE   
													ho.HeaderID = h2.HeaderID
                                                FOR XML 
													PATH( 'option_element' ), TYPE
                                                )
                                          , (   SELECT  
													Name    =   ac.Name
                                                  , Type    =   ac.DataType
                                                  , Units   =   ac.Units
                                                  , Value   =   ha.AppConstValue
                                                FROM    
													hwt.AppConst AS ac
                                                INNER JOIN
													hwt.HeaderAppConst AS ha 
														ON ha.AppConstID = ac.AppConstID
                                                WHERE   
													ha.HeaderID = h2.HeaderID
												FOR XML 
													PATH( 'AppConst_element' ), TYPE
                                                )
                                        FOR XML 
											PATH( 'options' ), TYPE
										)
                                FROM    
									hwt.Header AS h2
								OUTER APPLY( 
									SELECT	t.Name
									FROM	hwt.Tag AS t 
									INNER JOIN 
											hwt.HeaderTag AS ht ON ht.TagID = t.TagID 
									INNER JOIN 
											hwt.TagType AS tType ON tType.TagTypeID = t.TagTypeID
									WHERE 
										tType.Name = 'Project'
											AND ht.HeaderID = h2.HeaderID 
									) AS p
								OUTER APPLY( 
									SELECT	t.Name
									FROM	hwt.Tag AS t 
									INNER JOIN 
											hwt.HeaderTag AS ht ON ht.TagID = t.TagID 
									INNER JOIN 
											hwt.TagType AS tType ON tType.TagTypeID = t.TagTypeID
									WHERE 
										tType.Name = 'FWRevision'
											AND ht.HeaderID = h2.HeaderID 
									) AS fw									
                                WHERE   
									h2.HeaderID = h.HeaderID
                                FOR XML 
									PATH( 'header' ), TYPE
								)
                          , (   SELECT	
									num		=	v.VectorNumber 
								  , (	SELECT  
											Name    =   e.Name
										  , Type    =   e.DataType
										  , Units   =   e.Units
										  , Value   =   ve.ElementValue
										FROM    
											hwt.Element AS e
										INNER JOIN
											hwt.VectorElement AS ve 
												ON ve.ElementID = e.ElementID
										WHERE   
											ve.VectorID = v.VectorID
										FOR XML 
											PATH( 'vector_element' ), TYPE
										)
								  , ReqID	=	''	/* select tags */ 
								  , (	SELECT  
											Name    =   r.Name
										  , Type    =   r.DataType
										  , Units   =   r.Units
										  , ( 	SELECT 	
													Value = vr2.ResultValue
												FROM 	
													hwt.VectorResult AS vr2
												WHERE 	
													vr2.VectorID = vr.VectorID
														AND vr2.ResultID = vr.ResultID 
												ORDER BY 
													vr2.ResultN
												FOR XML 
													PATH( '' ), TYPE
												) 
										FROM    
											hwt.Result AS r
										INNER JOIN
											hwt.VectorResult AS vr 
												ON vr.ResultID = r.ResultID
										WHERE   
											vr.VectorID = v.VectorID
												AND vr.ResultN = 1 
										FOR XML 
											PATH( 'result_element' ), TYPE
											)									  
								  , ( 	SELECT 	
											StartTime 	=	v.StartTime 
										  , FinishTime	=	v.EndTime
										FROM 	
											hwt.Vector AS v2 
										WHERE	
											v2.VectorID = v.VectorID 
										FOR XML 
											PATH( 'Timestamp' ), TYPE
										)
								FROM    
									hwt.Vector AS v
								WHERE   
									v.HeaderID = h.HeaderID
								FOR XML 
									PATH( 'vector' ), TYPE
								)
						FOR XML 
							PATH( 'root' ), TYPE
						)
FROM
    hwt.Header AS h
INNER JOIN
	#headers AS tmp
		ON tmp.HeaderID = h.HeaderID

;
GO