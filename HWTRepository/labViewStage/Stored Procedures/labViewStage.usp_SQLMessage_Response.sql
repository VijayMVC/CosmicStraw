CREATE PROCEDURE labViewStage.usp_SQLMessage_Response
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_AssignTagsToDatasets
    Abstract:   Assigns existing tags to repository datasets

    Logic Summary
    -------------
    1)  INSERT data into hwt.Tag from input parameters 

    Parameters
    ----------
    @pUserID        sysname			UserID who is making the assignment
    @pHeaderID     	nvarchar(max) 	pipe-delimited list of datasets to which tags are assigned
    @pTagID         nvarchar(max) 	pipe-delimited list of tags assigned to datasets 
    @pNotes			nvarchar(200)	user comments documenting the tag assignment
	
    Notes
    -----
	If tag is already assigned to a dataset, update the assignment instead of inserting it

    Revision
    --------
    carsoc3     2018-04-27		production release

***********************************************************************************************************************************
*/	
AS


RETURN 0 ;