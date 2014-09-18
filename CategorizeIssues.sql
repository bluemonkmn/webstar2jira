IF OBJECT_ID('StarMap..ReleaseIssues') IS NOT NULL
   DROP TABLE StarMap..ReleaseIssues

-- Create a table to store all the info about which SDRs and
-- transmittals will be migrated and how they aredivided up
-- by release (to generate smaller import units).
CREATE TABLE StarMap..ReleaseIssues(
    SDRNum int NULL
   ,TransmittalId int NULL
   ,Release varchar(10) NOT NULL
)
CREATE UNIQUE NONCLUSTERED INDEX IX_SDRNum
ON StarMap..ReleaseIssues (SDRNum)
WHERE SDRNum IS NOT NULL
CREATE UNIQUE NONCLUSTERED INDEX IX_TransmittalId
ON StarMap..ReleaseIssues (TransmittalId)
WHERE TransmittalId IS NOT NULL
GO
-- Create a list containing all the releases we are interested in migrating
DECLARE @ReleaseList TABLE (
   Name varchar(10)
)
INSERT INTO @ReleaseList(Name) VALUES('7.30')
INSERT INTO @ReleaseList(Name) VALUES('7.40')
INSERT INTO @ReleaseList(Name) VALUES('7.50')
INSERT INTO @ReleaseList(Name) VALUES('8.0')
INSERT INTO @ReleaseList(Name) VALUES('BI')
INSERT INTO @ReleaseList(Name) VALUES('FSE')

-- Start with a list of all transmittals in the 7.30 release
INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
SELECT TransmittalId, '7.30'
FROM STAR..resolution
WHERE ReleaseLev = '7.30'

-- Add all SDRs in the 7.30 release that are not linked to any
-- included transmittal (for any included release).
INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
SELECT SDRNum, '7.30'
FROM STAR..sdr s
LEFT JOIN (
   SELECT rs.SDR_Num, COUNT(*) TransmittalCount
   FROM STAR..Resolution_SDRs rs
   JOIN STAR..resolution r ON r.TransmittalId = rs.TransmittalID
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   GROUP BY rs.SDR_Num) tc ON s.SDRNum = tc.SDR_Num
WHERE ISNULL(tc.TransmittalCount, 0) = 0 AND s.Release = '7.30'

-- Recursively propagate references to all related Transmittals in
-- included releases and all related SDRs in all releases.
DECLARE @affected int

set @affected = -1

WHILE @affected <> 0
BEGIN
   INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
   SELECT DISTINCT s.SDRNum, '7.30'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
   JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
   WHERE riDup.Release IS NULL

   SET @affected = @@ROWCOUNT

   INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
   SELECT DISTINCT r.TransmittalId, '7.30'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
   JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
   WHERE riDup.Release IS NULL

   SET @affected = @affected + @@ROWCOUNT
END

-- Add all transmittals in the 7.40 release not already included
INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
SELECT r.TransmittalId, '7.40'
FROM STAR..resolution r
LEFT JOIN StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
WHERE ReleaseLev = '7.40' AND ri.Release IS NULL

-- Add all SDRs in the 7.40 release that are not linked to any included
-- transmittal (for any included release) nor already included.
INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
SELECT s.SDRNum, '7.40'
FROM STAR..sdr s
LEFT JOIN (
   SELECT rs.SDR_Num, COUNT(*) TransmittalCount
   FROM STAR..Resolution_SDRs rs
   JOIN STAR..resolution r ON r.TransmittalId = rs.TransmittalID
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   GROUP BY rs.SDR_Num) tc ON s.SDRNum = tc.SDR_Num
LEFT JOIN StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
WHERE ISNULL(tc.TransmittalCount, 0) = 0 AND s.Release = '7.40' AND ri.Release IS NULL

-- Recursively propagate references to all related Transmittals in
-- included releases and all related SDRs in all releases.
set @affected = -1
WHILE @affected <> 0
BEGIN
   INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
   SELECT DISTINCT s.SDRNum, '7.40'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
   JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
   WHERE riDup.Release IS NULL

   SET @affected = @@ROWCOUNT

   INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
   SELECT DISTINCT r.TransmittalId, '7.40'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
   JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
   WHERE riDup.Release IS NULL

   SET @affected = @affected + @@ROWCOUNT
END

-- Add all transmittals in the 7.50 release
INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
SELECT r.TransmittalId, '7.50'
FROM STAR..resolution r
LEFT JOIN StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
WHERE ReleaseLev = '7.50' AND ri.Release IS NULL

-- Add all SDRs in the 7.50 release that are not linked to any
-- included transmittal (for any included release).
INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
SELECT s.SDRNum, '7.50'
FROM STAR..sdr s
LEFT JOIN (
   SELECT rs.SDR_Num, COUNT(*) TransmittalCount
   FROM STAR..Resolution_SDRs rs
   JOIN STAR..resolution r ON r.TransmittalId = rs.TransmittalID
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   GROUP BY rs.SDR_Num) tc ON s.SDRNum = tc.SDR_Num
LEFT JOIN StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
WHERE ISNULL(tc.TransmittalCount, 0) = 0 AND s.Release = '7.50' AND ri.Release IS NULL

-- Recursively propagate references to all related Transmittals in
-- included releases and all related SDRs in all releases.
set @affected = -1
WHILE @affected <> 0
BEGIN
   INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
   SELECT DISTINCT s.SDRNum, '7.50'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
   JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
   WHERE riDup.Release IS NULL

   SET @affected = @@ROWCOUNT

   INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
   SELECT DISTINCT r.TransmittalId, '7.50'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
   JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
   WHERE riDup.Release IS NULL

   SET @affected = @affected + @@ROWCOUNT
END

-- Add all transmittals in the 8.0 release
INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
SELECT r.TransmittalId, '8.0'
FROM STAR..resolution r
LEFT JOIN StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
WHERE ReleaseLev = '8.0' AND ri.Release IS NULL

-- Add all SDRs in the 8.0 release that are not linked to any
-- included transmittal (for any included release).
INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
SELECT s.SDRNum, '8.0'
FROM STAR..sdr s
LEFT JOIN (
   SELECT rs.SDR_Num, COUNT(*) TransmittalCount
   FROM STAR..Resolution_SDRs rs
   JOIN STAR..resolution r ON r.TransmittalId = rs.TransmittalID
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   GROUP BY rs.SDR_Num) tc ON s.SDRNum = tc.SDR_Num
LEFT JOIN StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
WHERE ISNULL(tc.TransmittalCount, 0) = 0 AND s.Release = '8.0' AND ri.Release IS NULL

-- Recursively propagate references to all related Transmittals in
-- included releases and all related SDRs in all releases.
set @affected = -1
WHILE @affected <> 0
BEGIN
   INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
   SELECT DISTINCT s.SDRNum, '8.0'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
   JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
   WHERE riDup.Release IS NULL

   SET @affected = @@ROWCOUNT

   INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
   SELECT DISTINCT r.TransmittalId, '8.0'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
   JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
   WHERE riDup.Release IS NULL

   SET @affected = @affected + @@ROWCOUNT
END

-- Add all transmittals in the BI release
INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
SELECT r.TransmittalId, 'BI'
FROM STAR..resolution r
LEFT JOIN StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
WHERE ReleaseLev = 'BI' AND ri.Release IS NULL

-- Add all SDRs in the BI release that are not linked to any
-- included transmittal (for any included release).
INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
SELECT s.SDRNum, 'BI'
FROM STAR..sdr s
LEFT JOIN (
   SELECT rs.SDR_Num, COUNT(*) TransmittalCount
   FROM STAR..Resolution_SDRs rs
   JOIN STAR..resolution r ON r.TransmittalId = rs.TransmittalID
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   GROUP BY rs.SDR_Num) tc ON s.SDRNum = tc.SDR_Num
LEFT JOIN StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
WHERE ISNULL(tc.TransmittalCount, 0) = 0 AND s.Release = 'BI' AND ri.Release IS NULL

-- Recursively propagate references to all related Transmittals in
-- included releases and all related SDRs in all releases.
set @affected = -1
WHILE @affected <> 0
BEGIN
   INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
   SELECT DISTINCT s.SDRNum, 'BI'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
   JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
   WHERE riDup.Release IS NULL

   SET @affected = @@ROWCOUNT

   INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
   SELECT DISTINCT r.TransmittalId, 'BI'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
   JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
   WHERE riDup.Release IS NULL

   SET @affected = @affected + @@ROWCOUNT
END

-- Add transmittals from the FSE release that match our version criteria
INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
SELECT r.TransmittalId, 'FSE'
FROM STAR..resolution r
LEFT JOIN StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
WHERE ReleaseLev = 'FSE'
AND(RlsLevelTarget LIKE '8.50%'
 OR RlsLevelTarget LIKE '84to85%' 
 OR RlsLevelTarget LIKE 'FSE 8.50%' 
 OR RlsLevelTarget LIKE 'FSE 85%')
AND ri.Release IS NULL

-- Add all SDRs fitting the FSE criteria that are not linked to any
-- included transmittal (for any included release).
INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
SELECT s.SDRNum, 'FSE'
FROM STAR..sdr s
LEFT JOIN (
   SELECT rs.SDR_Num, COUNT(*) TransmittalCount
   FROM STAR..Resolution_SDRs rs
   JOIN STAR..resolution r ON r.TransmittalId = rs.TransmittalID
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   GROUP BY rs.SDR_Num) tc ON s.SDRNum = tc.SDR_Num
LEFT JOIN StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
WHERE ISNULL(tc.TransmittalCount, 0) = 0 AND s.Release = 'FSE'
AND(s.Version LIKE '8.50%'
 OR s.Version LIKE '84to85%'
 OR s.Version LIKE 'FSE 8.50%'
 OR s.Version LIKE 'FSE 85%')
AND ri.Release IS NULL
 

-- Recursively propagate references to all related Transmittals in
-- included releases and all related SDRs in all releases.
set @affected = -1
WHILE @affected <> 0
BEGIN
   INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
   SELECT DISTINCT s.SDRNum, 'FSE'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
   JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
   WHERE riDup.Release IS NULL

   SET @affected = @@ROWCOUNT

   INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
   SELECT DISTINCT r.TransmittalId, 'FSE'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
   JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
   WHERE riDup.Release IS NULL

   SET @affected = @affected + @@ROWCOUNT
END

-- Add all SDRs that are open in any FS release
INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
SELECT s.SDRNum, 'Open'
FROM STAR..sdr s
LEFT JOIN StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
WHERE s.Status = 'O'
AND s.Release IN ('7.00', '7.10', '7.20', '7.30', '7.40', '7.50', '8.0', 'BI', 'FSE')
AND ri.Release IS NULL

-- Recursively propagate references to all related Transmittals in
-- included releases and all related SDRs in all releases.
set @affected = -1
WHILE @affected <> 0
BEGIN
   INSERT INTO StarMap..ReleaseIssues(SDRNum, Release)
   SELECT DISTINCT s.SDRNum, 'Open'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
   JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
   WHERE riDup.Release IS NULL

   SET @affected = @@ROWCOUNT

   INSERT INTO StarMap..ReleaseIssues(TransmittalId, Release)
   SELECT DISTINCT r.TransmittalId, 'Open'
   FROM StarMap..ReleaseIssues ri
   JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
   JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
   AND r.ReleaseLev IN (SELECT Name FROM @ReleaseList)
   LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
   WHERE riDup.Release IS NULL

   SET @affected = @affected + @@ROWCOUNT
END