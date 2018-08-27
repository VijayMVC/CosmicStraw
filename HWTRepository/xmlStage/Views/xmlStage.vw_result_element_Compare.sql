CREATE VIEW		xmlStage.vw_result_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_result_element_Compare
	Abstract:	Returns differences between labViewStage.result_element and xmlStage.result_element


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.result_element', *
	FROM	(
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, r.Name, r.Type, r.Units, r.Value, r.NodeOrder
				FROM	labViewStage.result_element AS r
						INNER JOIN	labViewStage.vector AS v
								ON	v.ID = r.VectorID

			  EXCEPT
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, r.Name, r.Type, r.Units, r.Value, r.NodeOrder
				FROM	xmlStage.result_element AS r
						INNER JOIN	xmlStage.vector AS v
								ON	v.ID = r.VectorID
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.result_element', *
	FROM	(
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, r.Name, r.Type, r.Units, r.Value, r.NodeOrder
				FROM	xmlStage.result_element AS r
						INNER JOIN	xmlStage.vector AS v
								ON	v.ID = r.VectorID

			  EXCEPT
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, r.Name, r.Type, r.Units, r.Value, r.NodeOrder
				FROM	labViewStage.result_element AS r
						INNER JOIN	labViewStage.vector AS v
								ON	v.ID = r.VectorID
			) AS x
			;
