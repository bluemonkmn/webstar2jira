select NTUserName, UserName,
case when CHARINDEX(',', ExchangeName) > 1
then LTRIM(SUBSTRING(ExchangeName, CHARINDEX(',', ExchangeName)+1, 35))
+ ' ' + SUBSTRING(ExchangeName, 1, CHARINDEX(',', ExchangeName)-1) 
else ExchangeName end FullName,
Access
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
,'infor\zszhang', 'SOFTBRANDSAMER\bldadm')

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

ALTER TABLE UserInfo add EmailAddr nvarchar(64) null

UPDATE UserInfo SET EmailAddr = 'ben.marty@infor.com' WHERE NTUserName = 'infor\bmarty'
UPDATE UserInfo SET EmailAddr = 'Brett.Murr@infor.com' WHERE NTUserName = 'infor\bmurr'
UPDATE UserInfo SET EmailAddr = 'duane.matheson@infor.com' WHERE NTUserName = 'infor\dmatheson'
UPDATE UserInfo SET EmailAddr = 'dick.schultz@infor.com' WHERE NTUserName = 'infor\dschultz'
UPDATE UserInfo SET EmailAddr = 'gregory.vanyo@infor.com' WHERE NTUserName = 'infor\gvanyo'
UPDATE UserInfo SET EmailAddr = 'Jamie.Bixby@infor.com' WHERE NTUserName = 'infor\jbixby'
UPDATE UserInfo SET EmailAddr = 'Jie.Liu@infor.com' WHERE NTUserName = 'infor\jliu'
UPDATE UserInfo SET EmailAddr = 'jim.moe@infor.com' WHERE NTUserName = 'infor\jmoe'
UPDATE UserInfo SET EmailAddr = 'julie.weeks-freedman@infor.com' WHERE NTUserName = 'infor\jweeks-freedman'
UPDATE UserInfo SET EmailAddr = 'Jie.Zhang@infor.com' WHERE NTUserName = 'infor\jzhang2'
UPDATE UserInfo SET EmailAddr = 'Karen.Bottorff@infor.com' WHERE NTUserName = 'infor\kbottorff'
UPDATE UserInfo SET EmailAddr = 'Min.Ye@infor.com' WHERE NTUserName = 'infor\mye'
UPDATE UserInfo SET EmailAddr = 'sara.johnson@infor.com' WHERE NTUserName = 'infor\sjohnson'
UPDATE UserInfo SET EmailAddr = 'susan.keim@infor.com' WHERE NTUserName = 'infor\skeim'
UPDATE UserInfo SET EmailAddr = 'sheila.yates@infor.com' WHERE NTUserName = 'infor\syates'