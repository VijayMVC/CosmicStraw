  CREATE TABLE [xmlStage].[appConst_element] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [HeaderID]    INT            NOT NULL,
    [Name]        NVARCHAR (250) NULL,
    [Type]        NVARCHAR (50)  NULL,
    [Units]       NVARCHAR (250) NULL,
    [Value]       NVARCHAR (MAX) NULL,
    [NodeOrder]   INT            CONSTRAINT [DF__appConst___NodeO__3FD07829] DEFAULT ((0)) NOT NULL,
    [CreatedDate] DATETIME2 (3)  CONSTRAINT [DF__appConst___Creat__40C49C62] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_xmlStage_appConst_element] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_xmlStage_appConst_element_header] FOREIGN KEY ([HeaderID]) REFERENCES [xmlStage].[header] ([ID])
);


GO

  CREATE NONCLUSTERED INDEX [IX_xmlStage_appConst_element_HeaderID]
    ON [xmlStage].[appConst_element]([HeaderID] ASC)
    ON [HWTIndexes];


GO

  CREATE NONCLUSTERED INDEX [IX_xmlStage_appConst_element_Name]
    ON [xmlStage].[appConst_element]([Name] ASC, [Type] ASC, [Units] ASC)
    ON [HWTIndexes];


