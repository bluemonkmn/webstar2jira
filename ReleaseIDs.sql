if OBJECT_ID('StarMap..ReleaseIDs') is not null
   drop table StarMap..ReleaseIDs
go

select ReleaseLev, ReleaseID
into StarMap..ReleaseIDs
from STAR..ReleaseIDs

use StarMap
go

alter table ReleaseIDs add IsReleased bit not null constraint DF_IsReleased default 1
alter table ReleaseIDs drop constraint DF_IsReleased
alter table ReleaseIDs add LanguageLabel varchar(20) null
alter table ReleaseIDs add HotfixLabel varchar(10) null
alter table ReleaseIDs add AffectsVersion varchar(15) null
alter table ReleaseIDs add FixedVersion varchar(15) null
alter table ReleaseIDs add JIRABranch varchar(15) null
go

update ReleaseIDs set AffectsVersion =
case when ReleaseLev = 'DMNDSTR' then substring(ReleaseID, 9, 10)
else SUBSTRING(ReleaseID, 11, 10) end

update ReleaseIDs set HotfixLabel = 'HotFix'
, AffectsVersion = left(AffectsVersion, len(AffectsVersion)-1)
where RIGHT(ReleaseID, 1) ='H'

update ReleaseIDs set IsReleased = 0 where ReleaseID in ('Visiwatch 2.6.3', 'DmndStr 2.1d')

update ReleaseIDs set FixedVersion = AffectsVersion

update ReleaseIDs set JIRABranch = 'VW_DEV' where ReleaseLev = 'VISI'
update ReleaseIDs set FixedVersion = 'VW_DEV', AffectsVersion = 'VW_DEV', IsReleased = 0 where AffectsVersion = '2.6.3'

update ReleaseIDs set JIRABranch = 'DS_DEV' where ReleaseLev = 'DMNDSTR' and HotfixLabel is null
update ReleaseIDs set FixedVersion = 'DS_DEV', AffectsVersion = 'DS_DEV' where ReleaseLev = 'DMNDSTR' and HotfixLabel is null and IsReleased = 0
update ReleaseIDs set JIRABranch = REPLACE(FixedVersion, '.'  , '_') where HotfixLabel is not null and IsReleased = 1
update ReleaseIDs set FixedVersion = JIRABranch where HotfixLabel is not null
