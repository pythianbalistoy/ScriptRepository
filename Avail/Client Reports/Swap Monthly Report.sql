
SELECT c.company_name,
       m.p_id,
       min(to_char(date_created,'DD-MON-YYYY')) date_created,
       max(to_char(date_updated,'DD-MON-YYYY')) last_date_updated,
       (SELECT Max(to_char(date_ENTRY,'DD-MON-YYYY'))
              FROM problem_detail d2
              where m.p_id = d2.p_id
              AND date_ENTRY >=  to_date('01-MAR-2011','dd-MON-yyyy')
              AND date_ENTRY < to_date('28-MAR-2011','dd-MON-yyyy')) last_date_updated_month,
       max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) title,
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
     AND m.client_id =2440 --in(861,171)     -- JDS and JDS-SQL
     AND d.date_ENTRY >=  to_date('01-MAR-2011','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('28-MAR-2011','dd-MON-yyyy')
group by company_name, m.p_id
order by 1,12,2 ;


Select * from track.clients 
where lower(company_name) like '%swap%'



 
 