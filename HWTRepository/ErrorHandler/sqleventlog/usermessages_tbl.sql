-- This table holds the text for messages that are directed to users,
-- and you can store texts in different langauges. You should always
-- have text for the message in the main language for your system.
CREATE TABLE slog.usermessages (
   msgid    varchar(36)    NOT NULL, -- This is the same msgid as in sqleventlog.
   lcid     smallint       NOT NULL, -- Language, 1033 for US English etc.
   msgtext  nvarchar(1960) NOT NULL, -- Text for the message.
   CONSTRAINT pk_usermessages PRIMARY KEY (msgid, lcid)
)
go
-- Some test messsages.
SET NOCOUNT ON
INSERT slog.usermessages (msgid, lcid, msgtext)
   VALUES ('RightHand', 1033, N'This is my right hand')
INSERT slog.usermessages (msgid, lcid, msgtext)
   VALUES ('RightHand', 1040, N'Questo è la mia mano destra')
INSERT slog.usermessages (msgid, lcid, msgtext)
   VALUES ('RightHand', 1036, N'Ceci est ma main droite')
INSERT slog.usermessages (msgid, lcid, msgtext)
   VALUES ('RightHand', 1031, N'Dieses ist meine rechte Hand')
INSERT slog.usermessages (msgid, lcid, msgtext)
   VALUES ('RightHand', 1045, N'To jest moja ręka prawa')

-- This is a parameterised message.
INSERT slog.usermessages (msgid, lcid, msgtext)
   VALUES('NoCust', 1033, N'Customer "%1" not found.')
INSERT slog.usermessages (msgid, lcid, msgtext)
   VALUES('NoCust', 1040, N'Cliente "%1" non c''è.')
go