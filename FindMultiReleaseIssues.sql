select TransmittalId into StarMap..MultiReleaseResolutions
from (
select r.TransmittalId, r.ReleaseLev
, s.Release
from STAR..resolution r 
join STAR..Resolution_SDRs rs on r.TransmittalId = rs.TransmittalID
join STAR..sdr s on s.SDRNum = rs.SDR_Num
where r.ReleaseLev in ('5.10', '5.20', '6.00', '6.10', '6.20', '7.00', '7.10', '7.20', '7.30', '7.40', '7.50', '8.0', 'BI', 'FSE')
and s.Release in ('5.10', '5.20', '6.00', '6.10', '6.20', '7.00', '7.10', '7.20', '7.30', '7.40', '7.50', '8.0', 'BI', 'FSE')
group by r.TransmittalId, r.ReleaseLev, s.Release) t0
group by TransmittalId, ReleaseLev
having COUNT(Release) > 1

select distinct s.SDRNum into StarMap..MultiReleaseSdrs
from STAR..sdr s
join STAR..Resolution_SDRs rs on rs.SDR_Num = s.SDRNum
join StarMap..MultiReleaseResolutions mr on mr.TransmittalId = rs.TransmittalID

insert into StarMap..MultiReleaseResolutions
select distinct r.TransmittalId
from STAR..resolution r
join STAR..Resolution_SDRs rs on rs.TransmittalID = r.TransmittalId
join StarMap..MultiReleaseSdrs ms on ms.SDRNum = rs.SDR_Num
left join StarMap..MultiReleaseResolutions mr on mr.TransmittalId = r.TransmittalId
where mr.TransmittalId is null

insert into StarMap..MultiReleaseSdrs
select distinct s.SDRNum
from STAR..sdr s
join STAR..Resolution_SDRs rs on rs.SDR_Num = s.SDRNum
join StarMap..MultiReleaseResolutions mr on mr.TransmittalId = rs.TransmittalID
left join StarMap..MultiReleaseSdrs ms on ms.SDRNum = rs.SDR_Num
where ms.SDRNum is null
