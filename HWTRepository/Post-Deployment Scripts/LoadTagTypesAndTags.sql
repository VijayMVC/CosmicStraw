﻿/*
Post-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/

IF NOT EXISTS( SELECT 1 FROM hwt.TagType WHERE TagTypeID = 1 )
	BEGIN 

			 SET 	IDENTITY_INSERT hwt.TagType ON ;  

		  INSERT 	hwt.TagType
						( TagTypeID, Name, Description, IsRestricted, IsPermanent, UpdatedBy, UpdatedDate )
		
		  VALUES	( 1 , N'TestMode', 			N'Test Mode used to gather the data.', 											1, 1, N'HWTAdmin', GETDATE() )
				  , ( 2 , N'Project', 			N'Project name.', 																1, 1, N'HWTAdmin', GETDATE() )
				  , ( 3 , N'DataStatus', 		N'The official status of the dataset. Indicates the usecase of the dataset.', 	0, 0, N'HWTAdmin', GETDATE() )
				  , ( 4 , N'Procedure', 		N'Procedure number associated with the dataset.', 								1, 1, N'HWTAdmin', GETDATE() )
				  , ( 5 , N'DeviceModel', 		N'Specific characteristics of the device under test.', 							1, 0, N'HWTAdmin', GETDATE() )
				  , ( 6 , N'FWRevision', 		N'Firmware revision under test', 												1, 1, N'HWTAdmin', GETDATE() )
				  , ( 7 , N'HWIncrement', 		N'Hardware revision of the hardware under test used to generate the dataset.', 	1, 0, N'HWTAdmin', GETDATE() )
				  , ( 8 , N'DUTType', 			N'Describes the type of device under test ( DUT )',								0, 0, N'HWTAdmin', GETDATE() )
				  , ( 9 , N'FunctionBlock', 	N'Functional block tested by the assigned dataset.', 							1, 0, N'HWTAdmin', GETDATE() )
				  , ( 10, N'Operator', 			N'Username of the test operator.', 												1, 1, N'HWTAdmin', GETDATE() )
				  , ( 11, N'DeviceSN', 			N'Status classification for the use of the data.', 								1, 1, N'HWTAdmin', GETDATE() )
				  , ( 12, N'UserDefined', 		N'A custom tag created by a user.', 											0, 0, N'HWTAdmin', GETDATE() )
				  , ( 13, N'Modifier', 			N'Specific dataset characteristics that may change.', 							0, 0, N'HWTAdmin', GETDATE() )
				  , ( 14, N'ReqID', 			N'ID for specific requirement under test', 										0, 0, N'HWTAdmin', GETDATE() )
					; 
	
			 SET 	IDENTITY_INSERT hwt.TagType OFF ; 
	
		  INSERT 	hwt.Tag
						( TagTypeID, Name, Description, IsDeleted, UpdatedBy, UpdatedDate ) 
		  
		  VALUES 	( 1, N'Simulation', 				N'Simulation test mode.', 																0, N'HWTAdmin', GETDATE())
				  , ( 1, N'Characterization', 			N'Characterization test mode.', 														0, N'HWTAdmin', GETDATE())
				  , ( 1, N'Verification', 				N'Verification test mode.', 															0, N'HWTAdmin', GETDATE())
				  , ( 3, N'Baseline', 					N'Baseline dataset used for other datasets to compare against.', 						0, N'HWTAdmin', GETDATE())
				  , ( 3, N'Draft', 						N'Dataset should not be used for official documents.', 									0, N'HWTAdmin', GETDATE())
				  , ( 3, N'Release', 					N'Dataset is marked as released.', 														0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Orion', 						N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Polaris', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Blackwell', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Blackwell (Scan DMA)', 		N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'BW (Flash Convert)', 		N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'BW HP MRI', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'BW MRI CRTD', 				N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'CRTP', 						N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'EvaraAF', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'EVICD', 						N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Galaxy', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Galaxy Boot/Test Inc1', 		N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Galaxy Boot/Test Inc2', 		N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Galaxy-Inc1', 				N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'InjReveal', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'InjReveal (Scan DMA)', 		N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'LINQ II', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'LINQ II (Peek/Poke DMA)', 	N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'LINQ II (Scan DMA)', 		N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Micra AVS', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Micra AVS (Peek/Poke DMA)', 	N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Micra AVS (Scan DMA)', 		N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'Polaris Proto', 				N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'PSA', 						N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'PSAOrion', 					N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 2, N'SubQ', 						N'', 																					0, N'HWTAdmin', GETDATE())
				  , ( 1, N'Evaluation', 				N'Evaluation test mode', 																0, N'HWTAdmin', GETDATE())
				  , ( 1, N'Development', 				N'Development test mode', 																0, N'HWTAdmin', GETDATE())
				  , ( 4, N'E_123', 						N'Procedure number E_123.', 															0, N'HWTAdmin', GETDATE())
				  , ( 4, N'PROC_001', 					N'Procedure number PROC_001.', 															0, N'HWTAdmin', GETDATE())
				  , ( 4, N'PROC_002', 					N'Procedure number PROC_002.', 															0, N'HWTAdmin', GETDATE())
				  , ( 4, N'PROC_003', 					N'Procedure number PROC_003.', 															0, N'HWTAdmin', GETDATE())
				  , ( 4, N'E_456', 						N'Procedure number E_456.', 															0, N'HWTAdmin', GETDATE())
				  , ( 4, N'TEST_01', 					N'Procedure number TEST_01.', 															0, N'HWTAdmin', GETDATE())
				  , ( 4, N'TEST_02', 					N'Procedure number TEST_02.', 															0, N'HWTAdmin', GETDATE())
				  , ( 4, N'PROC_004', 					N'Procedure number PROC_004.', 															0, N'HWTAdmin', GETDATE())
				  , ( 5, N'Dual', 						N'Dev Characteristic Dual.', 															0, N'HWTAdmin', GETDATE())
				  , ( 5, N'Bluetooth', 					N'Dev Characteristic Bluetooth.', 														0, N'HWTAdmin', GETDATE())
				  , ( 5, N'Quad', 						N'Dev Characteristic Quad.', 															0, N'HWTAdmin', GETDATE())
				  , ( 5, N'Dev Char A', 				N'Dev Characteristic A.', 																0, N'HWTAdmin', GETDATE())
				  , ( 5, N'Dev Char B', 				N'Dev Characteristic B.', 																0, N'HWTAdmin', GETDATE())
				  , ( 9, N'Func Blk 001', 				N'Function Block 001.', 																0, N'HWTAdmin', GETDATE())
				  , ( 9, N'Voltage Reg', 				N'Voltage Reg.', 																		0, N'HWTAdmin', GETDATE())
				  , ( 9, N'TX / RX', 					N'Function Block TX / RX.', 															0, N'HWTAdmin', GETDATE())
				  , ( 9, N'Amp Control', 				N'Function Block Amp Control.', 														0, N'HWTAdmin', GETDATE())
				  , ( 9, N'Frequency Mod', 				N'Frequency Modulation Control Block.', 												0, N'HWTAdmin', GETDATE())
				  , ( 8, N'Test Device', 				N'Test Device', 																		0, N'HWTAdmin', GETDATE())
				  , ( 8, N'Test Device 02', 			N'Test Device 02', 																		0, N'HWTAdmin', GETDATE())
				  , ( 8, N'Monitor', 					N'Monitor', 																			0, N'HWTAdmin', GETDATE())
				  , ( 8, N'Calibrator', 				N'Calibrator', 																			0, N'HWTAdmin', GETDATE())
				  , (12, N'JM Testing', 				N'Jon Meadows Search Results', 															0, N'HWTAdmin', GETDATE())
				  , (12, N'UD Tag 01', 					N'User Defined Tag 01', 																0, N'HWTAdmin', GETDATE())
				  , (12, N'Errors', 					N'Test Errors', 																		0, N'HWTAdmin', GETDATE())
				  , (12, N'Ignored', 					N'Ignored Results', 																	0, N'HWTAdmin', GETDATE())
				  , (13, N'Ignore', 					N'Due to somes event this dataset should not be used for analysis or documentation', 	0, N'HWTAdmin', GETDATE())
				  , (13, N'In-Progress', 				N'Dataset is currently incomplete. Test is currently being conducted.', 				0, N'HWTAdmin', GETDATE())
					;
	END
GO	  