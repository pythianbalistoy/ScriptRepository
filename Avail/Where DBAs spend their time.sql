select trunc(d.date_entry,'mm'), a.team_id, sum(hours_worked)
from problem_master m, problem_detail d, allotment a
where m.p_id = d.p_id
and a.id = m.client_id
and d.dba_id = '&dba_id'
and date_entry >= trunc(sysdate-60,'mm')
group by rollup(trunc(d.date_entry,'mm'), a.team_id);
