CREATE	PROCEDURE hwt.usp_LoadAppConstFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadAppConstFromStage
	Abstract:	Load AppConst data from stage to hwt.AppConst and hwt.HeaderAppConst

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT data into temp storage from trigger
	3)	INSERT new AppConst data from temp storage into hwt.AppConst
	4)	UPDATE AppConstID back into temp storage
	5)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
	6)	UPDATE PublishDate on labViewStage.appConst_element
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

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.appConst_element' ) ;

--	2)	INSERT data into temp storage from PublishAudit
	  CREATE	TABLE #changes
					(
						ID				int
					  , HeaderID		int
					  , Name			nvarchar(100)
					  , Type			nvarchar(50)
					  , Units			nvarchar(50)
					  , Value			nvarchar(50)
					  , NodeOrder		int
					  , OperatorName	nvarchar(1000)
					  , AppConstID		int
					)
				;

	  INSERT	#changes
					( ID, HeaderID, Name, Type, Units, Value, NodeOrder, OperatorName )
	  SELECT	i.ID
			  , i.HeaderID
			  , Name			=	REPLACE( REPLACE( REPLACE( i.Name, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , i.Type
			  , Units			=	REPLACE( REPLACE( REPLACE( i.Units, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , Value			=	REPLACE( REPLACE( REPLACE( i.Value, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , NodeOrder		=	ISNULL( NULLIF( i.NodeOrder, 0 ), i.ID )
			  , h.OperatorName
		FROM	labViewStage.appConst_element AS i
				INNER JOIN	labViewStage.PublishAudit AS pa
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = i.ID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = i.HeaderID
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	3)	INSERT new AppConst data from temp storage into hwt.AppConst
		--	cte is the set of AppConst data that does not already exist on hwt
		--	newData is the set of data from cte with ID attached
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
					  SELECT	DISTINCT
								AppConstID	=	MIN( ID ) OVER( PARTITION BY c.Name, c.Type, c.Units )
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


--	4)	UPDATE AppConstID back into temp storage
	  UPDATE	tmp
		 SET	AppConstID	=	ac.AppConstID
		FROM	#changes AS tmp
				INNER JOIN hwt.AppConst AS ac
						ON ac.Name = tmp.Name
							AND ac.DataType = tmp.Type
							AND ac.Units = tmp.Units
				;


--	5)	INSERT header AppConst data from temp storage into hwt.HeaderAppConst
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
