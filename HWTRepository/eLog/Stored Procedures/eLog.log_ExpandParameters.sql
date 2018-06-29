CREATE 	PROCEDURE eLog.log_ExpandParameters
			(
				@pMessageIO		nvarchar(2048)				OUTPUT
			  ,	@pParamNum 		tinyint
			  , @pVariantIn     sql_variant
			  , @pStringOut		nvarchar(400) 	= 	NULL 	OUTPUT 
			)
/*
***********************************************************************************************************************************

    Procedure:	eLog.log_ExpandParameters
     Abstract:  helper procedure that expands error message parameters into actual error message text
	
	
    Logic Summary
    -------------

	From original comments
		This is a helper routine to eLog.LogProcessError: 
		1) CONVERT the input variant value to a string.
		2) Replace the corresponding parameter holder with the value in the error message.
			Note that if the parameter holder does not appear in the string,
			the string is returned as NULL, because there is no need to store it
			in eLog.EventLogParameter

    Parameters
    ----------
	@pMessageIO		nvarchar(2048)			inbound message text, with parameter holders
											returns formatted message text with expanded parameters
	@pParamNum 		tinyint					sequence from 1 to 6 ( proc support six parameters )
	@pVariantIn     sql_variant				incoming parameter value
	@pStringOut		nvarchar(400) 			return incoming parameter formatted as a string 

    Notes
    -----
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP 
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )
					

    Revision
    --------
    carsoc3     2018-02-20		Added to alpha release, refactored 
	carsoc3		2018-04-27		Original production release
	

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ; 
  
 DECLARE	@pPosition	char(2)	=	'%' + LTRIM( STR( @pParamNum ) )
		  , @vBaseType 	sysname 
			;


--	exit when desired parameter is not in the message text.
IF 	( CHARINDEX( @pPosition, @pMessageIO COLLATE Latin1_General_BIN2 ) = 0 )
BEGIN
	  SELECT 	@pStringOut	=	NULL ; 
		GOTO 	endOfProc ;
END

	
--	determine base type of inbound parameter
  SELECT 	@vBaseType = CONVERT( nvarchar(128), sql_variant_property( @pVariantIn, 'Basetype') ) ;


--	format string output based on input parameter base type
IF	( @pVariantIn IS NULL )
	BEGIN
		  SELECT 	@pStringOut = '(null)' ; 
			GOTO 	endOfProc ;
	END

	
	IF	( @vBaseType IN ( 'float', 'real' ) )
	BEGIN
		  SELECT	@pStringOut	= 	CASE 
										WHEN ABS( CONVERT( float, @pVariantIn ) ) BETWEEN 1E-4 AND 1E6 
											THEN CONVERT( nvarchar(23), CONVERT( float, @pVariantIn ) )
										WHEN ABS( CONVERT( float, @pVariantIn ) ) < 1E-9
											THEN CONVERT( nvarchar(23), CONVERT( float, @pVariantIn ) )
										ELSE CONVERT( nvarchar(23), CONVERT( float, @pVariantIn ), 2 )
									END 
					; 
			GOTO 	endOfProc ;
	END 	

	IF	( @vBaseType = 'datetimeoffset' )
	BEGIN
		  SELECT 	@pStringOut	= 	CONVERT( char(30), CONVERT( datetimeoffset(3), @pVariantIn ), 121 ) ;
			GOTO 	endOfProc ;
	END 
		

	IF 	( @vBaseType LIKE '%date%' )
	BEGIN 
		  SELECT	@pStringOut	= 	CASE
										WHEN CONVERT( varchar(12), CONVERT( datetime2(3), @pVariantIn ), 14 ) = '00:00:00.000'
											THEN CONVERT( varchar(10), CONVERT( date, @pVariantIn ), 121 )
										WHEN @vBaseType = 'smalldatetime' 
											THEN CONVERT( varchar(16), CONVERT( smalldatetime, @pVariantIn ), 121 )
										ELSE CONVERT( varchar(23), CONVERT( datetime2(3), @pVariantIn ), 121 )
									END 
					;
			GOTO 	endOfProc ;
	END

		
	IF 	( @vBaseType LIKE 'time' )
	BEGIN 
		  SELECT 	@pStringOut	=	CONVERT( char(12), CONVERT( time(3), @pVariantIn ), 14 ) ; 
			GOTO 	endOfProc ;
	END

									
	IF	( @vBaseType LIKE '%binary' ) OR ( @vBaseType = 'timestamp' )
	BEGIN 
		  SELECT 	@pStringOut	=	CONVERT( nvarchar(400), CONVERT( varbinary(8000 ), @pVariantIn ), 1 ) ;
			GOTO 	endOfProc ; 
	END

		
	SELECT @pStringOut = CONVERT( nvarchar(400), @pVariantIn ) ; 

endOfProc:

	SELECT @pMessageIO = REPLACE( @pMessageIO, @pPosition, ISNULL( @pStringOut, '' ) ) ;
