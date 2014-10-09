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

update ReleaseIDs set AffectsVersion = ReleaseID

update ReleaseIDs set LanguageLabel = 'Spanish'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_Spanish'

update ReleaseIDs set LanguageLabel = 'Chinese'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_Chinese'

update ReleaseIDs set LanguageLabel = 'Dutch'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 6) = '_Dutch'

update ReleaseIDs set LanguageLabel = 'French'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_French'

update ReleaseIDs set LanguageLabel = 'German'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_German'

update ReleaseIDs set LanguageLabel = 'Italian'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_Italian'

update ReleaseIDs set LanguageLabel = 'Japanese'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 6) = '_Japan' or RIGHT(ReleaseID, 9) = '_Japanese'

update ReleaseIDs set LanguageLabel = 'JapaneseEnglish'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 3) = '_JE'

update ReleaseIDs set LanguageLabel = 'MainlandEnglish'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 3) = '_ME'

update ReleaseIDs set LanguageLabel = 'Portuguese'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_Portug'

update ReleaseIDs set LanguageLabel = 'Taiwanese'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_Taiwan' or RIGHT(ReleaseID, 10) = '_Taiwanese'

update ReleaseIDs set LanguageLabel = 'TaiwaneseEnglish'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 3) = '_TE'

update ReleaseIDs set HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) in ('_HotFix', '_Hotfix')

update ReleaseIDs set LanguageLabel = 'Chinese', HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 10) = '_ChineseHF'

update ReleaseIDs set LanguageLabel = 'French', HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 9) = '_FrenchHF'

update ReleaseIDs set LanguageLabel = 'German', HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 9) = '_GermanHF'

update ReleaseIDs set LanguageLabel = 'Japanese', HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_JapanHF'

update ReleaseIDs set LanguageLabel = 'Spanish', HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 10) = '_SpanishHF'

update ReleaseIDs set LanguageLabel = 'Taiwanese', HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 9) = '_TaiwanHF'

update ReleaseIDs set LanguageLabel = 'MainlandEnglish', HotfixLabel = 'HotFix'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 5) = '_MEHF'

update ReleaseIDs set HotfixLabel = 'Utility'
, AffectsVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_Utility'

update ReleaseIDs set IsReleased = 0 where ReleaseID in ('LEDO 5.10','INAP 7.50.4','Visibar 5.5D','8.0')

update ReleaseIDs set AffectsVersion = '8.00' where ReleaseID = '8.0'
update ReleaseIDs set FixedVersion = AffectsVersion

update ReleaseIDs set JIRABranch = REPLACE(REPLACE(ISNULL(AffectsVersion, ReleaseID), '.', '_'), ' ', '_')
update ReleaseIDs set JIRABranch = '7_30_DEV', FixedVersion = '7_30_DEV', AffectsVersion = '7_30_DEV', IsReleased = 0 where AffectsVersion = '7.30M'
update ReleaseIDs set JIRABranch = '7_40_DEV', FixedVersion = '7_40_DEV', AffectsVersion = '7_40_DEV', IsReleased = 0 where AffectsVersion = '7.40L'
update ReleaseIDs set JIRABranch = '7_50_DEV', FixedVersion = '7_50_DEV', AffectsVersion = '7_50_DEV', IsReleased = 0 where AffectsVersion = '7.50F'
update ReleaseIDs set JIRABranch = '8_00_DEV', FixedVersion = '8_00_DEV', AffectsVersion = '8_00_DEV', IsReleased = 0 where AffectsVersion = '8.00'
update ReleaseIDs set JIRABranch = '7_50', HotfixLabel='BI1' where AffectsVersion = 'BI 1' and HotfixLabel is null
update ReleaseIDs set JIRABranch = '7_50', LanguageLabel='BI1' where AffectsVersion = 'BI 1' and LanguageLabel is null and HotfixLabel != 'BI1'
update ReleaseIDs set JIRABranch = '7_50C', HotfixLabel='BI2' where AffectsVersion = 'BI 2'
update ReleaseIDs set JIRABranch = '7_50_DEV', HotfixLabel='BI3', IsReleased = 0 where AffectsVersion = 'BI 3'
update ReleaseIDs set JIRABranch = '7_30', HotfixLabel='BRM50' where AffectsVersion = 'BRM 5.0'
update ReleaseIDs set JIRABranch = '7_40', HotfixLabel='BRM57' where AffectsVersion = 'BRM 5.7'
update ReleaseIDs set JIRABranch = '7_00' where ReleaseLev = '7.00'
update ReleaseIDs set JIRABranch = '7_10' where ReleaseLev = '7.10'
update ReleaseIDs set JIRABranch = '7_20' where ReleaseLev = '7.20'
update ReleaseIDs set JIRABranch = '7_30', HotfixLabel='NotaFiscal' where ReleaseID = '7.3NF'
update ReleaseIDs set JIRABranch = '7_30_DEV' where AffectsVersion like '7.30%' and coalesce(HotfixLabel, LanguageLabel) is null
update ReleaseIDs set JIRABranch = '7_40_DEV' where AffectsVersion like '7.40%' and coalesce(HotfixLabel, LanguageLabel) is null
update ReleaseIDs set JIRABranch = '7_50_DEV' where AffectsVersion like '7.50%' and coalesce(HotfixLabel, LanguageLabel) is null
update ReleaseIDs set FixedVersion = JIRABranch where coalesce(HotfixLabel, LanguageLabel) is not null
