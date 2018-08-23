CREATE PROCEDURE	hwt.usp_LoadOptionFromStage
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

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.option_element' ) ;
	 
	 DECLARE 	@Records	TABLE	( RecordID int ) ; 

--	7)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit 
	  OUTPUT	deleted.RecordID 
	    INTO	@Records( RecordID )
	   WHERE 	ObjectID = @ObjectID
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;

				
--	1)	INSERT new Option data from temp storage into hwt
	  INSERT	hwt.[Option]
					( Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT 
				Name			=	lvs.Name
			  , DataType		=	lvs.Type
			  , Units			=	lvs.Units
			  , UpdatedBy		=	FIRST_VALUE( h.OperatorName ) OVER( PARTITION BY lvs.Name, lvs.Type, lvs.Units ORDER BY lvs.ID )
			  , UpdatedDate		=	SYSDATETIME()
		FROM	labViewStage.option_element AS lvs
				INNER JOIN	@Records 
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

				
--	2)	INSERT data into temp storage from PublishAudit
	CREATE TABLE	#changes
					(
						ID				int
					  , HeaderID		int
					  , Name			nvarchar(250)
					  , Type			nvarchar(50)
					  , Units			nvarchar(250)
					  , Value			nvarchar(1000)
					  , NodeOrder		int
					  , OperatorName	nvarchar(50)
					  , OptionID		int
					)
					;

	  INSERT	INTO #changes
					( ID, HeaderID, Name, Type, Units, Value, NodeOrder, OperatorName, OptionID )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , i.NodeOrder		
			  , h.OperatorName
			  , o.OptionID
		FROM	labViewStage.option_element AS i
				INNER JOIN	@Records 
						ON	RecordID = i.ID

				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID

				INNER JOIN	hwt.[Option] AS o
						ON	o.Name = i.Name
								AND o.DataType = i.Type
								AND o.Units = i.Units
				;



--	5)	INSERT header OptionID data from temp storage into hwt.HeaderOptionID
	  INSERT	hwt.HeaderOption
					( HeaderID, OptionID, NodeOrder, OptionValue, UpdatedBy, UpdatedDate )

	  SELECT	HeaderID
			  , OptionID
			  , NodeOrder
			  , Value
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes AS tmp
				;


	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
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
