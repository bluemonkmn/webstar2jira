set nocount on
select 
'set fromdir=c:\fromdir
set todir=c:\todir
'

select
'XCOPY /Y "%fromdir%'
+ m.ModifiedFileChanged + '"'
+ ' "%todir%'
+ m.ModifiedFileChanged + '*"'
+ '
'
from
(
select distinct tt.ModifiedFileChanged
from
(
select r.RlsLevelTarget
      ,r.TransmittalId
      ,f.FCIndex
      ,f.FileChanged
 ,rtrim(
  ltrim(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(
  replace(f.FileChanged
  ,'/', '\')
  ,'$\R75\', '\')
  ,'$\Translation\', '\Translation\')
  ,'$\Sql\', '\Src\Sql\')
  ,'$R75\', '\')
  ,'\R75\', '\')
  ,'r75\', '\')
  ,'R75\', '\')
  ,'Src\CSPUtil\', 'CSPUtil\')
  ,'.\Sql\Src\', '\Src\Sql\Src\')
  ,'Sql\Src\', '\Src\Sql\Src\')
  ,'$\Src\','Src\')
  ,'\\', '\')
  ,' \', '\')
  ,'SB.FS.', 'SoftBrands.FourthShift.')
  ,'\Src\Src\','\Src\')
  ,'   \Display_','\Src\MyFsWp\FSWebUI\Finders\ServerSideCode\Chinese\Display_'))) ModifiedFileChanged
from resolution r
join FileChanges f on f.TransmittalID = r.TransmittalId
where (r.RlsLevelTarget like '7.50E_%'
or r.TransmittalId in (52434, 52431, 52441, 52435))
and f.FileChanged > ''
and not ((r.TransmittalId = 52577) and (f.FCIndex = 61))
and not ((r.TransmittalId = 52577) and (f.FCIndex = 63))
and f.FileChanged not like '%/Translation/Transaction%'
) tt
) m
order by m.ModifiedFileChanged
