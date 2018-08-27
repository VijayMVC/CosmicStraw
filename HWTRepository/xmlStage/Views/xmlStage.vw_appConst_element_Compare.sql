CREATE VIEW		xmlStage.vw_appConst_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_appConst_element_Compare
	Abstract:	Returns differences between labViewStage.appConst_element and xmlStage.appConst_element


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.appConst_element', *
	FROM	(
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	labViewStage.appConst_element

			  EXCEPT
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	xmlStage.appConst_element
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.appConst_element', *
	FROM	(
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	xmlStage.appConst_element

			  EXCEPT
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	labViewStage.appConst_element
			) AS x
			;
