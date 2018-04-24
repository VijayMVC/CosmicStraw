CREATE ROLE [ElevatedUsers]
    AUTHORIZATION [dbo];




GO
ALTER ROLE [ElevatedUsers] ADD MEMBER [ENT\svc-crmhwtlab];


GO
ALTER ROLE [ElevatedUsers] ADD MEMBER [HWTValidator];

