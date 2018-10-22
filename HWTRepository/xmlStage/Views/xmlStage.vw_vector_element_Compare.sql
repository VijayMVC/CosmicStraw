CREATE	VIEW xmlStage.vw_vector_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_vector_element_Compare
	Abstract:	Returns differences between labViewStage.vector_element and xmlStage.vector_element


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture
	carsoc3		2018-10-04		Revision -- Transform data in repository, accounting for differences in LabVIEW outputs

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.vector_element', *
	FROM	(
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, ve.Name, ve.Type, ve.Units
							, Value = REPLACE( REPLACE( ve.Value, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
							, ve.NodeOrder
				FROM	labViewStage.vector_element as ve
						INNER JOIN	labViewStage.vector AS v
								ON	v.ID = ve.VectorID

			  EXCEPT
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, ve.Name, ve.Type, ve.Units
							, ve.Value
							, ve.NodeOrder
				FROM	xmlStage.vector_element as ve
						INNER JOIN	xmlStage.vector AS v
								ON	v.ID = ve.VectorID
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.vector_element', *
	FROM	(
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, ve.Name, ve.Type, ve.Units
							, ve.Value
							, ve.NodeOrder
				FROM	xmlStage.vector_element as ve
						INNER JOIN	xmlStage.vector AS v
								ON	v.ID = ve.VectorID

			  EXCEPT
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, ve.Name, ve.Type, ve.Units
							, REPLACE( REPLACE( ve.Value, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
							, ve.NodeOrder
				FROM	labViewStage.vector_element as ve
						INNER JOIN	labViewStage.vector AS v
								ON	v.ID = ve.VectorID
			) AS x
;
