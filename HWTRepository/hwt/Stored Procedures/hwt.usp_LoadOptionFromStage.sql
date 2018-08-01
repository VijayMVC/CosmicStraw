CREATE PROCEDURE	hwt.usp_LoadOptionFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadOptionFromStage
	Abstract:	Load changed test options data from stage to hwt.Option and hwt.HeaderOption

	Logic Summary
	-------------
	1)	INSERT data into temp storage from trigger
	2)	INSERT new Option data from temp storage into hwt.Option
	3)	UPDATE OptionID back into temp storage
	4)	INSERT header Option data from temp storage into hwt.HeaderOption

	Parameters
	----------

	Notes
	-----


	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/
AS
RETURN 0 ; 

--SET XACT_ABORT, NOCOUNT ON ;

--BEGIN TRY

--	--	define temp storage tables
--	IF	( 1 = 0 )
--		CREATE TABLE	#inserted
--						(
--							ID			int
--						  , HeaderID	int
--						  , Name		nvarchar(100)
--						  , Type		nvarchar(50)
--						  , Units		nvarchar(50)
--						  , Value		nvarchar(1000)
--						  , CreatedDate datetime
--						)
--						;

--	CREATE TABLE	#changes
--					(
--						ID				int
--					  , HeaderID		int
--					  , Name			nvarchar(100)
--					  , Type			nvarchar(50)
--					  , Units			nvarchar(50)
--					  , Value			nvarchar(1000)
--					  , OperatorName	nvarchar(50)
--					  , OptionN			int
--					  , OptionID		int
--					)
--					;

----	1)	INSERT data into temp storage from trigger
--	  INSERT	INTO #changes
--					( ID, HeaderID, Name, Type, Units, Value, OperatorName, OptionN )
--	  SELECT	i.ID
--			  , i.HeaderID
--			  , i.Name
--			  , i.Type
--			  , i.Units
--			  , i.Value
--			  , h.OperatorName
--			  , OptionN			=	existingCount.N + ROW_NUMBER() OVER( PARTITION BY i.HeaderID, i.Name, i.Type, i.Units ORDER BY i.ID )
--		FROM	#inserted AS i
--				INNER JOIN labViewStage.header AS h
--						ON h.ID = i.HeaderID

--				OUTER APPLY
--					(
--					  SELECT	COUNT(*)
--						FROM	labViewStage.option_element AS lvs
--					   WHERE	lvs.HeaderID = i.HeaderID
--									AND lvs.Name = i.Name
--									AND lvs.Type = i.Type
--									AND lvs.Units = i.Units
--					) AS existingCount(N)
--				;


----	2)	INSERT new Option data from temp storage into hwt.Option
--		WITH	cte AS
--					(
--					  SELECT	DISTINCT
--								Name		=	tmp.Name
--							  , DataType	=	tmp.Type
--							  , Units		=	tmp.Units
--						FROM	#changes AS tmp

--					  EXCEPT
--					  SELECT	Name
--							  , DataType
--							  , Units
--						FROM	hwt.[Option]
--					)

--	  INSERT	hwt.[Option]
--					( Name, DataType, Units, UpdatedBy, UpdatedDate )
--	  SELECT	DISTINCT
--				Name		=	cte.Name
--			  , DataType	=	cte.DataType
--			  , Units		=	cte.Units
--			  , UpdatedBy	=	tmp.OperatorName
--			  , UpdatedDate =	SYSDATETIME()
--		FROM	cte
--				INNER JOIN	#changes AS tmp
--						ON	tmp.Name = cte.Name
--								AND tmp.Type = cte.DataType
--								AND tmp.Units = cte.Units
--				;

----	3)	Apply AppConstID back into temp storage
--	  UPDATE	tmp
--		 SET	OptionID	=	o.OptionID
--		FROM	#changes AS tmp
--				INNER JOIN
--					hwt.[Option] AS o
--						ON o.Name = tmp.Name
--							AND o.DataType = tmp.Type
--							AND o.Units = tmp.Units
--				;


----	4)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
--	  INSERT	hwt.HeaderOption
--					( HeaderID, OptionID, OptionN, OptionValue, UpdatedBy, UpdatedDate )

--	  SELECT	HeaderID
--			  , OptionID
--			  , OptionN
--			  , Value
--			  , OperatorName
--			  , SYSDATETIME()
--		FROM	#changes AS tmp
--				;


--	RETURN 0 ;

--END TRY

--BEGIN CATCH
--	 DECLARE	@pErrorData xml ;

--	  SELECT	@pErrorData =	(
--								  SELECT
--											(
--											  SELECT	*
--												FROM	#inserted
--														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
--											)
--										  , (
--											  SELECT	*
--												FROM	#changes
--														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
--											)
--											FOR XML PATH( 'usp_LoadOptionFromStage' ), TYPE
--								)
--				;

--	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

--	 EXECUTE	eLog.log_CatchProcessing
--					@pProcID	=	@@PROCID
--				  , @pErrorData =	@pErrorData
--				;

--	RETURN 55555 ;

--END CATCH
