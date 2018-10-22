CREATE 	VIEW xmlStage.vw_option_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_option_element_Compare
	Abstract:	Returns differences between labViewStage.option_element and xmlStage.option_element


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture
	carsoc3		2018-10-04		Revision -- Transform data in repository, accounting for differences in LabVIEW outputs

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.option_element', *
	FROM	(
			  SELECT	HeaderID, Name, Type, Units
					  , Value = REPLACE( REPLACE( o.Value, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
					  , NodeOrder
				FROM	labViewStage.option_element AS o

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
			  SELECT	HeaderID, Name, Type, Units
					  , Value = REPLACE( REPLACE( o.Value, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
					  , NodeOrder
				FROM	labViewStage.option_element AS o
			) AS x
;
