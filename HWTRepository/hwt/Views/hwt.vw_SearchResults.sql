CREATE VIEW		hwt.vw_SearchResults
	   WITH 	SCHEMABINDING		
/*
***********************************************************************************************************************************

		View:	hwt.vw_SearchResults
    Abstract:   Returns desired data for user interface

    Logic Summary
    -------------


    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-04-27		production release
	
***********************************************************************************************************************************
*/
AS

  SELECT 	DatasetID      			=   h.HeaderID
		  , InProgress				=	ISNULL( inP.InProgress, 0 )
		  , Project         		=   p.ProjectName
		  , TestName        		=   h.TestName
		  , TestMode        		=   m.TestMode
		  , Operator        		=   o.OperatorName
		  , StartTime       		=   CONVERT( varchar(10), h.StartTime, 120 )
		  , EndTime         		=   CONVERT( varchar(10), h.FinishTime, 120 )
		  , TestDuration    		=   h.Duration
		  , TestStationID   		=   h.TestStationName
		  , FWRevision      		=   f.FWRevisionName
		  , HWIncrement     		=   hw.HWIncrementName
		  , Tags					=	u.Tags
		  , TestProcedureNum		=	tp.Procedures
		  , Requirements			=	r.Requirements
		  , DeviceModel				=	dm.DeviceModels
		  , DataStatus				=	ds.DataStatus
		  , DUTType					=	dt.DUTTypes
		  , FunctionBlock			=	fb.FunctionBlock
		  , DeviceSN				=	sn.DeviceSN
		  , Error					=	ISNULL( e.IsError, 0 ) 
		  , Ignored					=	ISNULL( i.IsIgnored, 0 ) 
		  , Comments				=	h.Comments 
		  , ErrorText				=	te.ErrorText
		  , Assets					=	eq.Equipment
	FROM	hwt.Header AS h

	OUTER APPLY
	(
	  SELECT	ProjectName	=	t.TagName
		FROM    hwt.vw_AllTags AS t
				INNER JOIN hwt.HeaderTag AS ht 
						ON ht.TagID = t.TagID
	   WHERE   	ht.HeaderID = h.HeaderID 
					AND t.TagTypeName = N'Project' 
	) AS p

	OUTER APPLY
	(
	  SELECT  	TestMode = t.TagName
		FROM    hwt.vw_AllTags AS t
				INNER JOIN hwt.HeaderTag AS ht 
					ON ht.TagID = t.TagID
	   WHERE   	ht.HeaderID = h.HeaderID 
					AND t.TagTypeName = N'TestMode' 
	) AS m

	OUTER APPLY
	(
	  SELECT	OperatorName = t.TagName
		FROM    hwt.vw_AllTags AS t
				INNER JOIN hwt.HeaderTag AS ht 
						ON ht.TagID = t.TagID
       WHERE   	ht.HeaderID = h.HeaderID 
					AND t.TagTypeName = N'Operator' 
	) AS o

	OUTER APPLY
	(
      SELECT  	FWRevisionName = t.TagName
	    FROM	hwt.vw_AllTags AS t
				INNER JOIN hwt.HeaderTag AS ht 
					ON ht.TagID = t.TagID
	   WHERE   	ht.HeaderID = h.HeaderID AND t.TagTypeName = N'FWRevision' 
	) AS f

	OUTER APPLY
	(
      SELECT	HWIncrementName	= t.TagName
		FROM    hwt.vw_AllTags AS t
				INNER JOIN hwt.HeaderTag AS ht 
						ON ht.TagID = t.TagID
       WHERE	ht.HeaderID = h.HeaderID 
					AND t.TagTypeName = N'HWIncrement' 
	) AS hw
	
	OUTER APPLY
	(
	  SELECT	Tags	=	STUFF
							(
								(	
								  SELECT	',' + t.TagName
									FROM 	hwt.vw_AllTags AS t 
											INNER JOIN hwt.HeaderTag AS ht 
													ON ht.TagID = t.TagID
								   WHERE 	ht.HeaderID = h.HeaderID 	
												AND t.TagTypeName = N'UserDefined'
								ORDER BY  	t.TagName 
											FOR XML PATH (''), TYPE
								).value('.', 'nvarchar(max)'), 1, 1, '' 
							) 
	) AS u	
	
	OUTER APPLY
	(
      SELECT  	Procedures	=	STUFF
								(
									(	
									  SELECT 	',' + t.TagName
										FROM 	hwt.vw_AllTags AS t 
												INNER JOIN hwt.HeaderTag AS ht 
														ON ht.TagID = t.TagID
									   WHERE 	ht.HeaderID = h.HeaderID 
													AND t.TagTypeName = N'Procedure'
									ORDER BY 	t.TagName 
												FOR XML PATH (''), TYPE
									).value('.', 'nvarchar(max)'), 1, 1, '' 
								) 
	) AS tp	

	OUTER APPLY
	(
      SELECT 	Requirements	=	STUFF
									(
										(	
										  SELECT 	',' + t.TagName
											FROM 	hwt.vw_AllTags AS t 
													INNER JOIN hwt.HeaderTag AS ht 
															ON ht.TagID = t.TagID
										   WHERE 	ht.HeaderID = h.HeaderID 
														AND t.TagTypeName = N'ReqID'
										ORDER BY 	t.TagName 
													FOR XML PATH (''), TYPE
										).value('.', 'nvarchar(max)'), 1, 1, '' 
									) 
	) AS r	

	OUTER APPLY
	(
      SELECT	DeviceModels	=	STUFF
									(
										(	
										  SELECT 	',' + t.TagName
											FROM 	hwt.vw_AllTags AS t 
													INNER JOIN hwt.HeaderTag AS ht 
															ON ht.TagID = t.TagID
										   WHERE 	ht.HeaderID = h.HeaderID 
														AND t.TagTypeName = N'DeviceModel'
										ORDER BY 	t.TagName 
													FOR XML PATH (''), TYPE
										).value('.', 'nvarchar(max)'), 1, 1, '' 
									) 
	) AS dm

	OUTER APPLY
	(
      SELECT	DataStatus = t.TagName
		FROM    hwt.vw_AllTags AS t
				INNER JOIN hwt.HeaderTag AS ht 
						ON ht.TagID = t.TagID
       WHERE   	ht.HeaderID = h.HeaderID 
					AND t.TagTypeName = N'DataStatus' 
	) AS ds

	OUTER APPLY
	(
      SELECT	DUTTypes	=	STUFF
									(
										(	
										  SELECT 	',' + t.TagName
											FROM 	hwt.vw_AllTags AS t 
													INNER JOIN hwt.HeaderTag AS ht 
															ON ht.TagID = t.TagID
										   WHERE 	ht.HeaderID = h.HeaderID 
														AND t.TagTypeName = N'DUTType'
										ORDER BY 	t.TagName 
													FOR XML PATH (''), TYPE
										).value('.', 'nvarchar(max)'), 1, 1, '' 
									)  
	) AS dt

	OUTER APPLY	
	(
	  SELECT	FunctionBlock	=	STUFF
									(
										(	
										  SELECT 	',' + t.TagName
											FROM 	hwt.vw_AllTags AS t 
													INNER JOIN hwt.HeaderTag AS ht 
															ON ht.TagID = t.TagID
										   WHERE 	ht.HeaderID = h.HeaderID 
														AND t.TagTypeName = N'FunctionBlock'
										ORDER BY 	t.TagName 
													FOR XML PATH (''), TYPE
										).value('.', 'nvarchar(max)'), 1, 1, '' 
									) 
	) AS fb

	OUTER APPLY
	(
      SELECT	DeviceSN	=	STUFF
								(
									(	
									  SELECT 	',' + t.TagName
										FROM 	hwt.vw_AllTags AS t 
												INNER JOIN hwt.HeaderTag AS ht 
														ON ht.TagID = t.TagID
									   WHERE 	ht.HeaderID = h.HeaderID 
													AND t.TagTypeName = N'DeviceSN'
									ORDER BY 	t.TagName 
												FOR XML PATH (''), TYPE
									).value('.', 'nvarchar(max)'), 1, 1, '' 
								) 
	) AS sn

	OUTER APPLY
	(
      SELECT	DISTINCT 
				IsIgnored	=	1
		FROM	hwt.HeaderTag AS hTag 
	   WHERE	hTag.HeaderID = h.HeaderID 
				AND TagID IN ( SELECT TagID FROM hwt.Tag WHERE Name = 'Ignore' )
	) AS i
	
	OUTER APPLY
	(
      SELECT	DISTINCT 
				IsError	=	1 
		FROM	hwt.Vector AS v 
				INNER JOIN hwt.VectorError AS e 
						ON e.VectorID = v.VectorID 
	   WHERE 	v.HeaderID = h.HeaderID 
	) AS e	

	OUTER APPLY
	(
	  SELECT	DISTINCT 
				InProgress	=	1 
		FROM	hwt.HeaderTag AS hTag 
	   WHERE	hTag.HeaderID = h.HeaderID 
				AND TagID IN ( SELECT TagID FROM hwt.Tag WHERE Name = 'In-Progress' )
	) AS inP	

	
	OUTER APPLY
	(
      SELECT	ErrorText	=	STUFF
								(
									(	
									  SELECT 	DISTINCT 
												',' + te.ErrorText
										FROM 	hwt.VectorError AS te 
												INNER JOIN hwt.Vector AS v
														ON v.VectorID = te.VectorID 
									   WHERE 	v.HeaderID = h.HeaderID 
									ORDER BY 	1
												FOR XML PATH (''), TYPE
									).value('.', 'nvarchar(max)'), 1, 1, '' 
								) 
	) AS te
	
	
	OUTER APPLY
	(
      SELECT	Equipment	=	STUFF
								(
									(	
									  SELECT 	DISTINCT 
												',' + eq.Asset
										FROM 	hwt.Equipment AS eq
												INNER JOIN hwt.HeaderEquipment AS he
														ON he.EquipmentID = eq.EquipmentID 
									   WHERE 	he.HeaderID = h.HeaderID 
									ORDER BY	1
												FOR XML PATH (''), TYPE
									).value('.', 'nvarchar(max)'), 1, 1, '' 
								) 
	) AS eq ;
