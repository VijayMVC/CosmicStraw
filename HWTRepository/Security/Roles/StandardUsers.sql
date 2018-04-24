CREATE ROLE [StandardUsers]
    AUTHORIZATION [dbo];




GO
ALTER ROLE [StandardUsers] ADD MEMBER [ElevatedUsers];
GO

ALTER ROLE [StandardUsers] ADD MEMBER [ENT\svc-crmhwtlab];
GO

ALTER ROLE [StandardUsers] ADD MEMBER [HWTValidator];

