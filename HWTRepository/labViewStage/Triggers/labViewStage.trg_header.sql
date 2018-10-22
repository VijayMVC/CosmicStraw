CREATE TRIGGER	labViewStage.trg_header
			ON	labViewStage.header
		 AFTER	INSERT, UPDATE
/*
***********************************************************************************************************************************

	Procedure:	hwt.trg_header
	Abstract:	Loads header records from labViewStage into repository

	Logic Summary
	-------------
	1)	Load trigger data into temp storage
	2)	EXECUTE proc that loads header data into repository


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		enhanced error handling
								labViewStage messaging architecture

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON
;

BEGIN TRY
	IF	NOT EXISTS( SELECT 1 FROM inserted )
		RETURN
;

--	1)	Load trigger data into temp storage
	  SELECT	i.ID
			  , i.ResultFile
			  , i.StartTime
			  , i.FinishTime
			  , i.TestDuration
			  , ProjectName			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.ProjectName, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , FirmwareRev			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.FirmwareRev, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , HardwareRev			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.HardwareRev, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , PartSN				=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.PartSN, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , OperatorName		=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.OperatorName, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , i.TestMode
			  , TestStationID		=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.TestStationID, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , TestName			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.TestName, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , TestConfigFile		=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.TestConfigFile, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , TestCodePathName	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.TestCodePathName, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , i.TestCodeRev
			  , i.HWTSysCodeRev
			  , KdrivePath			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.KdrivePath, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , Comments			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.Comments, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , ExternalFileInfo	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.ExternalFileInfo, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , i.IsLegacyXML
			  , i.VectorCount
			  , i.CreatedDate
			  , i.UpdatedDate
		INTO	#inserted
		FROM	inserted AS i
;

--	2)	EXECUTE proc that loads header data into repository
	 EXECUTE	hwt.usp_LoadHeaderFromStage
;

END TRY
BEGIN CATCH
	 DECLARE	@pErrorData xml
;

	IF EXISTS( SELECT 1 FROM deleted )
		BEGIN
			  SELECT	@pErrorData =	(
										  SELECT
													(
													  SELECT	*
														FROM	inserted
																FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
													)
												  , (
													  SELECT	*
														FROM	deleted
																FOR XML PATH( 'deleted' ), TYPE, ELEMENTS XSINIL
													)
													FOR XML PATH( 'trg_header' ), TYPE
										)
;
		END
	ELSE
		BEGIN
			  SELECT	@pErrorData =	(
										  SELECT
													(
													  SELECT	*
														FROM	inserted
																FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
													)
													FOR XML PATH( 'trg_header' ), TYPE
										)
;
		END

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION
;
	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
;

END CATCH
