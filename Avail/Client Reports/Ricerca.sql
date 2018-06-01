sorry

SELECT 
company_name, m.p_id "CR",
       min(to_char(date_created,'DD-MON-YYYY')) date_created,
       max(to_char(date_updated,'DD-MON-YYYY')) last_date_updated,
       max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) title,
      -- '=HYPERLINK("https://secure.pythian.com/track/display.pl?cr='||m.p_id||'", "Link")' AS URL,
      --- Max(m.dba_id)  DBA,
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
      -- '=HYPERLINK(https://secure.pythian.com/track/cr/'||m.p_id||')' AS URL,
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
     AND m.client_id in (5440, 4460)  --4460 for lyon
     AND d.date_ENTRY >=  to_date('1-Jan-2011','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('30-Aug-2011','dd-MON-yyyy')
group by company_name, m.p_id
having  sum(hours_worked) > 0
order by 1,2;




SELECT 
 min(to_char(date_created,'MON-YYYY')) date_created,
        (SELECT sum(hours_worked)
              FROM problem_detail d2
              where m.p_id = d2.p_id) hours_worked_CR
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     AND m.client_id = 5440
     AND d.date_ENTRY >=  to_date('1-jan-2011','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('30-Aug-2011','dd-MON-yyyy')
--group by date_created,hours_worked_CR
having  sum(hours_worked) > 0
order by 1;



/*

Select distinct client_name, client_id from problem_master
where lower(client_name) like 'rice%'
or lower(client_name) like '%lyon%'

Select * from clients
where lower(company_name) like '%rice%' or client_id = 5440

*/



SELECT company_name, 
       to_char(date_created,'MON-YYYY') Month_Worked
       , sum(hours_worked) Hours_Worked
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     AND m.client_id in (5440, 4460)  --4460 for lyon
     AND d.date_ENTRY >=  to_date('1-Jan-2011','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('30-Aug-2011','dd-MON-yyyy')
group by company_name, to_char(date_created,'MON-YYYY')
--having  sum(hours_worked) > 0
order by date_created;




SELECT m.client_id,
company_name, m.p_id "CR",
       min(to_char(date_created,'DD-MON-YYYY')) date_created,
       sum(hours_worked) hours_worked,
       (SELECT sum(hours_worked)
              FROM problem_detail d2
              where m.p_id = d2.p_id) hours_worked_CR
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     AND m.client_id in (5440, 4460)  --4460 for lyon
     AND d.date_ENTRY >=  to_date('1-Jan-2010','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('30-Aug-2011','dd-MON-yyyy')
group by m.client_id, company_name, m.p_id
having  sum(hours_worked) > 0
order by 4;



SELECT c.company_name,
       m.p_id,
       min(to_char(date_created,'DD-MON-YYYY')) date_created,
       max(to_char(date_updated,'DD-MON-YYYY')) last_date_updated,
       (SELECT Max(to_char(date_ENTRY,'DD-MON-YYYY'))
              FROM problem_detail d2
              where m.p_id = d2.p_id
              AND date_ENTRY >=  to_date('01-Jan-2010','dd-MON-yyyy')
              AND date_ENTRY < to_date('30-aug-2011','dd-MON-yyyy')) last_date_updated_month,
       --max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) title,
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
     AND m.client_id in (5440,5441,5921,5440,5920) --(6020,6120,5440,5441,5580,7280,5920,5900,5921,4460)
     AND d.date_ENTRY >=  to_date('01-Jan-2010','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('30-aug-2011','dd-MON-yyyy')
group by company_name, m.p_id;
 
 
 
