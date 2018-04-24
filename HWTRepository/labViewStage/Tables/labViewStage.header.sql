CREATE TABLE	labViewStage.header
				(
					ID                  int				NOT NULL	
				  , ResultFile          nvarchar(1000)
				  , StartTime           nvarchar(100)
				  , FinishTime          nvarchar(100)
				  , TestDuration        nvarchar(100)
				  , ProjectName         nvarchar(100)
				  , FirmwareRev         nvarchar(100)
				  , HardwareRev         nvarchar(100)
				  , PartSN              nvarchar(100)
				  , OperatorName        nvarchar(100)
				  , TestMode            nvarchar(50)
				  , TestStationID       nvarchar(100)
				  , TestName            nvarchar(250)
				  , TestConfigFile      nvarchar(400)
				  , TestCodePathName    nvarchar(400)
				  , TestCodeRev         nvarchar(100)
				  , HWTSysCodeRev       nvarchar(100)
				  , KdrivePath          nvarchar(400)
				  , Comments            nvarchar(max)
				  , ExternalFileInfo    nvarchar(max)
				  , IsLegacyXML			int							DEFAULT 0 
				  , CreatedDate			datetime					DEFAULT GETDATE() 
				  , UpdatedDate			datetime					
				  
				  , CONSTRAINT PK_labViewStage_header 
						PRIMARY KEY CLUSTERED( ID ASC ) 
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]
						
				) 	ON [HWTTables]
				TEXTIMAGE_ON [HWTTables]
				;
