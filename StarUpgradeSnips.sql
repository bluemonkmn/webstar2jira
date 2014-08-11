-- Work on a copy of WebStar data because triggers in the STAR database
-- interfere with our queries below.
if not exists (select 1 from sys.databases where name = 'StarMap')
   create database StarMap collate SQL_Latin1_General_CP1_CI_AS
go

select *
into StarMap..resolution
from resolution

select *
into StarMap..FileChanges
from FileChanges

use StarMap
go

-- BEGIN RENUMBER FILECHANGES.FCINDEX TO ELIMINATE DUPLICATES
-- Add temporary columns to help in the process of eliminating duplicate FCIndex entries in FileChanges
alter table resolution add maxFCIndex smallint null
alter table FileChanges add id int identity (1,1) not null
go

-- Store the maximum FCIndex value assigned to each transmittal
update r set maxFCIndex = fcMax.maxIndex
from resolution r
join (
select fc.TransmittalID, isnull(MAX(fc.FCIndex), 0) maxIndex
from FileChanges fc
group by fc.TransmittalID) fcMax on fcMax.TransmittalID = r.TransmittalId

-- Update all duplicate FCIndex values to start numbering after the max FCIndex of that transmittal
update fcUpdate set FCIndex = r.maxFCIndex + tranOffset.offset
from resolution r
join FileChanges fcUpdate on r.TransmittalId = fcUpdate.TransmittalID
join (
select fcTransmittal.id, ROW_NUMBER() over (partition by fcTransmittal.TransmittalID order by fcTransmittal.id) offset
from FileChanges fcTransmittal
join (
select fcOffset.id
, ROW_NUMBER() over (partition by fcOffset.TransmittalID, fcOffset.FCIndex order by fcOffset.id) dupIndex
from FileChanges fcOffset
join (
select TransmittalID, FCIndex
from FileChanges fc
group by fc.TransmittalID, fc.FCIndex
having COUNT(*) > 1) fcDup on fcDup.TransmittalID = fcOffset.TransmittalID and isnull(fcDup.FCIndex, -1) = isnull(fcOffset.FCIndex, -1)
) fcDupIndex on fcDupIndex.id = fcTransmittal.id
where dupIndex > 1
) tranOffset on tranOffset.id = fcUpdate.id

-- Change remaining NULL FCIndex values to 0 (initial test indicates this leaves no duplicate 0s)
update FileChanges set FCIndex = 0 where FCIndex is null

-- Remove the temporary columns ussed in re-indexing FCIndex
alter table resolution drop column maxFCIndex
alter table FileChanges drop column id
go
-- END RENUMBER FILECHANGES.FCINDEX TO ELIMINATE DUPLICATES

-- Propagate deleted files from deleted parent projects
update child set Deleted = 1
from FilePath parent
join FilePath child on parent.IsProject = 1 and parent.Deleted = 1
and left(child.Path, LEN(parent.Path)+1) = parent.Path + '/' and child.Deleted = 0

-- Verify propagation is done (this should return 0 rows when done)
select parent.Path, parent.Deleted, child.Path, child.Deleted
from FilePath parent
join FilePath child on parent.IsProject = 1 and parent.Deleted = 1
and left(child.Path, LEN(parent.Path)+1) = parent.Path + '/' and child.Deleted = 0

if OBJECT_ID('TransmittalFileRev') is not null drop table TransmittalFileRev
if exists (select 1 from sys.columns where object_id = object_id('FileRev') and name='PromoteSeq')
   alter table FileRev drop column PromoteSeq
if exists (select 1 from sys.columns where object_id = object_id('FileChanges') and name='NormalPath')
   alter table FileChanges drop column NormalPath

-- Add a column to group SourceSafe check-ins into AccuRev Promote transactions containing multiple files each
alter table FileRev add PromoteSeq int null
-- Add a temporary column to optimize appriximate matching
alter table FileChanges add NormalPath varchar(100) null
go

-- Create a normalized path for approximate path matching
update FileChanges set NormalPath = REPLACE(ltrim(rtrim(replace(FileChanged, char(9), ''))), '\', '/')
update fc set NormalPath =
CASE WHEN CHARINDEX('R75/', NormalPath) BETWEEN 1 AND 3
THEN '$/R75/' + SUBSTRING(NormalPath, CHARINDEX('R75/', NormalPath) + 4, 99)
WHEN CHARINDEX('SRC/', NormalPath) BETWEEN 1 AND 7
THEN '$/R' + SUBSTRING(REPLACE(x.ReleaseLev, '.', ''), 1, 2) + '/' + SUBSTRING(NormalPath, CHARINDEX('SRC/', NormalPath), 99)
ELSE NormalPath END
FROM FileChanges fc
JOIN resolution x ON fc.TransmittalID = x.TransmittalId

-- Create TransmittalFileRev table with matches between FileChanges.FileChanged and FilePath.Path
select c.TransmittalID, c.FCIndex, r.FileRevKey
into TransmittalFileRev
from FileChanges c
join resolution x on c.TransmittalID = x.TransmittalId
join FilePath p
on c.NormalPath = p.[Path]
and p.Deleted = 0
join FileRev r on r.FilePathKey = p.FilePathKey and ISNUMERIC(c.RevisionLevelTo)=1 and ISNUMERIC(c.RevisionLevelFrom)=1 and r.Revision <= cast(c.RevisionLevelTo as money) and r.Revision > cast(c.RevisionLevelFrom as money)
where x.ReleaseLev in ('7.50', 'BI')
go

-- Apply matching based on a truncated path
insert into TransmittalFileRev(TransmittalID, FCIndex, FileRevKey)
select c.TransmittalID, c.FCIndex, r.FileRevKey
from FileChanges c
join resolution x on c.TransmittalID = x.TransmittalId
join FilePath p
on right(c.FileChanged, 70) = right(p.[Path], 70)
and p.Deleted = 0
join FileRev r on r.FilePathKey = p.FilePathKey and ISNUMERIC(c.RevisionLevelTo)=1 and ISNUMERIC(c.RevisionLevelFrom)=1 and r.Revision <= cast(c.RevisionLevelTo as money) and r.Revision > cast(c.RevisionLevelFrom as money)
left join TransmittalFileRev old on old.TransmittalID = c.TransmittalID and old.FCIndex = c.FCIndex and old.FileRevKey = r.FileRevKey
where x.ReleaseLev in ('7.50', 'BI') and LEN(p.[Path]) > 70
and old.FileRevKey is null

-- Remove the temporary column for optimizing approximate path matching
alter table FileChanges drop column NormalPath
go

-- BEGIN GROUPING INTO CHANGESETS
declare @PromoteCounter int
set @PromoteCounter = 1
declare @prevUsr nvarchar(64)
declare @prevComment nvarchar(max)
declare @curUsr nvarchar(64)
declare @curComment nvarchar(max)
declare @fileRevKey int

-- As an optimization, insert the grouping data into a table variable rather
-- than trying to update individual rows as each row is processed.
declare @PromoteFileRev table(PromoteSeq int not null, FileRevKey int not null)

declare ChangesetCursor cursor for
select [User], Comment, r.FileRevKey
from FileRev r
join FilePath p on r.FilePathKey = p.FilePathKey and p.Deleted = 0
order by r.CommitTime, r.[User], r.FilePathKey

open ChangesetCursor
fetch next from ChangesetCursor into @curUsr, @curComment, @fileRevKey

set nocount on

-- For each check-in, group it into the same changeset (Promote) if
-- the user and comment are the same as the previous check-in.
while @@FETCH_STATUS = 0
begin
   if @prevUsr is not null and (@prevUsr <> @curUsr or
      isnull(replace(replace(@prevComment, CHAR(13) + CHAR(10), ''), ' ', ''), '') <> 
      isnull(replace(replace(@curComment, CHAR(13) + CHAR(10), ''), ' ', ''), ''))
   begin
      set @PromoteCounter = @PromoteCounter + 1
      print 'Promote Sequence ' + cast(@PromoteCounter as nvarchar(10))
   end
   
   insert into @PromoteFileRev(PromoteSeq, FileRevKey) values(@PromoteCounter, @fileRevKey)
   set @prevUsr = @curUsr
   set @prevComment = @curComment
   fetch next from ChangesetCursor into @curUsr, @curComment, @fileRevKey
end
close ChangesetCursor
deallocate ChangesetCursor

set nocount off

-- Move all the grouping data into a column in the FileRev table.
update r set PromoteSeq = pr.PromoteSeq
from FileRev r
join @PromoteFileRev pr on r.FileRevKey = pr.FileRevKey

-- Apply a "-1" group to all deleted files so PromoteSeq can be non-nullable
update r set PromoteSeq = -1
from FileRev r
join FilePath p on r.FilePathKey = p.FilePathKey
where p.Deleted = 1

-- Make Promote sequence grouping column non-nullable
alter table FileRev alter column PromoteSeq int not null
go
-- END GROUPING INTO CHANGESETS

-- Check if there are any matches where FileChanges.FileChanged does not match FilePath.Path
-- This could occur when duplicate entries existed in the FileChanges table
-- (same TransmittalId & FCIndex, but different FileChanged value)
-- This *should* only return the approximate matches.
select c.FileChanged, p.[Path], *
from TransmittalFileRev xr
join FileChanges c on xr.TransmittalId = c.TransmittalID and c.FCIndex = xr.FCIndex
join FileRev r on r.FileRevKey = xr.FileRevKey
join FilePath p on p.FilePathKey = r.FilePathKey
where p.[Path] <> c.FileChanged

-- Check if there are any duplicate rows in the link table.
-- This should return nothing.
select TransmittalID, FCIndex, FileRevKey, COUNT(*)
from TransmittalFileRev
group by TransmittalID, FCIndex, FileRevKey
having COUNT(*) > 1

-- Output source control history with groupings
select r.PromoteSeq, p.[Path], r.Revision, r.[User], r.CommitTime, r.Comment, r.Action, r.Label
from FileRev r
join FilePath p on r.FilePathKey = p.FilePathKey
where p.Deleted = 0
order by r.PromoteSeq

-- Output linkage between promote transactions and transmittals/resolutions
select r.PromoteSeq, p.Path, r.Revision, r.[User], r.CommitTime, r.Action, left(r.Comment, 40) [Comment first 40], xr.TransmittalId, c.RevisionLevelFrom, substring(x.ReadMe, 1, 40) [Readme first 40]
from FileRev r
join FilePath p on r.FilePathKey = p.FilePathKey
left join TransmittalFileRev xr
left join FileChanges c
join resolution x on x.TransmittalId = c.TransmittalID
on c.TransmittalID = xr.TransmittalId and c.FCIndex = xr.FCIndex
on xr.FileRevKey = r.FileRevKey
where p.Deleted = 0
order by c.TransmittalID, PromoteSeq