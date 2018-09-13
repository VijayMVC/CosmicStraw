  CREATE TABLE [hwt].[HeaderAppConst] (
    [HeaderID]      INT            NOT NULL,
    [AppConstID]    INT            NOT NULL,
    [NodeOrder]     INT            NOT NULL,
    [AppConstValue] NVARCHAR (MAX) NOT NULL,
    [UpdatedBy]     [sysname]      NOT NULL,
    [UpdatedDate]   DATETIME2 (3)  NOT NULL,
    CONSTRAINT [PK_hwt_HeaderAppConst] PRIMARY KEY CLUSTERED ([HeaderID] ASC, [AppConstID] ASC, [NodeOrder] ASC),
    CONSTRAINT [FK_hwt_HeaderAppConst_AppConst] FOREIGN KEY ([AppConstID]) REFERENCES [hwt].[AppConst] ([AppConstID]),
    CONSTRAINT [FK_hwt_HeaderAppConst_Header] FOREIGN KEY ([HeaderID]) REFERENCES [hwt].[Header] ([HeaderID])
);


