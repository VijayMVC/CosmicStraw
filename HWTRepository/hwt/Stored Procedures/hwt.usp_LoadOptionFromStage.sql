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

--	2)	INSERT data into temp storage from PublishAudit
	CREATE TABLE	#changes
					(
						ID				int
					  , HeaderID		int
					  , Name			nvarchar(100)
					  , Type			nvarchar(50)
					  , Units			nvarchar(50)
					  , Value			nvarchar(1000)
					  , NodeOrder		int
					  , OperatorName	nvarchar(50)
					  , OptionID		int
					)
					;

	  INSERT	INTO #changes
					( ID, HeaderID, Name, Type, Units, Value, NodeOrder, OperatorName )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , NodeOrder		=	ISNULL( NULLIF( i.NodeOrder, 0 ), i.ID )
			  , h.OperatorName
		FROM	labViewStage.option_element AS i
				INNER JOIN	labViewStage.PublishAudit AS pa
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = i.ID

				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID
				;


	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	3)	INSERT new Option data from temp storage into hwt.Option
		--	cte is the set of Option data that does not already exist on hwt
		--	newData is the set of data from cte with ID attached
		WITH	cte AS
					(
					  SELECT	DISTINCT
								Name		=	tmp.Name
							  , DataType	=	tmp.Type
							  , Units		=	tmp.Units
						FROM	#changes AS tmp

					  EXCEPT
					  SELECT	Name
							  , DataType
							  , Units
						FROM	hwt.[Option]
					)

			  , newData AS
					(
					  SELECT	DISTINCT
								OptionID	=	MIN( ID ) OVER( PARTITION BY c.Name, c.Type, c.Units )
							  , Name		=	cte.Name
							  , DataType	=	cte.DataType
							  , Units		=	cte.Units
						FROM	#changes AS c
								INNER JOIN cte
										ON cte.Name = c.Name
											AND cte.DataType = c.Type
											AND cte.Units = c.Units
					)

	  INSERT	hwt.[Option]
					( OptionID, Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	OptionID		=	newData.OptionID
			  , Name			=	newData.Name
			  , DataType		=	newData.DataType
			  , Units			=	newData.Units
			  , UpdatedBy		=	x.OperatorName
			  , UpdatedDate		=	SYSDATETIME()
		FROM	newData
				CROSS APPLY
					( SELECT OperatorName FROM #changes AS c WHERE c.ID = newData.OptionID ) AS x
				;

--	4)	Apply OptionID back into temp storage
	  UPDATE	tmp
		 SET	OptionID	=	o.OptionID
		FROM	#changes AS tmp
				INNER JOIN
					hwt.[Option] AS o
						ON o.Name = tmp.Name
							AND o.DataType = tmp.Type
							AND o.Units = tmp.Units
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


--	7)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	pa
		FROM	labViewStage.PublishAudit AS pa
				INNER JOIN	#changes AS tmp
						ON	pa.ObjectID = @ObjectID
							AND tmp.ID = pa.RecordID
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
