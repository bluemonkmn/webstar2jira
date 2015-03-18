IF OBJECT_ID('StarMap..ReleaseIssues') IS NOT NULL
   DROP TABLE StarMap..ReleaseIssues

-- Create a table to store all the info about which SDRs and
-- transmittals will be migrated and how they aredivided up
-- by release (to generate smaller import units).
CREATE TABLE StarMap..ReleaseIssues(
    SDRNum int NULL
   ,TransmittalId int NULL
   ,ImportGroup varchar(10) NOT NULL
   ,Branch varchar(15) NOT NULL
   ,[Version] varchar(15) NOT NULL
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
   Name varchar(15) NOT NULL,
   Sequence int NOT NULL
)

INSERT INTO @ReleaseList(Name, Sequence) VALUES('VisiBar 5.5B', 1)
INSERT INTO @ReleaseList(Name, Sequence) VALUES('VisiBar 5.5C', 2)
INSERT INTO @ReleaseList(Name, Sequence) VALUES('VisiBar 5.5D', 3)
INSERT INTO @ReleaseList(Name, Sequence) VALUES('VisiBar 5.5E', 4)

   -- Add all transmittals in this release not already included
   INSERT INTO StarMap..ReleaseIssues(TransmittalId, ImportGroup, Branch, [Version])
   SELECT r.TransmittalId, r.ReleaseLev, rd.JIRABranch,
   CASE WHEN r.WaitingOn IN ('Pull', 'Done')
        THEN rd.FixedVersion
        ELSE rd.JIRABranch END
   FROM STAR..resolution r
   JOIN StarMap..ReleaseIDs rd on rd.ReleaseLev = r.ReleaseLev and rd.ReleaseID = r.RlsLevelTarget
   LEFT JOIN StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
   WHERE r.RlsLevelTarget IN (SELECT Name FROM @ReleaseList) AND ri.ImportGroup IS NULL

   -- Add all SDRs in the this release that are not linked to any included
   -- transmittal (for any included release) nor already included.
   INSERT INTO StarMap..ReleaseIssues(SDRNum, ImportGroup, Branch, [Version])
   SELECT s.SDRNum, s.Release, rd.JIRABranch, rd.AffectsVersion
   FROM STAR..sdr s
   LEFT JOIN (
      SELECT rs.SDR_Num, COUNT(*) TransmittalCount
      FROM STAR..Resolution_SDRs rs
      JOIN STAR..resolution r ON r.TransmittalId = rs.TransmittalID
      AND r.RlsLevelTarget IN (SELECT Name FROM @ReleaseList)
      GROUP BY rs.SDR_Num) tc ON s.SDRNum = tc.SDR_Num
   JOIN StarMap..ReleaseIDs rd on rd.ReleaseLev = s.Release and rd.ReleaseID = s.[Version]
   LEFT JOIN StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
   WHERE ISNULL(tc.TransmittalCount, 0) = 0 AND s.Release IN (SELECT Name FROM @ReleaseList)
   AND ri.ImportGroup IS NULL
   AND s.Version IN (SELECT Name FROM @ReleaseList)

   -- Recursively propagate references to all related Transmittals in
   -- included releases and all related SDRs in all releases.
   DECLARE @affected int

   set @affected = -1

   WHILE @affected <> 0
   BEGIN
      INSERT INTO StarMap..ReleaseIssues(SDRNum, ImportGroup, Branch, [Version])
      SELECT s.SDRNum, 'VisiBar',
      CASE WHEN s.Version IN (SELECT Name FROM @ReleaseList) AND s.Version != 'FSEVENT' THEN rd.JIRABranch ELSE MAX (ri.Branch) END,
      CASE WHEN s.Release = 'VisiBar' THEN rd.AffectsVersion ELSE MAX(ri.[Version]) END
      FROM StarMap..ReleaseIssues ri
      JOIN STAR..Resolution_SDRs rs ON ri.TransmittalId = rs.TransmittalID
      JOIN STAR..sdr s on s.SDRNum = rs.SDR_Num
      JOIN StarMap..ReleaseIDs rd on rd.ReleaseLev = s.Release and rd.ReleaseID = s.[Version]
      LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.SDRNum = s.SDRNum
      WHERE riDup.ImportGroup IS NULL
      GROUP BY s.SDRNum, rd.JIRABranch, rd.AffectsVersion, s.Release, s.Version

      SET @affected = @@ROWCOUNT

      INSERT INTO StarMap..ReleaseIssues(TransmittalId, ImportGroup, Branch, [Version])
      SELECT r.TransmittalId, 'VisiBar', rd.JIRABranch,
      CASE WHEN r.WaitingOn IN ('Pull', 'Done') THEN rd.FixedVersion ELSE rd.JIRABranch END
      FROM StarMap..ReleaseIssues ri
      JOIN STAR..Resolution_SDRs rs ON ri.SDRNum = rs.SDR_Num
      JOIN STAR..resolution r ON rs.TransmittalID = r.TransmittalId
      AND r.ReleaseLev = 'VisiBar' AND RIGHT(r.RlsLevelTarget,3) != '_HF'
      JOIN StarMap..ReleaseIDs rd on rd.ReleaseLev = r.ReleaseLev and rd.ReleaseID = r.RlsLevelTarget
      LEFT JOIN StarMap..ReleaseIssues riDup ON riDup.TransmittalId = r.TransmittalId
      WHERE riDup.ImportGroup IS NULL
      GROUP BY r.TransmittalId, r.WaitingOn, rd.JIRABranch, rd.FixedVersion

      SET @affected = @affected + @@ROWCOUNT
   END
