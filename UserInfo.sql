select NTUserName, UserName,
case when CHARINDEX(',', ExchangeName) > 1
then LTRIM(SUBSTRING(ExchangeName, CHARINDEX(',', ExchangeName)+1, 35))
+ ' ' + SUBSTRING(ExchangeName, 1, CHARINDEX(',', ExchangeName)-1) 
else ExchangeName end FullName,
Access, EmailAddr
into StarMap..UserInfo
from STAR..UserInfo

use StarMap
alter table UserInfo add Active bit not null constraint DF_UserInfoActive default (0)
alter table UserInfo drop DF_UserInfoActive
update UserInfo set Active = 1 where NTUserName like 'INFOR\%'

update UserInfo set Active = 0 where NTUserName in
('infor\aschuck', 'infor\bguo'
,'infor\cchen','infor\cmeng','infor\dschultz'
,'infor\fyang','infor\ghageman','infor\gsun','infor\izuniga','INFOR\jdunstall'
,'infor\jhliu','infor\jkerr','infor\jmcdermid','infor\jtharp','infor\jwang2'
,'infor\kpaul','infor\ksteltzner','infor\lxing','infor\nharper'
,'infor\pjin','INFOR\pstreet','infor\pwang','infor\revans','infor\rpanneerselvamr'
,'infor\rsharp','infor\ssun','infor\wguo2','infor\wzhang2'
,'infor\zszhang')

update UserInfo set FullName = 'Li Da' where FullName = 'Da Li'
update UserInfo set FullName = 'Dai Fu' where FullName = 'Fu Dai'
update UserInfo set FullName = 'Cai Hongyuan' where FullName = 'Hongyuan Cai'
update UserInfo set FullName = 'Cai HaiMing' where FullName = 'HaiMing Cai'
update UserInfo set FullName = 'Li Jin' where FullName = 'Jin Li'
update UserInfo set FullName = 'Liu Jie' where FullName = 'Jie Liu'
update UserInfo set FullName = 'Guo LiangHong' where FullName = 'LiangHong Guo'
update UserInfo set FullName = 'Ye Min' where FullName = 'Min Ye'
update UserInfo set FullName = 'Wang Shuyu' where FullName = 'Shuyu Wang'
update UserInfo set FullName = 'Fan Yujie' where FullName = 'Yujie Fan'
update UserInfo set FullName = 'Li Chen' where FullName = 'Chen Li'
update UserInfo set FullName = 'Zhang Jie' where FullName = 'Jie Zhang'
update UserInfo set FullName = 'Zhu Jiang' where FullName = 'Jiang Zhu'
update UserInfo set FullName = 'Tan Jiyuan' where FullName = 'Jiyuan Tan'
update UserInfo set FullName = 'Feng Linli' where FullName = 'Linli Feng'
update UserInfo set FullName = 'Gao Liang' where FullName = 'Liang Gao'
update UserInfo set FullName = 'Gao Meng' where FullName = 'Meng Gao'
update UserInfo set FullName = 'Zhang Simeng' where FullName = 'Simeng Zhang'
update UserInfo set FullName = 'Li Wenjian' where FullName = 'Wenjian Li'
update UserInfo set FullName = 'Meng Xiangjun' where FullName = 'Xiangjun Meng'
update UserInfo set FullName = 'Zhang Xiaomin' where FullName = 'Xiaomin Zhang'

update UserInfo set EmailAddr = 'andy.wallace@infor.com' where NTUserName = 'infor\awallace'
update UserInfo set EmailAddr = 'jian.wang@infor.com' where NTUserName = 'infor\jwang4'
update UserInfo set EmailAddr = 'shelia.yates@infor.com' where NTUserName = 'infor\syates'
update UserInfo set EmailAddr = 'jin.yang@infor.com' where NTUserName = 'infor\yjin2'
