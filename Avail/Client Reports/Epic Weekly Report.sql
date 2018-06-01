

SELECT 
c.company_name,
m.p_id "CR",
       min(to_char(date_created,'DD-MON-YYYY')) date_created,
       max(to_char(date_updated,'DD-MON-YYYY')) last_date_updated,
       max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) title,
       --'=HYPERLINK("https://secure.pythian.com/track/display.pl?cr='||m.p_id||'", "Link")' AS URL,
       Max(m.dba_id)  DBA,
       sum(hours_worked) hours_worked,
       (SELECT sum(hours_worked)
              FROM problem_detail d2
              where m.p_id = d2.p_id) hours_worked_CR,
       Max(case status_id
           when 3 then 'SoftClosed'
           when 2 then 'Closed'
           when 1 then 'New'
           when 4 then 'WorkInProgress'
           when 5 then 'Pending'
           when 7 then 'Closed'
           else 'Other' END) AS status,
       --'=HYPERLINK(https://secure.pythian.com/track/cr/'||m.p_id||')' AS URL,
       Max(case m.s_id
           when 1 then 'Red'
           when 2 then 'Yellow'
           when 3 then 'Green'
           else 'Other' END) AS Severity,
       Max(g.CLIENT_GROUP) CLIENT_GROUP
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     AND m.client_id = 4660 -- in (1720,2860,4660) 
     AND d.date_ENTRY >=  to_date('1-nov-2011','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('30-dec-2011','dd-MON-yyyy')
     --and status_id not in (2,3,7)
group by m.p_id, c.company_name
having  sum(hours_worked) > 0
order by c.company_name, date_created;

/*
select * 
from track.clients
where lower(company_name) like '%epic%'



From problem_master
where lower(client) like '%epic%'

Select * from clients
where lower(company_name) like '%epic%'

4660	EPIC Technologies SQL
1720	EPIC Technologies Inc
2860	EPIC Technologies Inc - SysAdmin


Select client, client_id
From problem_master
where lower(client) like '%epic%'
group by client, client_id
order by client;
*/