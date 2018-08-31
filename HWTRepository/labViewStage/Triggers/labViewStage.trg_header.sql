CREATE TRIGGER
	labViewStage.trg_header
		ON labViewStage.header
		AFTER INSERT, UPDATE
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

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	IF	NOT EXISTS( SELECT 1 FROM inserted )
		RETURN ;


--	1)	Load trigger data into temp storage
	  SELECT	i.ID
			  , i.ResultFile
			  , i.StartTime
			  , i.FinishTime
			  , i.TestDuration
			  , i.ProjectName
			  , i.FirmwareRev
			  , i.HardwareRev
			  , i.PartSN
			  , i.OperatorName
			  , i.TestMode
			  , i.TestStationID
			  , i.TestName
			  , i.TestConfigFile
			  , i.TestCodePathName
			  , i.TestCodeRev
			  , i.HWTSysCodeRev
			  , i.KdrivePath
			  , i.Comments
			  , i.ExternalFileInfo
			  , i.IsLegacyXML
			  , i.VectorCount
			  , i.CreatedDate
			  , i.UpdatedDate
		INTO	#inserted
		FROM	inserted AS i
				;


--	2)	EXECUTE proc that loads header data into repository
	 EXECUTE	hwt.usp_LoadHeaderFromStage ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

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

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
