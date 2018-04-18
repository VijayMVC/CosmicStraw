CREATE FUNCTION 
	utility.ufn_GetDuration( 
		@pStartTime	AS datetime
	  , @pEndTime	AS datetime
)
RETURNS nvarchar(20) 
AS
BEGIN
	-- Declare the return variable here
	DECLARE	@Duration as nvarchar(20) = NULL ; 

	
	SELECT 
		@Duration = STUFF( CONVERT( varchar(20), @pEndTime - @pStartTime, 108 ), 1, 2 
							, DATEDIFF( hour , 0 ,  @pEndTime - @pStartTime ) )
	; 

	IF LEFT( @Duration, 1 ) = N'-' 
		SELECT @Duration = N'' 
	; 

	RETURN @Duration ; 

END
GO

