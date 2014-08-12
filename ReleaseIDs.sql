select ReleaseLev, ReleaseID
into StarMap..ReleaseIDs
from STAR..ReleaseIDs

use StarMap
go

alter table ReleaseIDs add IsReleased bit not null constraint DF_IsReleased default 1
alter table ReleaseIDs drop constraint DF_IsReleased
alter table ReleaseIDs add LanguageLabel varchar(20) null
alter table ReleaseIDs add HotfixLabel varchar(10) null
alter table ReleaseIDs add JIRAVersion varchar(15) null

update ReleaseIDs set LanguageLabel = 'Spanish'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_Spanish'

update ReleaseIDs set LanguageLabel = 'Chinese'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_Chinese'

update ReleaseIDs set LanguageLabel = 'Dutch'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 6) = '_Dutch'

update ReleaseIDs set LanguageLabel = 'French'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_French'

update ReleaseIDs set LanguageLabel = 'German'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_German'

update ReleaseIDs set LanguageLabel = 'Italian'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_Italian'

update ReleaseIDs set LanguageLabel = 'Japanese'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 6) = '_Japan' or RIGHT(ReleaseID, 9) = '_Japanese'

update ReleaseIDs set LanguageLabel = 'JE'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 3) = '_JE'

update ReleaseIDs set LanguageLabel = 'ME'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 3) = '_ME'

update ReleaseIDs set LanguageLabel = 'Portuguese'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_Portug'

update ReleaseIDs set LanguageLabel = 'Taiwanese'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) = '_Taiwan' or RIGHT(ReleaseID, 10) = '_Taiwanese'

update ReleaseIDs set LanguageLabel = 'TE'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 3) = '_TE'

update ReleaseIDs set HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 7) in ('_HotFix', '_Hotfix')

update ReleaseIDs set LanguageLabel = 'Chinese', HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 10) = '_ChineseHF'

update ReleaseIDs set LanguageLabel = 'French', HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 9) = '_FrenchHF'

update ReleaseIDs set LanguageLabel = 'German', HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 9) = '_GermanHF'

update ReleaseIDs set LanguageLabel = 'Japanese', HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 8) = '_JapanHF'

update ReleaseIDs set LanguageLabel = 'Spanish', HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 10) = '_SpanishHF'

update ReleaseIDs set LanguageLabel = 'Taiwanese', HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 9) = '_TaiwanHF'

update ReleaseIDs set LanguageLabel = 'ME', HotfixLabel = 'HotFix'
, JIRAVersion = left(ReleaseID, CHARINDEX('_', ReleaseID)-1)
where RIGHT(ReleaseID, 5) = '_MEHF'

update ReleaseIDs set IsReleased = 0 where ReleaseID in ('7.50F')