CREATE	PROCEDURE hwt.usp_LoadAppConstFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadAppConstFromStage
	Abstract:	Load AppConst data from stage to hwt.AppConst and hwt.HeaderAppConst

	Logic Summary
	-------------
	1)	INSERT data into temp storage from trigger
	2)	INSERT new AppConst data from temp storage into hwt.AppConst
	3)	UPDATE AppConstID back into temp storage
	4)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
	5)	UPDATE PublishDate on labViewStage.appConst_element

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

	--	define temp storage tables
	CREATE TABLE	#changes
					(
						ID				int
					  , HeaderID		int
					  , Name			nvarchar(100)
					  , Type			nvarchar(50)
					  , Units			nvarchar(50)
					  , Value			nvarchar(50)
					  , OperatorName	nvarchar(1000)
					  , NodeOrder		int
					  , AppConstID		int
					)
					;


--	1)	INSERT data into temp storage from trigger
	  INSERT	#changes
					( ID, HeaderID, Name, Type, Units, Value, OperatorName, NodeOrder )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.Name
			  , i.Type
			  , i.Units
			  , i.Value
			  , h.OperatorName
			  , NodeOrder		=	CASE i.NodeOrder
										WHEN	0 THEN existingCount.N + ROW_NUMBER() OVER( PARTITION BY i.HeaderID ORDER BY i.CreatedDate, i.ID )
										ELSE	i.NodeOrder
									END
		FROM	labViewStage.appConst_element AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID

				OUTER APPLY
					(
					  SELECT	COUNT(*)
						FROM	labViewStage.appConst_element AS lvs
					   WHERE	lvs.HeaderID = i.HeaderID
									AND lvs.PublishDate IS NOT NULL
					) AS existingCount(N)

	   WHERE	i.PublishDate IS NULL
				;


--	2)	INSERT new AppConst data from temp storage into hwt.AppConst
		--	cte is the distinct AppConst records that do not already exist on hwt
		--	newData is the records from cte with ID attached
		--	formatted
		WITH	cte AS
					(
					  SELECT	Name		=	tmp.Name
							  , DataType	=	tmp.Type
							  , Units		=	tmp.Units
						FROM	#changes AS tmp

					  EXCEPT
					  SELECT	Name
							  , DataType
							  , Units
						FROM	hwt.AppConst
					)

			  , newData AS
					(
					  SELECT	AppConstID	=	MIN( ID ) OVER( PARTITION BY c.Name, c.Type, c.Units )
							  , Name		=	cte.Name
							  , DataType	=	cte.DataType
							  , Units		=	cte.Units
						FROM	#changes AS c
								INNER JOIN cte
										ON cte.Name = c.Name
											AND cte.DataType = c.Type
											AND cte.Units = c.Units
					)

	  INSERT	hwt.AppConst
					( AppConstID, Name, DataType, Units, UpdatedBy, UpdatedDate )
	  SELECT	AppConstID		=	newData.AppConstID
			  , Name			=	newData.Name
			  , DataType		=	newData.DataType
			  , Units			=	newData.Units
			  , UpdatedBy		=	x.OperatorName
			  , UpdatedDate		=	SYSDATETIME()
		FROM	newData
				CROSS APPLY 
					( SELECT OperatorName FROM #changes AS c WHERE c.ID = newData.AppConstID ) AS x 
				;


--	3)	UPDATE AppConstID back into temp storage
	  UPDATE	tmp
		 SET	AppConstID	=	ac.AppConstID
		FROM	#changes AS tmp
				INNER JOIN hwt.AppConst AS ac
						ON ac.Name = tmp.Name
							AND ac.DataType = tmp.Type
							AND ac.Units = tmp.Units
				;


--	4)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
	  INSERT	hwt.HeaderAppConst
					( HeaderID, AppConstID, NodeOrder, AppConstValue, UpdatedBy, UpdatedDate )

	  SELECT	HeaderID
			  , AppConstID
			  , NodeOrder
			  , Value
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes
				;

--	5)	UPDATE PublishDate on labViewStage.appConst_element				
	  UPDATE	lvs
		 SET	PublishDate	=	SYSDATETIME() 
		FROM	labViewStage.appConst_element AS lvs
	   WHERE	EXISTS
					( SELECT 1 FROM #changes AS c WHERE c.ID = lvs.ID ) 
				
END TRY

BEGIN CATCH
	 DECLARE	@pErrorData	xml ;

	  SELECT	@pErrorData	=	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadAppConstFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pErrorData
				;

	RETURN 55555 ;

END CATCH
