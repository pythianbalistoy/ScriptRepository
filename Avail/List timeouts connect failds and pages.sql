
-- pages by day

select on_day, sum(decode(event_type_id,10,cnt)) alerts, sum(decode(event_type_id,20,cnt)) tmo,  
  sum(decode(event_type_id,21,cnt)) con_failed, sum(cnt) total 
from ( 
select trunc(time_stamp) on_day, event_type_id, count(*) cnt 
from oncall.alerts 
where event_type_id not in (15,13,18,19, 12,11) 
and time_stamp > sysdate - 14 
group by trunc(time_stamp), event_type_id 
order by 1 desc, event_type_id asc 
) group by on_day 
order by 1 desc;

-- breakdown Timeouts and Connect faileds from Tim

select b.name, b.agent_id, b.handler_id,
    a.time_stamp, a.subject, a.event_type_id, a.full_msg
from oncall.alerts a, agent b
where 1=1
  --and time_stamp > sysdate - 1
  and trunc(time_stamp) = trunc(sysdate) - 2
  and a.event_type_id not in (15,13,18,19, 12,11)
  and a.event_type_id in (21)
  --and a.event_type_id = 21
  and a.object_id = b.agent_id
  --and b.agent_id = 1409
  --and full_msg like '%Abandoned % s after dispatch%'
  --and full_msg like '%disk_storage%'
  and agent_id not in (2661)
order by a.time_stamp desc;


 select * from oncall.alerts  
where object_id = 1636 
  and time_stamp > sysdate - 1 
order by time_stamp asc;



select * from handler_variable where variable_name = 'MAX_COLLECTOR_WORKERS';
1635

insert into handler_variable
  values(1635, 'MAX_COLLECTOR_WORKERS', 1);



select handler_id from agent where lower(name) like lower('sql_db2.LoneWMSSQL');