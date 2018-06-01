
-- Chris search
select --* 
pm.p_id, pm.date_created, pm.client_name, pm.dba_id
, pm.p_title as "CR Title"
, Pd.LOG as "CR POST"
from TRACK.problem_master pm inner join TRACK.problem_detail pd
on pm.p_id = pd.p_id
WHERE ROWNUM < 10 -- just like our "Select top N"
and date_created > '03-mar-2010' 
and pm.dba_id = 'presley' -- CR Creator, not poster
order by pm.client_name, pm.date_created;

-- Avail Monitored servers
select servername from clients
where lower(client_name) like '%amrn%'
order by 1


select cl.team,cl.company_name,to_char(pm.date_created,'YYYYMMDD HH24:MI') AS CrDate,
case pm.status_id
when 3 then 'SoftClosed'
when 2 then 'Closed'
when 1 then 'New'
when 4 then 'WorkInProgress'
when 5 then 'Pending'
WHEN 7 THEN 'Closed'
else 'Other' end AS status,
'https://secure.pythian.com/track/display.pl?cr='||pm.p_id AS URL,
p_title,pd."MinWorked"
,pm.dba_id
from track.problem_master pm join track.clients cl on pm.client_id = cl.client_id
left outer join
(select pdw.p_id,sum(pdw.minutes_worked) "MinWorked" from track.problem_detail pdw group by pdw.p_id) pd
on pd.p_id = pm.p_id
where /*pm.p_id in
(select pm.p_id from track.problem_master pm
where pm.dba_id in ('presley')
and */ lower(company_name) like lower('Ameren - SQL')
and  pm.status_id not in (7,3,2)
order by cl.team,pm.date_created desc,cl.company_name;


select cl.team,cl.company_name,to_char(pm.date_created,'YYYYMMDD HH24:MI') AS CrDate
, pm.p_title
,
case pm.status_id
when 3 then 'SoftClosed'
when 2 then 'Closed'
when 1 then 'New'
when 4 then 'WorkInProgress'
when 5 then 'Pending'
WHEN 7 THEN 'Closed'
else 'Other' end AS status,
'https://secure.pythian.com/track/display.pl?cr='||pm.p_id AS URL,
--p_title,
pd."MinWorked"
,pm.dba_id
from track.problem_master pm join track.clients cl on pm.client_id = cl.client_id
left outer join
(select pdw.p_id,sum(pdw.minutes_worked) "MinWorked" from track.problem_detail pdw group by pdw.p_id) pd
on pd.p_id = pm.p_id
where /*pm.p_id in
(select pm.p_id from track.problem_master pm
where pm.dba_id in ('presley')
and */ lower(company_name) like lower('Ameren - SQL')
and  pm.status_id not in (7,3,2)
order by cl.team,pm.date_created desc,cl.company_name;



select * from track.problem_master pm  WHERE ROWNUM < 10
and date_created > '03-mar-2010';


select * 
from TRACK.problem_master pm inner join    TRACK.problem_detail pd
on pm.p_id = pd.p_id
WHERE ROWNUM < 10
and date_created > '03-mar-2010'
--order by object_name;









