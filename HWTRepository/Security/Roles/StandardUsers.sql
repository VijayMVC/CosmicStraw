CREATE ROLE [StandardUsers]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [StandardUsers] ADD MEMBER [ElevatedUsers];

