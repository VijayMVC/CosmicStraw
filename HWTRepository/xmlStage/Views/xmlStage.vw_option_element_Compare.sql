CREATE VIEW		xmlStage.vw_option_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_option_element_Compare
	Abstract:	Returns differences between labViewStage.option_element and xmlStage.option_element


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.option_element', *
	FROM	(
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	labViewStage.option_element

			  EXCEPT
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	xmlStage.option_element
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.option_element', *
	FROM	(
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	xmlStage.option_element

			  EXCEPT
			  SELECT	HeaderID, Name, Type, Units, Value, NodeOrder
				FROM	labViewStage.option_element
			) AS x
			;
