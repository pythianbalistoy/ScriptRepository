SELECT --c.company_name,
       m.p_id CR,
       substr(m.p_title,instr(m.p_title, '| ', 1, 1)+2, ((instr(m.p_title, '| ', 1, 2)+2) - (instr(m.p_title, '| ', 1, 1)+5))) "System",
       min(to_char(date_created,'DD-MON-YYYY')) "Date Created",
       max(to_char(date_updated,'DD-MON-YYYY')) "Last Updated",
       max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) "CR Title",
      -- Max(m.dba_id)  "DBA",
       sum(hours_worked) "Hours Worked",
       (SELECT sum(hours_worked)
              FROM problem_detail d2
              where m.p_id = d2.p_id) "Hours Worked CR",
       Max(case status_id
           when 3 then 'SoftClosed'
           when 2 then 'Closed'
           when 1 then 'New'
           when 4 then 'WorkInProgress'
           when 5 then 'Pending'
           when 7 then 'Closed'
           else 'Other' END) AS Status,
       Max(case m.s_id
           when 1 then 'Red'
           when 2 then 'Yellow'
           when 3 then 'Green'
           else 'Other' END) AS Severity
       --Max(g.CLIENT_GROUP) "Client Group"
       
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     AND m.client_id =9260 -- CHSSQL
     AND d.date_ENTRY >=  to_date('01-Mar-2012','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('01-Apr-2012','dd-MON-yyyy')
group by m.p_id, m.p_title
order by 2, 3;




SELECT --c.company_name,
       m.p_id CR,
       min(to_char(date_created,'DD-MON-YYYY')) "Date Created",
       max(to_char(date_updated,'DD-MON-YYYY')) "Last Updated",
       max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) "CR Title",
       Max(m.dba_id)  "DBA",
       sum(hours_worked) "Hours Worked",
       (SELECT sum(hours_worked)
              FROM problem_detail d2
              where m.p_id = d2.p_id) "Hours Worked CR",
       Max(case status_id
           when 3 then 'SoftClosed'
           when 2 then 'Closed'
           when 1 then 'New'
           when 4 then 'WorkInProgress'
           when 5 then 'Pending'
           when 7 then 'Closed'
           else 'Other' END) AS Status,
       Max(case m.s_id
           when 1 then 'Red'
           when 2 then 'Yellow'
           when 3 then 'Green'
           else 'Other' END) AS Severity,
       Max(g.CLIENT_GROUP) "Client Group"
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     AND m.client_id =9260 -- CHSSQL
     AND d.date_ENTRY >=  to_date('01-Mar-2012','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('01-Apr-2012','dd-MON-yyyy')
group by m.p_id
order by 2, 3;
 
 /*
 
 Select *
 From track.clients
 where lower(company_name) like '%catholic%'
 
 */
 