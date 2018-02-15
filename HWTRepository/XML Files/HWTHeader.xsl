<xsl:stylesheet 
	version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
<xsl:output 
	method="text" 
	indent="yes" 
	encoding="US-ASCII"/>   
	
<xsl:template name="replace">
	<xsl:param name="text" />
	<xsl:param name="searchString" >'</xsl:param>
	<xsl:param name="replaceString" >''</xsl:param>
	<xsl:choose>
		<xsl:when test="contains($text,$searchString)">
			<xsl:value-of select="substring-before($text,$searchString)"/>
			<xsl:value-of select="$replaceString"/>
		   <!--  recursive call -->
			<xsl:call-template name="replace">
				<xsl:with-param name="text" select="substring-after($text,$searchString)" />
				<xsl:with-param name="searchString" select="$searchString" />
				<xsl:with-param name="replaceString" select="$replaceString" />
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>		
	
<xsl:template match="@*|node(  )"> 
	<xsl:apply-templates select="@*|node(  )"/> 
</xsl:template>   
	
	
	
<xsl:template match="header">
DECLARE 
	@HeaderID AS INT ; 

SELECT 
	@HeaderID 	=	ISNULL( MAX( ID ), 0 ) + 1 
FROM 
	xmlStage.header ; 

INSERT INTO 
	xmlStage.header( 
		ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev, HardwareRev, PartSN
	  , OperatorName, TestStationID, TestName, TestConfigFile, TestCodePathName, TestCodeRev, HWTSysCodeRev
	  ,	KdrivePath, ExternalFileInfo, Comments )
SELECT 
	ID					=	@HeaderID
  , ResultFile			=	'<xsl:value-of select="Result_File" />'
  , StartTime			=	'<xsl:value-of select="Start_Time" />'
  , FinishTime			=	'<xsl:value-of select="Finish_Time" />'
  , TestDuration		=	'<xsl:value-of select="Test_Duration" />'
  , ProjectName			=	'<xsl:value-of select="Project_Name" />'
  , FirmwareRev			=	'<xsl:value-of select="Firmware_Rev" />'
  , HardwareRev			=	'<xsl:value-of select="Hardware_Rev" />'
  , PartSN				=	'<xsl:value-of select="Part_SN" />'
  , OperatorName		=	'<xsl:value-of select="Operator_Name" />'
  , TestStationID		=	'<xsl:value-of select="Test_Station_ID" />'
  , TestName			=	'<xsl:value-of select="Test_Name" />'
  , TestConfigFile		=	'<xsl:value-of select="Test_Config_File" />'
  , TestCodePathName	=	'<xsl:value-of select="Test_Code_Path_Name" />'
  , TestCodeRev			=	'<xsl:value-of select="Test_Code_Rev" />'
  , HWTSysCodeRev		=	'<xsl:value-of select="HWTSys_Code_Rev" />'
  ,	KdrivePath			=	'<xsl:value-of select="Kdrive_Path" />'
  , ExternalFileInfo	=	'<xsl:call-template name="replace">
								<xsl:with-param name="text" select="External_File_Info"/>
							</xsl:call-template>'
  , Comments			=	'<xsl:value-of select="Comments" />'
;
<xsl:apply-templates/>
</xsl:template>   



<xsl:template match="equipment">
	<xsl:apply-templates select="equipment_element"/>
</xsl:template>

<xsl:template match="equipment_element">
	<xsl:choose>
		<xsl:when test="position() mod 950 = 1">
INSERT INTO 
	xmlStage.equipment_element( 
		HeaderID, Description, Asset, CalibrationDueDate, CostCenter )
VALUES</xsl:when>
	</xsl:choose>
	( 	@HeaderID, '<xsl:value-of select="Description" />', '<xsl:value-of select="Asset" />', '<xsl:value-of select="Calibration_Due_Date" />', '<xsl:value-of select="Cost_Center" />' )<xsl:if test="not( position()=last() or (position() mod 950 = 0 ) )"> ,</xsl:if>
<xsl:if test="position()=last() or position() mod 950 = 0 ">
;
</xsl:if>
</xsl:template>	



<xsl:template match="options">
	<xsl:apply-templates select="option_element"/>
</xsl:template>


<xsl:template match="option_element">
	<xsl:choose>
		<xsl:when test="position() mod 950 = 1">
		
INSERT INTO 
	xmlStage.option_element( 
		HeaderID, Name, Type, Units, Value )
VALUES</xsl:when>
	</xsl:choose>
	( 	@HeaderID, '<xsl:value-of select="name" />', '<xsl:value-of select="type" />', '<xsl:value-of select="units" />', '<xsl:value-of select="value" />' )<xsl:if test="not( position()=last() or (position() mod 950 = 0 ) )"> ,</xsl:if>
<xsl:if test="position()=last() or position() mod 950 = 0 ">
;
</xsl:if>
</xsl:template>	

		

<xsl:template match="LibraryInfo">
	<xsl:apply-templates select="file" />
</xsl:template>	

<xsl:template match="file">
	<xsl:choose>
		<xsl:when test="position() mod 100 = 1">	
INSERT INTO 
	xmlStage.libraryInfo_file( 
		HeaderID, FileName, FileRev, Status, HashCode )
VALUES</xsl:when>
	</xsl:choose>
	( 	@HeaderID, '<xsl:value-of select="@name" />', '<xsl:value-of select="@rev" />', '<xsl:value-of select="@status" />', '<xsl:value-of select="@HashCode" />' )<xsl:if test="not( position()=last() or (position() mod 100 = 0 ) )"> ,</xsl:if>
<xsl:if test="position()=last() or position() mod 100 = 0 ">
;
</xsl:if>
</xsl:template>		



<xsl:template match="vector">
INSERT INTO 
	xmlStage.vector( 
		HeaderID, VectorNumber, ReqID, StartTime, EndTime )
VALUES
	(	@HeaderID, <xsl:value-of select="num" />, '<xsl:value-of select="ReqID" />', '<xsl:value-of select="Timestamp/StartTime" />', '<xsl:value-of select="Timestamp/EndTime" />' ) 
; 
<xsl:apply-templates select="vector_element">
  <xsl:with-param name="VectorNumber" select="num"/>
</xsl:apply-templates>
<xsl:apply-templates select="result_element"/>
</xsl:template>	  


<xsl:template match="vector_element">
  <xsl:param name="VectorNumber"/>
	<xsl:choose>
		<xsl:when test="position() mod 950 = 1">	
INSERT INTO 
	xmlStage.vector_element( 
		HeaderID, VectorNumber, Name, Type, Units, Value )
VALUES</xsl:when>
	</xsl:choose>
	( 	@HeaderID, <xsl:value-of select="$VectorNumber" />, '<xsl:value-of select="name" />', '<xsl:value-of select="type" />', '<xsl:value-of select="units" />', '<xsl:value-of select="value" />' )<xsl:if test="not( position()=last() or (position() mod 950 = 0 ) )"> ,</xsl:if>
<xsl:if test="position()=last() or position() mod 950 = 0 ">
;
</xsl:if>
</xsl:template>	 


<xsl:template match="result_element">
INSERT INTO 
	xmlStage.result_element( 
		HeaderID, VectorNumber, Name, Type, Units, N, Value )
VALUES<xsl:apply-templates select="value"/>
</xsl:template>	
	
	
<xsl:template match="value">
	<xsl:choose>
		<xsl:when test="position() mod 950 = 1 and not( position() = 1 )">	
INSERT INTO 
	xmlStage.result_element( 
		HeaderID, VectorNumber, Name, Type, Units, N, Value )
VALUES</xsl:when>
	</xsl:choose>		
	( 	@HeaderID, <xsl:value-of select="../../num" />, '<xsl:value-of select="../name"/>', '<xsl:value-of select="../type" />', '<xsl:value-of select="../units" />', <xsl:value-of select="position()"/>, '<xsl:value-of select="text()" />' )<xsl:if test="not( position()=last() or (position() mod 950 = 0 ) )"> ,</xsl:if>
<xsl:if test="position()=last() or position() mod 950 = 0">
;
</xsl:if>
</xsl:template>	 	



</xsl:stylesheet>