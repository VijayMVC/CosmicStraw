CREATE	VIEW xmlStage.vw_appConst_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_appConst_element_Compare
	Abstract:	Returns differences between labViewStage.appConst_element and xmlStage.appConst_element


	Notes
	-----

	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture
	carsoc3		2018-10-04		Revision -- Transform data in repository, accounting for differences in LabVIEW outputs

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.appConst_element', *
	FROM	(
			  SELECT	HeaderID, Name, Type, Units
					  , Value = REPLACE( REPLACE( a.Value, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
					  , NodeOrder
				FROM	labViewStage.appConst_element AS a

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
			  SELECT	HeaderID, Name, Type, Units
					  , Value = REPLACE( REPLACE( a.Value, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
					  , NodeOrder
				FROM	labViewStage.appConst_element AS a
			) AS x
;
