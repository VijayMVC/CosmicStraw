CREATE VIEW
    [hwt].[vw_SearchResults]
AS
SELECT
    TestNumber      =   h.HeaderID
  , Project         =   p.Name
  , TestName        =   h.TestName
  , TestMode        =   m.Name
  , Operator        =   o.Name
  , StartTime       =   CONVERT( varchar(10), h.StartTime, 120 )
  , EndTime         =   CONVERT( varchar(10), h.FinishTime, 120 )
  , TestDuration    =   h.Duration
  , TestStationID   =   h.TestStationName
  , FWRevision      =   f.Name
  , HWIncrement     =   hw.Name
FROM
    hwt.Header AS h

OUTER APPLY(
    SELECT  Name
    FROM    hwt.Tag AS t
    INNER JOIN
            hwt.HeaderTag AS ht ON ht.TagID = t.TagID
    WHERE   ht.HeaderID = h.HeaderID AND t.TagTypeID = 2 ) AS p

OUTER APPLY(
    SELECT  Name
    FROM    hwt.Tag AS t
    INNER JOIN
            hwt.HeaderTag AS ht ON ht.TagID = t.TagID
    WHERE   ht.HeaderID = h.HeaderID AND t.TagTypeID = 1 ) AS m

OUTER APPLY(
    SELECT  Name
    FROM    hwt.Tag AS t
    INNER JOIN
            hwt.HeaderTag AS ht ON ht.TagID = t.TagID
    WHERE   ht.HeaderID = h.HeaderID AND t.TagTypeID = 6 ) AS f

OUTER APPLY(
    SELECT  Name
    FROM    hwt.Tag AS t
    INNER JOIN
            hwt.HeaderTag AS ht ON ht.TagID = t.TagID
    WHERE   ht.HeaderID = h.HeaderID AND t.TagTypeID = 7 ) AS hw

OUTER APPLY(
    SELECT  Name
    FROM    hwt.Tag AS t
    INNER JOIN
            hwt.HeaderTag AS ht ON ht.TagID = t.TagID
    WHERE   ht.HeaderID = h.HeaderID AND t.TagTypeID = 10 ) AS o

;
GO

