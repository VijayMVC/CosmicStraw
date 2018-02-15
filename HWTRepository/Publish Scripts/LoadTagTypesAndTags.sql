/*
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
SET IDENTITY_INSERT [hwt].[TagType] ON 
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (1, N'TestMode', N'Test Mode used to gather the data.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Project', N'Project name.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (3, N'TestStatus', N'The official status of the dataset. Indicates the usecase of the dataset.', 1, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (4, N'Procedure', N'Procedure number associated with the dataset.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (5, N'DeviceCharacteristic', N'Specific characteristics of the device under test.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (6, N'FWRevision', N'Firmware revision under test', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (7, N'HWIncrement', N'Hardware revision of the hardware under test used to generate the dataset.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (8, N'DeviceType', N'', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (9, N'FunctionBlock', N'Functional block tested by the assigned dataset.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (10, N'Operator', N'Username of the test operator.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (11, N'DeviceSN', N'Status classification for the use of the data.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (12, N'UserDefined', N'A custom tag created by a user.', 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (13, N'Modifier', N'Modifier tags define specific characteristics of the dataset that may change. For example, the In-Progress tag is a modifier indicating that testing is currently under way.', 1, N'schoew4', CAST(N'2018-01-11T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[TagType] ([TagTypeID], [Name], [Description], [IsUserCreated], [UpdatedBy], [UpdatedDate]) VALUES (14, N'ReqID', N'ID for specific requirement under test', 1, N'carsoc3', CAST(N'2018-01-11T12:41:00.000' AS DateTime))
GO
SET IDENTITY_INSERT [hwt].[TagType] OFF
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (1, N'Simulation', N'Simulation test mode.', 1, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (1, N'Characterization', N'Characterization test mode.', 1, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (1, N'Verification', N'Verification test mode.', 1, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (3, N'Baseline', N'Baseline dataset used for other datasets to compare against.', 0, 0, N'schoew3', CAST(N'2018-01-10T12:47:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (3, N'Draft', N'Dataset sh ould not be used for official documents.', 0, 0, N'schoew3', CAST(N'2018-01-10T12:46:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (3, N'Release', N'Dataset is marked as released.', 0, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (13, N'Ignore', N'Due to somes event this dataset should not be used for analysis or documentation', 0, 0, N'schoew3', CAST(N'2018-01-10T12:48:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (13, N'In-Progress', N'Dataset is currently incomplete. Test is currently being conducted.', 0, 0, N'schoew3', CAST(N'2018-01-10T12:48:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Orion', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Polaris', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Blackwell', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Blackwell (Scan DMA)', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'BW (Flash Convert)', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:46:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'BW HP MRI', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'BW MRI CRTD', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:41:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'CRTP', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'EvaraAF', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:47:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'EVICD', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:48:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Galaxy', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:48:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Galaxy Boot/Test Inc1', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:49:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Galaxy Boot/Test Inc2', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:49:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Galaxy-Inc1', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:48:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'InjReveal', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:50:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'InjReveal (Scan DMA)', N'', 1, 0, N'schoew3', CAST(N'2018-01-10T12:50:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'LINQ II', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'LINQ II (Peek/Poke DMA)', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'LINQ II (Scan DMA)', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Micra AVS', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Micra AVS (Peek/Poke DMA)', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Micra AVS (Scan DMA)', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'Polaris Proto', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'PSA', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'PSAOrion', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (2, N'SubQ', N'', 1, 0, N'carsoc3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (1, N'Evaluation', N'Evaluation test mode', 1, 0, N'ccarso3', CAST(N'2018-01-19T00:00:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'E_123', N'Procedure number E_123.', 0, 0, N'schoew3', CAST(N'2018-01-10T12:49:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'PROC_001', N'Procedure number PROC_001.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.980' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'PROC_002', N'Procedure number PROC_002.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.980' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'PROC_003', N'Procedure number PROC_003.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.980' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'E_456', N'Procedure number E_456.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.980' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'TEST_01', N'Procedure number TEST_01.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.980' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'TEST_02', N'Procedure number TEST_02.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.980' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (4, N'PROC_004', N'Procedure number PROC_004.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.980' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (5, N'Dual', N'Dev Characteristic Dual.', 0, 0, N'schoew3', CAST(N'2018-01-10T12:49:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (5, N'Bluetooth', N'Dev Characteristic Bluetooth.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (5, N'Quad', N'Dev Characteristic Quad.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (5, N'Dev Char A', N'Dev Characteristic A.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (5, N'Dev Char B', N'Dev Characteristic B.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (9, N'Func Blk 001', N'Function Block 001.', 0, 0, N'schoew3', CAST(N'2018-01-10T12:49:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (9, N'Voltage Reg', N'Voltage Reg.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (9, N'TX / RX', N'Function Block TX / RX.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (9, N'Amp Control', N'Function Block Amp Control.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (9, N'Frequency Mod', N'Frequency Modulation Control Block.', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.983' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (8, N'Test Device', N'Test Device', 0, 0, N'schoew3', CAST(N'2018-01-10T12:49:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (8, N'Test Device 02', N'Test Device 02', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.987' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (8, N'Monitor', N'Monitor', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.987' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (8, N'Calibrator', N'Calibrator', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.987' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (12, N'JM Testing', N'Jon Meadows Search Results', 0, 0, N'schoew3', CAST(N'2018-01-10T12:49:00.000' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (12, N'UD Tag 01', N'User Defined Tag 01', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.990' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (12, N'Errors', N'Test Errors', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.990' AS DateTime))
GO
INSERT [hwt].[Tag] ([TagTypeID], [Name], [Description], [IsPermanent], [IsDeleted], [UpdatedBy], [UpdatedDate]) VALUES (12, N'Ignored', N'Ignored Results', 0, 0, N'carsoc3', CAST(N'2018-02-07T05:07:08.990' AS DateTime))
GO

