CREATE VIEW		xmlStage.vw_error_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_error_element_Compare
	Abstract:	Returns differences between labViewStage.error_element and xmlStage.error_element


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.error_element', *
	FROM	(
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, e.ErrorType, e.ErrorCode, e.ErrorText, e.NodeOrder
				FROM	labViewStage.error_element AS e
						INNER JOIN	labViewStage.vector AS v
								ON	v.ID = e.VectorID

			  EXCEPT
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, e.ErrorType, e.ErrorCode, e.ErrorText, e.NodeOrder
				FROM	xmlStage.error_element AS e
						INNER JOIN	xmlStage.vector AS v
								ON	v.ID = e.VectorID
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.error_element', *
	FROM	(
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, e.ErrorType, e.ErrorCode, e.ErrorText, e.NodeOrder
				FROM	xmlStage.error_element AS e
						INNER JOIN	xmlStage.vector AS v
								ON	v.ID = e.VectorID

			  EXCEPT
			  SELECT	v.HeaderID, v.VectorNum, v.Loop, v.StartTime
							, e.ErrorType, e.ErrorCode, e.ErrorText, e.NodeOrder
				FROM	labViewStage.error_element AS e
						INNER JOIN	labViewStage.vector AS v
								ON	v.ID = e.VectorID
			) AS x
			;
