CREATE PROCEDURE
    hwt.usp_InsertTagToRepository(
        @pTagType     	AS  nvarchar(50)
      , @pName          AS  nvarchar(50)
      , @pDescription   AS  nvarchar(100)
      , @pIsPermanent   AS  int =   0
    )
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_InsertTagToRepository
    Abstract:   Adds new tags to repository

    Logic Summary
    -------------
    1)  INSERT data into hwt.Tag from input parameters 

    Parameters
    ----------
    @pUserID        nvarchar(128)
    @pTagTypeID     int
    @pName          nvarchar(50)
    @pDescription   nvarchar(100)
    @pIsPermanent   int 
	
    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/	
AS
SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

    DECLARE
        @ErrorMessage   AS  nvarchar(max) ;

    INSERT INTO
        hwt.Tag(
            TagTypeID
          , Name
          , Description
          , IsPermanent
		  , IsDeleted
          , UpdatedDate
          , UpdatedBy )
    SELECT
        TagTypeID       =   tType.TagTypeID
      , Name            =   @pName
      , Description     =   @pDescription
      , IsPermanent     =   @pIsPermanent
	  , IsDeleted		=	0
      , UpdatedDate     =   GETDATE()
      , UpdatedBy       =   CURRENT_USER
	FROM 
		hwt.TagType AS tType 
			WHERE tType.TagTypeID = @pTagType
    ;

    RETURN 0 ;

END TRY
BEGIN CATCH
    PRINT 'Throwing Error' ;
    IF @ErrorMessage IS NOT NULL
        THROW 60000, @ErrorMessage , 1;
    ELSE
        THROW ;
END CATCH
