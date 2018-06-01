
select distinct pm.p_id CR, pm.p_title CR_details, pm.date_created Created,
  (select max(date_entry) from problem_detail pdd where pdd.p_id = pd.p_id and minutes_worked <> 0) Last_worked,
  pm.date_updated Last_CR_change,
  round(( (select max(date_entry) from problem_detail pdd where pdd.p_id = pd.p_id and minutes_worked <> 0) - date_created), 2)  Time_to_resolution_in_days,
  substr(pm.p_title,instr(pm.p_title, '| ', 1, 3)+2) Issue,
  substr(pm.p_title,instr(pm.p_title, '| ', 1, 1)+2, ((instr(pm.p_title, '| ', 1, 2)+2) - (instr(pm.p_title, '| ', 1, 1)+4))) System
from problem_master pm, problem_detail pd
where
  pm.client_id = &&client
  and pm.status_id in (2,3,6)
  and pm.p_id = pd.p_id
  --and date_created > (sysdate - &&num_of_days)
  and pm.date_updated > (sysdate - &&num_of_days)
  and pm.dba_id <> 'autodaily'
  and pm.p_title <> 'DBA Daily'
  and pm.micro_CR <> 1
  and lower(pm.p_title) like '%tors1strisqlp1%'
order by 6;


/*

set lines 132

select *
from problem_master pm
where lower(client_name) like '%mcap%'

*/



select distinct pm.p_id CR, pm.p_title CR_details, pm.date_created Created,
(select max(date_entry) from problem_detail pdd where pdd.p_id = pd.p_id and minutes_worked <> 0) Last_worked,
pm.date_updated Last_CR_change,
round(( (select max(date_entry) from problem_detail pdd where pdd.p_id = pd.p_id and minutes_worked <> 0) - date_created), 2)  Time_to_resolution_in_days,
(select sum(hours_worked) from problem_detail pdd where pdd.p_id = pd.p_id)  Time_worked_CR,
substr(pm.p_title,instr(pm.p_title, '| ', 1, 3)+2) Issue,
substr(pm.p_title,instr(pm.p_title, '| ', 1, 2)+2, ((instr(pm.p_title, '| ', 1, 3)+2) - (instr(pm.p_title, '| ', 1, 2)+4))) Issue_type,
substr(pm.p_title,instr(pm.p_title, '| ', 1, 1)+2, ((instr(pm.p_title, '| ', 1, 2)+2) - (instr(pm.p_title, '| ', 1, 1)+4))) System
from problem_master pm, problem_detail pd, allotment al
where
lower(al.label) = lower('&&lowshortname')
and pm.client_id = al.id
and pm.status_id in (2,3,6)
and pm.p_id = pd.p_id
--and date_created > (sysdate - &&num_of_days)
and pm.date_updated > (sysdate - &&num_of_days)
and pm.dba_id <> 'autodaily'
and pm.p_title <> 'DBA Daily'
and pm.micro_CR <> 1
order by 6;


