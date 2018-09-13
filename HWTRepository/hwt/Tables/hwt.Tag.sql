  CREATE TABLE [hwt].[Tag] (
    [TagID]       INT            IDENTITY (1, 1) NOT NULL,
    [TagTypeID]   INT            NOT NULL,
    [Name]        NVARCHAR (50)  NOT NULL,
    [Description] NVARCHAR (200) NOT NULL,
    [IsDeleted]   TINYINT        NOT NULL,
    [UpdatedBy]   [sysname]      NOT NULL,
    [UpdatedDate] DATETIME2 (3)  NOT NULL,
    CONSTRAINT [PK_hwt_Tag] PRIMARY KEY CLUSTERED ([TagID] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [FK_hwt_Tag_TagType] FOREIGN KEY ([TagTypeID]) REFERENCES [hwt].[TagType] ([TagTypeID]),
    CONSTRAINT [UK_hwt_Tag_Name] UNIQUE NONCLUSTERED ([TagTypeID] ASC, [Name] ASC)
);


GO

  CREATE	UNIQUE INDEX UX_hwt_Tag_Name
				ON hwt.Tag
					( TagTypeID ASC, Name ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
