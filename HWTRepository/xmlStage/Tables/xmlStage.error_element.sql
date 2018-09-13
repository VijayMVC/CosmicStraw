  CREATE TABLE [xmlStage].[error_element] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [VectorID]    INT            NOT NULL,
    [ErrorType]   INT            DEFAULT ((1)) NOT NULL,
    [ErrorCode]   INT            NOT NULL,
    [ErrorText]   NVARCHAR (MAX) NOT NULL,
    [NodeOrder]   INT            DEFAULT ((0)) NOT NULL,
    [CreatedDate] DATETIME2 (3)  DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_xmlStage_error_element] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [CK_xmlStage_VectorError_ErrorType] CHECK ([ErrorType]=(3) OR [ErrorType]=(2) OR [ErrorType]=(1)),
    CONSTRAINT [FK_xmlStage_error_element_vector] FOREIGN KEY ([VectorID]) REFERENCES [xmlStage].[vector] ([ID])
);


