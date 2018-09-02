CREATE PROCEDURE
	hwt.usp_LoadOptionFromStage
		(
			@pHeaderXML		xml
		)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadOptionFromStage
	Abstract:	Load changed test options data from stage to hwt.Option and hwt.HeaderOption

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT option data from labViewStage into temp storage
	3)	INSERT new Option data from temp storage into hwt.Option
	4)	Apply OptionID back into temp storage
	5)	INSERT header OptionID data from temp storage into hwt.HeaderOptionID
	6)	UPDATE PublishDate on labViewStage.option_element
	7)	EXECUTE sp_releaseapplock to release lock

	Parameters
	----------

	Notes
	-----

	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling
								updated messaging architecture
									--	extract all records not published
									--	publish to hwt
									--	update stage data with publish date

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@loadHeader		TABLE	( HeaderID	int ) ;
	 DECLARE	@lvsRecord		TABLE	( RecordID	int ) ;


--	1)	SELECT the HeaderIDs that need to be published

	  INSERT	@loadHeader( HeaderID )
	  SELECT	loadHeader.xmlData.value( '@value[1]', 'int' )
		FROM	@pHeaderXML.nodes('LoadHeader/HeaderID') AS loadHeader(xmlData)
				;


--	2)	SELECT the labViewStage records that need to be published
	  INSERT	@lvsRecord( RecordID )
	  SELECT	ID
		FROM	labViewStage.option_element AS lvs
				INNER JOIN	@loadHeader AS h
						ON	h.HeaderID = lvs.HeaderID
				;

	IF	( @@ROWCOUNT = 0 ) RETURN ;


--	1)	INSERT new Option data from temp storage into hwt
	  INSERT	hwt.[Option]
					( Name, DataType, Units, CreatedBy, CreatedDate )
	  SELECT	DISTINCT
				Name			=	lvs.Name
			  , DataType		=	lvs.Type
			  , Units			=	lvs.Units
			  , CreatedBy		=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , CreatedDate		=	SYSDATETIME()
		FROM	labViewStage.option_element AS lvs
				INNER JOIN	@lvsRecord
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = lvs.HeaderID

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.[Option] AS o
					   WHERE	o.Name = lvs.Name
								AND o.DataType = lvs.Type
								AND o.Units = lvs.Units
					)
				;


--	5)	INSERT header OptionID data from temp storage into hwt.HeaderOptionID
	  INSERT	hwt.HeaderOption
					( HeaderID, OptionID, NodeOrder, OptionValue )

	  SELECT	HeaderID		=	i.HeaderID
			  , OptionID		=	o.OptionID
			  , NodeOrder		=	i.NodeOrder
			  , OptionValue		=	i.Value
		FROM	labViewStage.option_element AS i
				INNER JOIN	@lvsRecord
						ON	RecordID = i.ID

				INNER JOIN	hwt.[Option] AS o
						ON	o.Name = i.Name
								AND o.DataType = i.Type
								AND o.Units = i.Units
				;

	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	i.*
												FROM	labViewStage.option_element AS i
														INNER JOIN	@lvsRecord
																ON	RecordID = i.ID
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadOptionFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH
