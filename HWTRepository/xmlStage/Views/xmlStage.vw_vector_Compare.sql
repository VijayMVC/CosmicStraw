CREATE VIEW		xmlStage.vw_vector_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_vector_Compare
	Abstract:	Returns differences between labViewStage.vector and xmlStage.vector


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.vector', *
	FROM	(
			  SELECT	HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime
				FROM	labViewStage.vector

			  EXCEPT
			  SELECT	HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime
				FROM	xmlStage.vector
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.vector', *
	FROM	(
			  SELECT	HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime
				FROM	xmlStage.vector

			  EXCEPT
			  SELECT	HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime
				FROM	labViewStage.vector
			) AS x
;
