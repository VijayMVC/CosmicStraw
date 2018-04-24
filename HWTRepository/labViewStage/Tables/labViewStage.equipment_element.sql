CREATE TABLE 	labViewStage.equipment_element 
				(
					ID                  int             NOT NULL
				  , HeaderID            int             NOT NULL
				  , Description         nvarchar(100)
				  , Asset               nvarchar(50)
				  , CalibrationDueDate  nvarchar(50)
				  , CostCenter          nvarchar(50)	
				  , CreatedDate 		datetime					DEFAULT GETDATE()
							  
				  , CONSTRAINT PK_labViewStage_equipment_element 
						PRIMARY KEY CLUSTERED( ID ASC ) 
						WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]
				  
				  , CONSTRAINT FK_labViewStage_equipment_element_header 
						FOREIGN KEY( HeaderID ) 
						REFERENCES labViewStage.header( ID )
				
				) 	ON [HWTTables]
				;
GO 
  
CREATE INDEX 	IX_labViewStage_equipment_element_name 
		  ON 	labViewStage.equipment_element
					( HeaderID ASC, Asset ASC, Description ASC, CostCenter ASC ) 
		WITH	( DATA_COMPRESSION = PAGE ) 
		  ON	[HWTIndexes]
				;
