  CREATE TABLE [hwt].[VectorError] (
    [VectorErrorID]       INT            NOT NULL,
    [VectorID]            INT            NOT NULL,
    [ErrorType]           INT            NOT NULL,
    [ErrorCode]           INT            NOT NULL,
    [ErrorText]           NVARCHAR (MAX) NOT NULL,
    [ErrorSequenceNumber] INT            NOT NULL,
    [UpdatedBy]           [sysname]      NOT NULL,
    [UpdatedDate]         DATETIME2 (3)  NOT NULL,
    CONSTRAINT [PK_hwt_VectorError] PRIMARY KEY CLUSTERED ([VectorErrorID] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [CK_hwt_VectorError_ErrorType] CHECK ([ErrorType]=(3) OR [ErrorType]=(2) OR [ErrorType]=(1)),
    CONSTRAINT [FK_hwt_VectorError_Vector] FOREIGN KEY ([VectorID]) REFERENCES [hwt].[Vector] ([VectorID])
);


GO

  CREATE	INDEX IX_hwt_VectorError_VectorData
	  ON	hwt.VectorError
				( VectorID ASC )
			INCLUDE
				( ErrorCode, ErrorText )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;


