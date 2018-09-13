  CREATE TABLE [labViewStage].[appConst_element] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [HeaderID]    INT            NOT NULL,
    [Name]        NVARCHAR (250) NULL,
    [Type]        NVARCHAR (50)  NULL,
    [Units]       NVARCHAR (250) NULL,
    [Value]       NVARCHAR (MAX) NULL,
    [NodeOrder]   INT            CONSTRAINT [DF__appConst___NodeO__25518C17] DEFAULT ((0)) NOT NULL,
    [CreatedDate] DATETIME2 (3)  CONSTRAINT [DF__appConst___Creat__2645B050] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_labViewStage_appConst_element] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_labViewStage_appConst_element_header] FOREIGN KEY ([HeaderID]) REFERENCES [labViewStage].[header] ([ID])
);


GO

  CREATE NONCLUSTERED INDEX [IX_labViewStage_appConst_element_HeaderID]
    ON [labViewStage].[appConst_element]([HeaderID] ASC)
    ON [HWTIndexes];


GO

  CREATE NONCLUSTERED INDEX [IX_labViewStage_appConst_element_Name]
    ON [labViewStage].[appConst_element]([Name] ASC, [Type] ASC, [Units] ASC)
    ON [HWTIndexes];


