CREATE VIEW		xmlStage.vw_equipment_element_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_equipment_element_Compare
	Abstract:	Returns differences between labViewStage.equipment_element and xmlStage.equipment_element


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.equipment_element', *
	FROM	(
			  SELECT	HeaderID, Asset, Description, CalibrationDueDate, CostCenter, NodeOrder
				FROM	labViewStage.equipment_element

			  EXCEPT
			  SELECT	HeaderID, Asset, Description, CalibrationDueDate, CostCenter, NodeOrder
				FROM	xmlStage.equipment_element
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.equipment_element', *
	FROM	(
			  SELECT	HeaderID, Asset, Description, CalibrationDueDate, CostCenter, NodeOrder
				FROM	xmlStage.equipment_element

			  EXCEPT
			  SELECT	HeaderID, Asset, Description, CalibrationDueDate, CostCenter, NodeOrder
				FROM	labViewStage.equipment_element
			) AS x
			;
